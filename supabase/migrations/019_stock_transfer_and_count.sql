BEGIN;

CREATE OR REPLACE FUNCTION public.transfer_stock(
  p_product_id uuid, p_source_id uuid, p_destination_id uuid,
  p_quantity integer, p_reason text
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE
  v_reference uuid := gen_random_uuid();
BEGIN
  IF coalesce(public.current_user_role(), '') NOT IN ('admin', 'warehouse_staff') THEN
    RAISE EXCEPTION 'Stock transfer denied' USING ERRCODE = '42501';
  END IF;
  IF p_source_id IS NULL OR p_destination_id IS NULL OR p_source_id = p_destination_id
    OR p_quantity IS NULL OR p_quantity <= 0 OR nullif(btrim(p_reason), '') IS NULL THEN
    RAISE EXCEPTION 'Distinct warehouses, positive quantity and reason required'
      USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT FROM public.products WHERE id = p_product_id AND is_active)
    OR (SELECT count(*) FROM public.warehouse_locations
        WHERE id IN (p_source_id, p_destination_id) AND is_active) <> 2 THEN
    RAISE EXCEPTION 'Product or warehouse unavailable' USING ERRCODE = '23503';
  END IF;
  INSERT INTO public.inventory_stock(product_id, warehouse_id, quantity)
    SELECT p_product_id, id, 0 FROM public.warehouse_locations
    WHERE id IN (p_source_id, p_destination_id) ORDER BY id
    ON CONFLICT (product_id, warehouse_id) DO NOTHING;
  PERFORM 1 FROM public.inventory_stock
    WHERE product_id = p_product_id AND warehouse_id IN (p_source_id, p_destination_id)
    ORDER BY warehouse_id FOR UPDATE;

  PERFORM public.adjust_stock(p_product_id, p_source_id, -p_quantity, p_reason,
    v_reference, 'warehouse_transfer');
  PERFORM public.adjust_stock(p_product_id, p_destination_id, p_quantity, p_reason,
    v_reference, 'warehouse_transfer');
  RETURN v_reference;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.record_physical_stock_count(
  p_product_id uuid, p_warehouse_id uuid, p_expected_quantity integer,
  p_counted_quantity integer, p_reason text
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE
  v_stock public.inventory_stock%ROWTYPE;
  v_reference uuid := gen_random_uuid();
BEGIN
  IF coalesce(public.current_user_role(), '') NOT IN ('admin', 'warehouse_staff') THEN
    RAISE EXCEPTION 'Physical stock count denied' USING ERRCODE = '42501';
  END IF;
  IF p_expected_quantity IS NULL OR p_counted_quantity IS NULL OR p_counted_quantity < 0
    OR nullif(btrim(p_reason), '') IS NULL THEN
    RAISE EXCEPTION 'Nonnegative count and reason required' USING ERRCODE = '22023';
  END IF;
  IF NOT EXISTS (SELECT FROM public.products WHERE id = p_product_id AND is_active)
    OR NOT EXISTS (SELECT FROM public.warehouse_locations WHERE id = p_warehouse_id AND is_active) THEN
    RAISE EXCEPTION 'Product or warehouse unavailable' USING ERRCODE = '23503';
  END IF;
  SELECT * INTO v_stock FROM public.inventory_stock
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id FOR UPDATE;
  IF NOT FOUND OR v_stock.quantity IS DISTINCT FROM p_expected_quantity THEN
    RAISE EXCEPTION 'Stock changed; reload before recording the count' USING ERRCODE = '40001';
  END IF;
  IF p_counted_quantity <> p_expected_quantity THEN
    PERFORM public.adjust_stock(p_product_id, p_warehouse_id,
      p_counted_quantity - p_expected_quantity, p_reason, v_reference, 'physical_count');
  END IF;
  INSERT INTO public.audit_logs(table_name, record_id, action_type, new_values, user_id)
    VALUES ('inventory_stock', v_stock.id, 'update', jsonb_build_object(
      'physical_count_id', v_reference, 'expected_quantity', p_expected_quantity,
      'counted_quantity', p_counted_quantity, 'reason', btrim(p_reason)), auth.uid());
  RETURN v_reference;
END;
$fn$;

REVOKE ALL ON FUNCTION public.transfer_stock(uuid, uuid, uuid, integer, text),
  public.record_physical_stock_count(uuid, uuid, integer, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.transfer_stock(uuid, uuid, uuid, integer, text),
  public.record_physical_stock_count(uuid, uuid, integer, integer, text) TO authenticated;

COMMIT;
