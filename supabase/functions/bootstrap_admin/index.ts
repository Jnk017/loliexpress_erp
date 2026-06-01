import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  const secret = Deno.env.get("BOOTSTRAP_ADMIN_SECRET");
  if (!secret || req.headers.get("x-bootstrap-secret") !== secret) {
    return new Response("Unauthorized", { status: 401 });
  }

  const { count } = await supabase
    .from("user_profiles")
    .select("id", { count: "exact", head: true })
    .eq("role", "admin");
  if ((count ?? 0) > 0) {
    return new Response("Admin already exists", { status: 409 });
  }

  const body = await req.json().catch(() => ({}));
  const email = body.email ?? "admin@loliexpress.com";
  const password = body.password;
  if (!password) return new Response("password is required", { status: 400 });

  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: "Initial Admin" },
  });
  if (error || !data.user) {
    return new Response(error?.message ?? "Admin creation failed", { status: 400 });
  }

  await supabase.from("user_profiles").upsert({
    id: data.user.id,
    email,
    full_name: "Initial Admin",
    role: "admin",
    is_active: true,
  });

  return new Response(JSON.stringify({ id: data.user.id, email }), {
    headers: { "Content-Type": "application/json" },
  });
});
