import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

import { corsHeaders } from "../_shared/cors.ts";

export const allowedRoles = new Set([
  "sales_rep", "warehouse_staff", "b2b_customer", "comptable", "acheteur", "delivery_agent",
]);

export function validateCreateUserPayload(body: Record<string, unknown> | null): string | null {
  const email = String(body?.email ?? "").trim().toLowerCase();
  const role = String(body?.role ?? "");
  if (!email || !email.includes("@")) return "Invalid email";
  if (!allowedRoles.has(role)) return "Invalid role";
  if (body && "password" in body) return "Passwords must never be supplied by administrators";
  return null;
}

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, "Content-Type": "application/json", "Cache-Control": "no-store" },
});

export function createUserHandler(serviceClient: SupabaseClient, supabaseUrl: string, anonKey: string) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
    if (req.method !== "POST") {
      console.warn(JSON.stringify({ event: "create_user_rejected", reason: "method_not_allowed" }));
      return json({ error: "Method not allowed" }, 405);
    }
    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(supabaseUrl, anonKey, { global: { headers: { Authorization: authHeader } } });
    const { data: authUser, error: authError } = await userClient.auth.getUser();
    if (authError || !authUser.user) {
      console.warn(JSON.stringify({ event: "create_user_rejected", reason: "unauthorized" }));
      return json({ error: "Unauthorized" }, 401);
    }

    const { data: profile } = await serviceClient.from("user_profiles").select("role,is_active,must_change_password").eq("id", authUser.user.id).single();
    if (profile?.role !== "admin" || profile?.is_active !== true || profile?.must_change_password === true) {
      console.warn(JSON.stringify({ event: "create_user_rejected", reason: "admin_only", actor_id: authUser.user.id }));
      return json({ error: "Admin only" }, 403);
    }

    const body = await req.json().catch(() => null) as Record<string, unknown> | null;
    const email = String(body?.email ?? "").trim().toLowerCase();
    const role = String(body?.role ?? "");
    const validationError = validateCreateUserPayload(body);
    if (validationError) {
      console.warn(JSON.stringify({ event: "create_user_rejected", reason: "invalid_payload", actor_id: authUser.user.id }));
      return json({ error: validationError }, 400);
    }

    const redirectTo = Deno.env.get("INVITE_REDIRECT_URL") ?? Deno.env.get("SITE_URL");
    const { data: invited, error } = await serviceClient.auth.admin.inviteUserByEmail(email, {
      redirectTo,
      data: { full_name: String(body?.full_name ?? ""), must_change_password: true },
    });
    if (error || !invited.user) {
      console.error(JSON.stringify({ event: "create_user_invitation_failed", actor_id: authUser.user.id }));
      return json({ error: error?.message ?? "User invitation failed" }, 400);
    }

    const { error: profileError } = await serviceClient.from("user_profiles").upsert({
      id: invited.user.id,
      email,
      full_name: String(body?.full_name ?? email),
      role,
      phone: body?.phone || null,
      company_name: body?.company_name || null,
      is_active: true,
      must_change_password: true,
    });
    if (profileError) {
      await serviceClient.auth.admin.deleteUser(invited.user.id);
      console.error(JSON.stringify({ event: "create_user_rollback", reason: "profile_failed", user_id: invited.user.id }));
      return json({ error: profileError.message }, 500);
    }

    const { error: auditError } = await serviceClient.from("audit_logs").insert({
      table_name: "user_profiles",
      record_id: invited.user.id,
      action_type: "insert",
      user_id: authUser.user.id,
      new_values: { operation: "user_created_by_admin", email, role, invitation_sent: true },
    });
    if (auditError) {
      await serviceClient.auth.admin.deleteUser(invited.user.id);
      console.error(JSON.stringify({ event: "create_user_rollback", reason: "audit_failed", user_id: invited.user.id }));
      return json({ error: "User creation rolled back because audit logging failed" }, 500);
    }
    console.info(JSON.stringify({ event: "user_created_by_admin", actor_id: authUser.user.id, user_id: invited.user.id, role }));
    return json({ id: invited.user.id, invitation_sent: true }, 201);
  };
}

if (import.meta.main) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  Deno.serve(createUserHandler(serviceClient, supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!));
}
