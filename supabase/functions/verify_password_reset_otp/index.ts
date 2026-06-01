import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

async function sha256(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req) => {
  const body = await req.json().catch(() => ({}));
  const email = String(body.email ?? "").trim().toLowerCase();
  const token = String(body.otp ?? "").trim();
  const password = String(body.password ?? "");

  if (!email.includes("@") || !RegExp("^\\d{6}$").hasMatch(token)) {
    return new Response("Code invalide", { status: 400 });
  }
  if (password.length < 8) {
    return new Response("Le mot de passe doit contenir au moins 8 caractères", {
      status: 400,
    });
  }

  const { data: record, error } = await supabase
    .from("password_reset_otps")
    .select("id,user_id,email,otp_hash,attempts,expires_at,consumed_at")
    .ilike("email", email)
    .is("consumed_at", null)
    .gt("expires_at", new Date().toISOString())
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error || !record || record.attempts >= 5) {
    return new Response("Code expiré ou invalide", { status: 400 });
  }

  const hash = await sha256(`${email}:${token}`);
  if (hash !== record.otp_hash) {
    await supabase
      .from("password_reset_otps")
      .update({ attempts: (record.attempts ?? 0) + 1 })
      .eq("id", record.id);
    return new Response("Code expiré ou invalide", { status: 400 });
  }

  const { error: updateError } = await supabase.auth.admin.updateUserById(
    record.user_id,
    { password, email_confirm: true },
  );
  if (updateError) {
    return new Response(updateError.message, { status: 500 });
  }

  await supabase
    .from("password_reset_otps")
    .update({ consumed_at: new Date().toISOString() })
    .eq("id", record.id);

  return Response.json({ ok: true });
});
