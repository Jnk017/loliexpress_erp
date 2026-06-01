import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async () => {
  const cutoff = new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString();
  const { data: invoices, error } = await supabase
    .from("invoices")
    .select("id, invoice_number, due_date, total_amount, customers(user_id, company_name, user_profiles(email))")
    .neq("payment_status", "paid")
    .lt("due_date", cutoff);
  if (error) return new Response(error.message, { status: 500 });

  for (const invoice of invoices ?? []) {
    const customer = Array.isArray(invoice.customers) ? invoice.customers[0] : invoice.customers;
    const profile = Array.isArray(customer?.user_profiles)
      ? customer.user_profiles[0]
      : customer?.user_profiles;
    if (!customer?.user_id || !profile?.email) continue;
    await supabase.from("notification_queue").insert({
      notification_type: "overdue_invoice",
      recipient_id: customer.user_id,
      recipient_email: profile.email,
      channel: "email",
      subject: `Rappel facture ${invoice.invoice_number}`,
      message: `La facture ${invoice.invoice_number} est impayée depuis plus de 15 jours.`,
      related_entity_type: "invoice",
      related_entity_id: invoice.id,
    });
  }

  return new Response(JSON.stringify({ queued: invoices?.length ?? 0 }), {
    headers: { "Content-Type": "application/json" },
  });
});
