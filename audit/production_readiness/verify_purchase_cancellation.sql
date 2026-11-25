BEGIN;
CREATE TEMP TABLE cancel_fixture AS
SELECT gen_random_uuid() AS buyer, gen_random_uuid() AS supplier,
       gen_random_uuid() AS product, gen_random_uuid() AS warehouse;
GRANT SELECT ON cancel_fixture TO authenticated;
INSERT INTO auth.users(id,email) SELECT buyer,buyer || '@example.invalid' FROM cancel_fixture;
UPDATE public.user_profiles SET role='acheteur',is_active=true,must_change_password=false
WHERE id=(SELECT buyer FROM cancel_fixture);
SELECT set_config('request.jwt.claim.sub',buyer::text,true) FROM cancel_fixture;
INSERT INTO public.suppliers(id,company_name,is_active) SELECT supplier,'Gate annulation',true FROM cancel_fixture;
INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
SELECT product,product::text,'Gate annulation',5,'CDF',true FROM cancel_fixture;
INSERT INTO public.warehouse_locations(id,name,is_active) SELECT warehouse,warehouse::text,true FROM cancel_fixture;

SET LOCAL ROLE authenticated;
DO $$
DECLARE f cancel_fixture; purchase public.purchases; item uuid; items jsonb;
BEGIN
  SELECT * INTO STRICT f FROM cancel_fixture;
  items := jsonb_build_array(jsonb_build_object('product_id',f.product,'quantity',2,'unit_cost',5));
  purchase := public.create_purchase_with_items(f.supplier,items,'CDF',1,NULL);
  IF (public.cancel_unreceived_purchase(purchase.id)).status IS DISTINCT FROM 'cancelled'
     OR (public.cancel_unreceived_purchase(purchase.id)).status IS DISTINCT FROM 'cancelled' THEN
    RAISE EXCEPTION 'Annulation ou répétition incohérente';
  END IF;
  purchase := public.create_purchase_with_items(f.supplier,items,'CDF',1,NULL);
  SELECT id INTO STRICT item FROM public.purchase_items WHERE purchase_id=purchase.id;
  PERFORM public.receive_purchase_item(item,f.warehouse,1,gen_random_uuid());
  BEGIN
    PERFORM public.cancel_unreceived_purchase(purchase.id);
    RAISE EXCEPTION 'Achat partiellement reçu annulé';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  purchase := public.create_purchase_with_items(f.supplier,items,'CDF',1,NULL);
  PERFORM public.register_supplier_bill(purchase.id,'Gate-' || purchase.id,current_date+7,10);
  BEGIN
    PERFORM public.cancel_unreceived_purchase(purchase.id);
    RAISE EXCEPTION 'Achat facturé annulé';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
END
$$;
SELECT true AS purchase_cancellation_pass;
ROLLBACK;
