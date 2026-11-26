-- Drivers read their assigned deliveries and confirm through the handover RPC.
DROP POLICY IF EXISTS delivery_agent_update_assigned_deliveries ON public.deliveries;

-- These operations bypass or change row-level enforcement and are never
-- required by the application roles.
REVOKE TRUNCATE, TRIGGER
  ON public.deliveries, public.delivery_routes, public.sales_orders, public.order_items,
     public.inventory_stock, public.stock_movements
  FROM PUBLIC, anon, authenticated;
