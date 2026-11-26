-- Warehouse staff need catalogue lookup for the scanner and inventory.
-- Migration 030 still governs the client-visible columns.
CREATE POLICY warehouse_staff_read_active_products ON public.products
FOR SELECT TO authenticated
USING ((SELECT public.is_warehouse_staff()) AND is_active);
