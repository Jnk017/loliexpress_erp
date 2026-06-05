import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export function validateBootstrapPayload(body: Record<string, unknown>): string | null {
  const email = String(body.email ?? "").trim().toLowerCase();
  if (!email || !email.includes("@")) return "A valid email is required";
  if ("password" in body) return "Bootstrap does not accept passwords";
  return null;
}

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
});

async function logAttempt(client: SupabaseClient, req: Request, success: boolean, metadata: Record<string, unknown>) {
  const forwarded = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  await client.from("security_events").insert({
    event_type: "bootstrap_admin_attempt", success,
    ip_address: forwarded || null, user_agent: req.headers.get("user-agent"), metadata,
  });
  console.info(JSON.stringify({ event: "bootstrap_admin_attempt", success, ...metadata }));
}

export function bootstrapAdminHandler(supabase: SupabaseClient) {
  return async (req: Request): Promise<Response> => {
    if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
    const configuredSecret = Deno.env.get("BOOTSTRAP_ADMIN_SECRET");
    const suppliedSecret = req.headers.get("x-bootstrap-secret");
    if (!configuredSecret || suppliedSecret !== configuredSecret) {
      await logAttempt(supabase, req, false, { reason: "invalid_secret" });
      return json({ error: "Unauthorized" }, 401);
    }

    const { data: setting, error: settingError } = await supabase.from("system_configuration").select("config_value").eq("config_key", "bootstrap_admin_enabled").maybeSingle();
    if (settingError) {
      await logAttempt(supabase, req, false, { reason: "configuration_read_failed" });
      return json({ error: "Bootstrap configuration is unavailable" }, 500);
    }
    if (setting?.config_value !== "true") {
      await logAttempt(supabase, req, false, { reason: "disabled" });
      return json({ error: "Bootstrap is disabled" }, 410);
    }
    const { count, error: countError } = await supabase.from("user_profiles").select("id", { count: "exact", head: true }).eq("role", "admin");
    if (countError) {
      await logAttempt(supabase, req, false, { reason: "admin_count_failed" });
      return json({ error: "Unable to verify bootstrap state" }, 500);
    }
    if ((count ?? 0) > 0) {
      await supabase.from("system_configuration").update({ config_value: "false", updated_at: new Date().toISOString() }).eq("config_key", "bootstrap_admin_enabled");
      await logAttempt(supabase, req, false, { reason: "admin_exists" });
      return json({ error: "Admin already exists" }, 409);
    }

    const body = await req.json().catch(() => ({})) as Record<string, unknown>;
    const email = String(body.email ?? "").trim().toLowerCase();
    const validationError = validateBootstrapPayload(body);
    if (validationError) {
      await logAttempt(supabase, req, false, { reason: "invalid_payload" });
      return json({ error: validationError }, 400);
    }

    const { data, error } = await supabase.auth.admin.inviteUserByEmail(email, {
      redirectTo: Deno.env.get("INVITE_REDIRECT_URL") ?? Deno.env.get("SITE_URL"),
      data: { full_name: "Initial Admin", must_change_password: true },
    });
    if (error || !data.user) {
      await logAttempt(supabase, req, false, { reason: "invite_failed" });
      return json({ error: error?.message ?? "Admin invitation failed" }, 400);
    }
    const { error: profileError } = await supabase.from("user_profiles").upsert({
      id: data.user.id, email, full_name: "Initial Admin", role: "admin", is_active: true, must_change_password: true,
    });
    if (profileError) {
      await supabase.auth.admin.deleteUser(data.user.id);
      await logAttempt(supabase, req, false, { reason: "profile_failed" });
      return json({ error: profileError.message }, 500);
    }
    const { error: auditError } = await supabase.from("audit_logs").insert({
      table_name: "user_profiles", record_id: data.user.id, action_type: "insert", user_id: data.user.id,
      new_values: { operation: "bootstrap_admin", email, invitation_sent: true },
    });
    if (auditError) {
      await supabase.auth.admin.deleteUser(data.user.id);
      await logAttempt(supabase, req, false, { reason: "audit_failed", user_id: data.user.id });
      return json({ error: "Admin bootstrap rolled back because audit logging failed" }, 500);
    }
    const { error: disableError } = await supabase.from("system_configuration").update({
      config_value: "false",
      updated_at: new Date().toISOString(),
    }).eq("config_key", "bootstrap_admin_enabled");
    if (disableError) {
      await supabase.auth.admin.deleteUser(data.user.id);
      await logAttempt(supabase, req, false, { reason: "disable_failed", user_id: data.user.id });
      return json({ error: "Admin bootstrap rolled back because it could not be disabled" }, 500);
    }
    await logAttempt(supabase, req, true, { user_id: data.user.id });
    return json({ id: data.user.id, email, invitation_sent: true }, 201);
  };
}

if (import.meta.main) {
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  Deno.serve(bootstrapAdminHandler(supabase));
}
