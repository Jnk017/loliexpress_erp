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

function otp(): string {
  const value = crypto.getRandomValues(new Uint32Array(1))[0] % 1000000;
  return value.toString().padStart(6, "0");
}

Deno.serve(async (req) => {
  const { email } = await req.json().catch(() => ({}));
  const normalizedEmail = String(email ?? "").trim().toLowerCase();
  if (!normalizedEmail.includes("@")) {
    return new Response("Email invalide", { status: 400 });
  }

  const { data: profile } = await supabase
    .from("user_profiles")
    .select("id,email,full_name,is_active")
    .ilike("email", normalizedEmail)
    .maybeSingle();

  // Avoid account enumeration: unknown or inactive accounts still get a generic success.
  if (!profile?.id || profile.is_active !== true) {
    return Response.json({ ok: true });
  }

  const resendKey = Deno.env.get("RESEND_API_KEY");
  if (!resendKey) {
    return Response.json(
      {
        ok: false,
        code: "email_provider_missing",
        message:
          "Le service d'envoi OTP n'est pas configuré. Ajoutez le secret Supabase RESEND_API_KEY.",
      },
      { status: 503 },
    );
  }

  const code = otp();
  const hash = await sha256(`${normalizedEmail}:${code}`);
  await supabase.from("password_reset_otps").insert({
    user_id: profile.id,
    email: normalizedEmail,
    otp_hash: hash,
    expires_at: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
  });

  const sent = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: Deno.env.get("NOTIFICATION_FROM_EMAIL") ?? "noreply@loliexpress.com",
      to: normalizedEmail,
      subject: "Code de réinitialisation LoliExpress ERP",
      html: `<p>Bonjour ${profile.full_name ?? ""},</p><p>Votre code de réinitialisation est:</p><h2>${code}</h2><p>Il expire dans 10 minutes.</p>`,
    }),
  });

  if (!sent.ok) {
    return new Response(await sent.text(), { status: 502 });
  }

  return Response.json({ ok: true });
});
