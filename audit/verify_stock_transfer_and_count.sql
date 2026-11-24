-- Run only on the gate test database after migration 019 and QA account setup.
BEGIN;
CREATE TEMP TABLE qa_stock_operation (
  product_id uuid NOT NULL DEFAULT gen_random_uuid(),
  source_id uuid NOT NULL DEFAULT gen_random_uuid(),
  destination_id uuid NOT NULL DEFAULT gen_random_uuid(),
  admin_id uuid NOT NULL,
  client_id uuid NOT NULL
);
INSERT INTO qa_stock_operation(admin_id, client_id)
VALUES (
  (SELECT id FROM public.user_profiles WHERE email='admin@loliexpress.test' AND role='admin' AND is_active),
  (SELECT id FROM public.user_profiles WHERE email='client-a@loliexpress.test' AND role='b2b_customer' AND is_active)
);
SELECT set_config('request.jwt.claims', '{}', true);
SELECT set_config('request.jwt.claim.sub', admin_id::text, true) FROM qa_stock_operation;
INSERT INTO public.products(id, sku, name, unit_price, currency, is_active)
  SELECT product_id, 'qa-' || product_id::text, 'Article QA', 1, 'CDF', true FROM qa_stock_operation;
INSERT INTO public.warehouse_locations(id, name, is_active)
  SELECT source_id, 'Origine QA ' || source_id::text, true FROM qa_stock_operation
  UNION ALL
  SELECT destination_id, 'Destination QA ' || destination_id::text, true FROM qa_stock_operation;

GRANT SELECT ON qa_stock_operation TO authenticated;
SET LOCAL ROLE authenticated;
DO $qa$
DECLARE
  f qa_stock_operation%ROWTYPE;
  transfer_id uuid;
  count_id uuid;
BEGIN
  SELECT * INTO STRICT f FROM qa_stock_operation;
  PERFORM public.adjust_stock(f.product_id, f.source_id, 10, 'Initial QA');
  transfer_id := public.transfer_stock(f.product_id, f.source_id, f.destination_id, 4, 'Transfert QA');
  IF (SELECT count(*) FROM public.stock_movements
      WHERE reference_id = transfer_id AND reference_type = 'warehouse_transfer') <> 2
    OR (SELECT quantity FROM public.inventory_stock WHERE product_id=f.product_id AND warehouse_id=f.source_id) IS DISTINCT FROM 6
    OR (SELECT quantity FROM public.inventory_stock WHERE product_id=f.product_id AND warehouse_id=f.destination_id) IS DISTINCT FROM 4 THEN
    RAISE EXCEPTION 'Transfer did not preserve quantity or traceability';
  END IF;

  BEGIN
    PERFORM public.transfer_stock(f.product_id, f.source_id, f.destination_id, 7, 'Dépassement QA');
    RAISE EXCEPTION 'Insufficient stock was accepted';
  EXCEPTION WHEN numeric_value_out_of_range THEN NULL;
  END;
  IF (SELECT count(*) FROM public.stock_movements WHERE product_id=f.product_id) <> 3 THEN
    RAISE EXCEPTION 'Rejected transfer created a movement';
  END IF;

  count_id := public.record_physical_stock_count(f.product_id, f.destination_id, 4, 2, 'Comptage QA');
  IF NOT EXISTS (SELECT FROM public.stock_movements WHERE reference_id=count_id AND reference_type='physical_count' AND quantity=-2)
    OR (SELECT quantity FROM public.inventory_stock WHERE product_id=f.product_id AND warehouse_id=f.destination_id) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'Count did not update the recorded stock';
  END IF;

  BEGIN
    PERFORM public.record_physical_stock_count(f.product_id, f.destination_id, 4, 3, 'Solde périmé QA');
    RAISE EXCEPTION 'Stale stock count was accepted';
  EXCEPTION WHEN serialization_failure THEN NULL;
  END;
  count_id := public.record_physical_stock_count(f.product_id, f.destination_id, 2, 2, 'Comptage sans écart QA');
  IF EXISTS (SELECT FROM public.stock_movements WHERE reference_id=count_id)
    OR NOT EXISTS (SELECT FROM public.audit_logs WHERE new_values->>'physical_count_id'=count_id::text) THEN
    RAISE EXCEPTION 'Unchanged count should be audited without movement';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', f.client_id::text, true);
  BEGIN
    PERFORM public.transfer_stock(f.product_id, f.source_id, f.destination_id, 1, 'Interdit QA');
    RAISE EXCEPTION 'B2B transfer was accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.record_physical_stock_count(f.product_id, f.destination_id, 2, 3, 'Interdit QA');
    RAISE EXCEPTION 'B2B count was accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$qa$;
SELECT true AS stock_workflows_pass;
ROLLBACK;
