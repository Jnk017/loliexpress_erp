BEGIN;
CREATE TEMP TABLE return_lookup_fixture AS SELECT
  gen_random_uuid() AS admin_id, gen_random_uuid() AS receiver,
  gen_random_uuid() AS customer, gen_random_uuid() AS product, gen_random_uuid() AS warehouse;
ALTER TABLE return_lookup_fixture ADD COLUMN order_number text;
GRANT SELECT ON return_lookup_fixture TO authenticated;
INSERT INTO auth.users (id,email)
SELECT admin_id,admin_id || '@example.invalid' FROM return_lookup_fixture
UNION ALL
SELECT receiver,receiver || '@example.invalid' FROM return_lookup_fixture;
UPDATE public.user_profiles SET role='admin',is_active=true,must_change_password=false
WHERE id=(SELECT admin_id FROM return_lookup_fixture);
UPDATE public.user_profiles SET role='warehouse_staff',is_active=true,must_change_password=false
WHERE id=(SELECT receiver FROM return_lookup_fixture);
SELECT set_config('request.jwt.claim.sub',admin_id::text,true) FROM return_lookup_fixture;
DO $$
DECLARE f return_lookup_fixture; sale public.sales_orders; delivery_id uuid;
BEGIN
  SELECT * INTO STRICT f FROM return_lookup_fixture;
  INSERT INTO public.customers(id,company_name,contact_person,email,phone,is_active)
    VALUES (f.customer,'Gate retour','Gate',f.customer || '@example.invalid','000',true);
  INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
    VALUES (f.product,f.product::text,'Produit retour Gate',10,'CDF',true);
  INSERT INTO public.warehouse_locations(id,name,is_active)
    VALUES (f.warehouse,'Réserve retour Gate',true);
  PERFORM public.adjust_stock(f.product,f.warehouse,2,'Gate retour');
  sale := public.create_order_with_items(f.customer,
    jsonb_build_array(jsonb_build_object('product_id',f.product,'quantity',2)));
  PERFORM public.transition_order_status(sale.id,'confirmed');
  PERFORM public.transition_order_status(sale.id,'processing');
  PERFORM public.transition_order_status(sale.id,'shipped');
  INSERT INTO public.deliveries(order_id,delivery_address,status)
    VALUES (sale.id,'Gate retour','pending') RETURNING id INTO delivery_id;
  PERFORM public.assign_delivery_warehouse(delivery_id,f.warehouse);
  IF (public.confirm_delivery(delivery_id)->>'success') IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'Remise de la commande de test refusée';
  END IF;
  UPDATE return_lookup_fixture SET order_number=sale.order_number;
END
$$;
SELECT set_config('request.jwt.claim.sub',receiver::text,true) FROM return_lookup_fixture;
SET LOCAL ROLE authenticated;
DO $$
DECLARE f return_lookup_fixture; line record;
BEGIN
  SELECT * INTO STRICT f FROM return_lookup_fixture;
  SELECT * INTO STRICT line FROM public.get_customer_return_lines(' ' || lower(f.order_number) || ' ');
  IF line.remaining_quantity <> 2 OR line.sku <> f.product::text
     OR line.warehouse_name <> 'Réserve retour Gate' THEN
    RAISE EXCEPTION 'Recherche de retour incohérente';
  END IF;
  BEGIN
    PERFORM public.inspect_customer_return(line.order_item_id,1,1,'Gate retour',gen_random_uuid());
    RAISE EXCEPTION 'Magasinier autorisé à déclarer un article revendable';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  PERFORM public.inspect_customer_return(line.order_item_id,1,0,'Gate retour',gen_random_uuid());
  IF (SELECT remaining_quantity FROM public.get_customer_return_lines(f.order_number)) IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'Reliquat de retour incohérent après inspection';
  END IF;
END
$$;
SELECT true AS warehouse_return_lookup_pass;
ROLLBACK;
