import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  const { notification_id } = await req.json().catch(() => ({}));
  if (!notification_id) {
    return new Response("notification_id is required", { status: 400 });
  }

  const { data: notification, error } = await supabase
    .from("notification_queue")
    .select("*")
    .eq("id", notification_id)
    .single();
  if (error) return new Response(error.message, { status: 500 });

  const resendKey = Deno.env.get("RESEND_API_KEY");
  if (!resendKey) {
    return new Response("RESEND_API_KEY is not configured", { status: 500 });
  }

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: Deno.env.get("NOTIFICATION_FROM_EMAIL") ?? "noreply@loliexpress.com",
      to: notification.recipient_email,
      subject: notification.subject,
      html: notification.message,
    }),
  });

  await supabase
    .from("notification_queue")
    .update({
      status: response.ok ? "sent" : "failed",
      sent_at: response.ok ? new Date().toISOString() : null,
      error_message: response.ok ? null : await response.text(),
      retry_count: (notification.retry_count ?? 0) + (response.ok ? 0 : 1),
    })
    .eq("id", notification_id);

  return new Response(JSON.stringify({ ok: response.ok }), {
    headers: { "Content-Type": "application/json" },
  });
});
