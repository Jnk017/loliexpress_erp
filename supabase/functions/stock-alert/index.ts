import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async () => {
  const { data: stock, error } = await supabase
    .from("inventory_stock")
    .select("id, product_id, quantity, reorder_level, products(name)")
    .lte("quantity", "reorder_level");
  if (error) return new Response(error.message, { status: 500 });

  const { data: recipients } = await supabase
    .from("user_profiles")
    .select("id, email")
    .in("role", ["admin", "warehouse_staff"])
    .eq("is_active", true);

  for (const item of stock ?? []) {
    const product = Array.isArray(item.products) ? item.products[0] : item.products;
    for (const recipient of recipients ?? []) {
      await supabase.from("notification_queue").insert({
        notification_type: "low_stock",
        recipient_id: recipient.id,
        recipient_email: recipient.email,
        channel: "both",
        subject: "Alerte stock bas",
        message: `${product?.name ?? "Produit"} est sous le seuil (${item.quantity}/${item.reorder_level}).`,
        related_entity_type: "product",
        related_entity_id: item.product_id,
      });
    }
  }

  return new Response(JSON.stringify({ checked: stock?.length ?? 0 }), {
    headers: { "Content-Type": "application/json" },
  });
});
