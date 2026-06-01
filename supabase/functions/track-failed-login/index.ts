import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  const webhookSecret = Deno.env.get("AUTH_WEBHOOK_SECRET");
  if (webhookSecret && req.headers.get("x-webhook-secret") !== webhookSecret) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = await req.json().catch(() => ({}));
  const email = payload.email ?? payload.user?.email;
  if (!email) return new Response("email is required", { status: 400 });

  const { error } = await supabase.from("failed_login_attempts").insert({
    email,
    ip_address: req.headers.get("x-forwarded-for")?.split(",")[0] ?? null,
    user_agent: req.headers.get("user-agent"),
    failure_reason: payload.reason ?? payload.error ?? "auth_failed",
  });

  if (error) return new Response(error.message, { status: 500 });
  return new Response(JSON.stringify({ ok: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
