BEGIN;
CREATE TEMP TABLE receipt_fixture AS
SELECT gen_random_uuid() AS actor, gen_random_uuid() AS supplier,
       gen_random_uuid() AS product, gen_random_uuid() AS warehouse,
       gen_random_uuid() AS request_id;
ALTER TABLE receipt_fixture ADD COLUMN item_id uuid;
GRANT SELECT ON receipt_fixture TO authenticated;
INSERT INTO auth.users (id,email) SELECT actor,actor || '@example.invalid' FROM receipt_fixture;
UPDATE public.user_profiles SET role='admin',is_active=true,must_change_password=false
WHERE id=(SELECT actor FROM receipt_fixture);
SELECT set_config('request.jwt.claim.sub',actor::text,true) FROM receipt_fixture;
INSERT INTO public.suppliers(id,company_name,is_active)
SELECT supplier,'Réception Gate',true FROM receipt_fixture;
INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
SELECT product,product::text,'Réception Gate',20,'CDF',true FROM receipt_fixture;
INSERT INTO public.warehouse_locations(id,name,is_active)
SELECT warehouse,warehouse::text,true FROM receipt_fixture;
DO $$
DECLARE f receipt_fixture; purchase public.purchases;
BEGIN
  SELECT * INTO STRICT f FROM receipt_fixture;
  purchase := public.create_purchase_with_items(f.supplier,
      jsonb_build_array(jsonb_build_object('product_id',f.product,'quantity',2,'unit_cost',10)),
      'CDF',1,NULL);
  UPDATE receipt_fixture SET item_id=(SELECT id FROM public.purchase_items WHERE purchase_id=purchase.id);
END
$$;
UPDATE public.user_profiles SET role='warehouse_staff'
WHERE id=(SELECT actor FROM receipt_fixture);
SET LOCAL ROLE authenticated;
DO $$
DECLARE f receipt_fixture;
BEGIN
  SELECT * INTO STRICT f FROM receipt_fixture;
  IF NOT EXISTS (
    SELECT FROM public.list_warehouse_purchase_receipts() WHERE purchase_item_id=f.item_id
     AND remaining_quantity=2
  ) OR EXISTS (SELECT FROM public.purchase_items WHERE id=f.item_id) THEN
    RAISE EXCEPTION 'La file doit exposer la réception sans exposer les données financières';
  END IF;
  PERFORM public.receive_purchase_item(f.item_id,f.warehouse,2,f.request_id);
  PERFORM public.receive_purchase_item(f.item_id,f.warehouse,2,f.request_id);
  IF EXISTS (SELECT FROM public.list_warehouse_purchase_receipts() WHERE purchase_item_id=f.item_id)
     OR NOT EXISTS (SELECT FROM public.inventory_stock WHERE product_id=f.product AND quantity=2) THEN
    RAISE EXCEPTION 'La réception ne correspond pas au stock ou à la file';
  END IF;
  PERFORM set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
  BEGIN
    PERFORM public.list_warehouse_purchase_receipts();
    RAISE EXCEPTION 'Compte sans profil autorisé';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$$;
SELECT true AS warehouse_receipt_queue_pass;
ROLLBACK;
