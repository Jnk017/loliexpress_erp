import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const allowedRoles = new Set([
  "sales_rep",
  "warehouse_staff",
  "b2b_customer",
  "comptable",
  "acheteur",
  "delivery_agent",
]);

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const serviceClient = createClient(supabaseUrl, serviceKey);

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization") ?? "";
  const userClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: authUser, error: authError } = await userClient.auth.getUser();
  if (authError || !authUser.user) return new Response("Unauthorized", { status: 401 });

  const { data: profile } = await serviceClient
    .from("user_profiles")
    .select("role,is_active")
    .eq("id", authUser.user.id)
    .single();
  if (profile?.role !== "admin" || profile?.is_active !== true) {
    return new Response("Admin only", { status: 403 });
  }

  const body = await req.json();
  const role = body.role;
  if (!allowedRoles.has(role)) return new Response("Invalid role", { status: 400 });

  const { data: created, error } = await serviceClient.auth.admin.createUser({
    email: body.email,
    password: body.password,
    email_confirm: true,
    user_metadata: { full_name: body.full_name ?? "" },
  });
  if (error || !created.user) {
    return new Response(error?.message ?? "User creation failed", { status: 400 });
  }

  const { error: profileError } = await serviceClient.from("user_profiles").upsert({
    id: created.user.id,
    email: body.email,
    full_name: body.full_name ?? body.email,
    role,
    phone: body.phone ?? null,
    company_name: body.company_name ?? null,
    is_active: true,
  });
  if (profileError) return new Response(profileError.message, { status: 500 });

  const resendKey = Deno.env.get("RESEND_API_KEY");
  if (resendKey) {
    await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: Deno.env.get("NOTIFICATION_FROM_EMAIL") ?? "noreply@loliexpress.com",
        to: body.email,
        subject: "Votre compte LoliExpress ERP",
        html: `<p>Votre compte a été créé.</p><p>Mot de passe temporaire: <b>${body.password}</b></p><p>Changez-le à la première connexion.</p>`,
      }),
    });
  }

  return new Response(JSON.stringify({ id: created.user.id }), {
    headers: { "Content-Type": "application/json" },
  });
});
