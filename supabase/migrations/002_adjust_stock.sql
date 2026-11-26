-- P0.a — aligner le contrat Flutter avec le registre des mouvements.
BEGIN;
DROP FUNCTION IF EXISTS public.adjust_stock(uuid, uuid, integer, text);
CREATE OR REPLACE FUNCTION public.adjust_stock(
    p_product_id uuid, p_warehouse_id uuid, p_quantity_delta integer, p_reason text,
    p_reference_id uuid DEFAULT NULL, p_reference_type text DEFAULT 'manual_adjustment'
)
RETURNS public.inventory_stock
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE
    stock public.inventory_stock%ROWTYPE;
    ledger_quantity bigint;
BEGIN
    IF coalesce(public.current_user_role(), '') NOT IN ('admin', 'warehouse_staff') THEN
        RAISE EXCEPTION 'Stock adjustment denied' USING ERRCODE = '42501';
    END IF;
    IF p_quantity_delta IS NULL OR p_quantity_delta = 0 OR nullif(btrim(p_reason), '') IS NULL THEN
        RAISE EXCEPTION 'Nonzero quantity and reason required' USING ERRCODE = '22023';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = p_product_id AND is_active)
        OR NOT EXISTS (SELECT 1 FROM public.warehouse_locations WHERE id = p_warehouse_id AND is_active) THEN
        RAISE EXCEPTION 'Product or warehouse unavailable' USING ERRCODE = '23503';
    END IF;
    INSERT INTO public.inventory_stock(product_id, warehouse_id, quantity)
    VALUES (p_product_id, p_warehouse_id, 0)
    ON CONFLICT (product_id, warehouse_id) DO NOTHING;
    SELECT * INTO STRICT stock FROM public.inventory_stock
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id FOR UPDATE;
    SELECT coalesce(sum(CASE WHEN movement_type = 'out' THEN -quantity::bigint ELSE quantity END), 0)
    INTO ledger_quantity FROM public.stock_movements
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;
    IF ledger_quantity <> stock.quantity OR ledger_quantity + p_quantity_delta < 0 THEN
        RAISE EXCEPTION 'Stock adjustment would create an invalid balance' USING ERRCODE = '22003';
    END IF;
    INSERT INTO public.stock_movements(product_id, warehouse_id, movement_type, quantity,
        reference_id, reference_type, notes, created_by)
    VALUES (p_product_id, p_warehouse_id, 'adjustment', p_quantity_delta,
        p_reference_id, p_reference_type, btrim(p_reason), auth.uid());
    SELECT * INTO STRICT stock FROM public.inventory_stock
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;
    INSERT INTO public.audit_logs(table_name, record_id, action_type, new_values, user_id)
    VALUES ('inventory_stock', stock.id, 'update',
        jsonb_build_object('delta', p_quantity_delta, 'quantity', stock.quantity, 'reason', p_reason), auth.uid());
    RETURN stock;
END;
$fn$;
REVOKE INSERT, UPDATE, DELETE ON public.inventory_stock, public.stock_movements FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.adjust_stock(uuid, uuid, integer, text, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.adjust_stock(uuid, uuid, integer, text, uuid, text) TO authenticated;
COMMIT;
