BEGIN;
CREATE TEMP TABLE plan_fixture AS SELECT
  gen_random_uuid() AS admin_id, gen_random_uuid() AS driver,
  gen_random_uuid() AS customer, gen_random_uuid() AS product, gen_random_uuid() AS warehouse;
ALTER TABLE plan_fixture ADD COLUMN delivery uuid;
GRANT SELECT ON plan_fixture TO authenticated;
INSERT INTO auth.users (id,email)
SELECT admin_id,admin_id || '@example.invalid' FROM plan_fixture
UNION ALL SELECT driver,driver || '@example.invalid' FROM plan_fixture;
UPDATE public.user_profiles SET role='admin',is_active=true,must_change_password=false
WHERE id=(SELECT admin_id FROM plan_fixture);
UPDATE public.user_profiles SET role='delivery_agent',is_active=true,must_change_password=false
WHERE id=(SELECT driver FROM plan_fixture);
SELECT set_config('request.jwt.claim.sub',admin_id::text,true) FROM plan_fixture;
DO $$
DECLARE f plan_fixture; sale public.sales_orders; delivery_id uuid;
BEGIN
  SELECT * INTO STRICT f FROM plan_fixture;
  INSERT INTO public.customers(id,company_name,contact_person,email,phone,is_active)
    VALUES (f.customer,'Gate planification','Gate',f.customer || '@example.invalid','000',true);
  INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
    VALUES (f.product,f.product::text,'Produit Gate',10,'CDF',true);
  INSERT INTO public.warehouse_locations(id,name,is_active)
    VALUES (f.warehouse,'Réserve Gate',true);
  PERFORM public.adjust_stock(f.product,f.warehouse,2,'Gate planification');
  sale := public.create_order_with_items(f.customer,
    jsonb_build_array(jsonb_build_object('product_id',f.product,'quantity',1)));
  BEGIN
    PERFORM public.plan_order_delivery(sale.id,f.driver,f.warehouse,'Gate',current_date);
    RAISE EXCEPTION 'Commande non expédiée planifiée';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  PERFORM public.transition_order_status(sale.id,'confirmed');
  PERFORM public.transition_order_status(sale.id,'processing');
  PERFORM public.transition_order_status(sale.id,'shipped');
  delivery_id := public.plan_order_delivery(sale.id,f.driver,f.warehouse,'Gate',current_date);
  IF delivery_id IS DISTINCT FROM public.plan_order_delivery(sale.id,f.driver,f.warehouse,'Gate',current_date)
     OR (SELECT count(*) FROM public.deliveries WHERE order_id=sale.id) <> 1
     OR (SELECT quantity FROM public.inventory_stock WHERE product_id=f.product) IS DISTINCT FROM 2
     OR NOT EXISTS (
         SELECT FROM public.deliveries d JOIN public.delivery_routes r ON r.id=d.route_id
         WHERE d.id=delivery_id AND r.driver_id=f.driver AND d.warehouse_id=f.warehouse
     ) THEN
    RAISE EXCEPTION 'Planification non idempotente ou affectation non persistée';
  END IF;
  BEGIN
    PERFORM public.plan_order_delivery(sale.id,f.driver,f.warehouse,'Autre adresse',current_date);
    RAISE EXCEPTION 'Modification implicite d’une livraison existante';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  UPDATE plan_fixture SET delivery=delivery_id;
END
$$;
SELECT set_config('request.jwt.claim.sub',driver::text,true) FROM plan_fixture;
SET LOCAL ROLE authenticated;
DO $$
DECLARE f plan_fixture;
BEGIN
  SELECT * INTO STRICT f FROM plan_fixture;
  IF has_function_privilege('anon','public.plan_order_delivery(uuid,uuid,uuid,text,date)','EXECUTE') THEN
    RAISE EXCEPTION 'Planification accessible anonymement';
  END IF;
  BEGIN
    PERFORM public.plan_order_delivery(NULL,f.driver,f.warehouse,'Gate',current_date);
    RAISE EXCEPTION 'Planification accessible au livreur';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  IF NOT EXISTS (SELECT FROM public.deliveries WHERE id=f.delivery)
     OR (public.confirm_delivery(f.delivery)->>'success') IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'Remise refusée au livreur affecté';
  END IF;
END
$$;
RESET ROLE;
DO $$
DECLARE f plan_fixture;
BEGIN
  SELECT * INTO STRICT f FROM plan_fixture;
  IF (SELECT quantity FROM public.inventory_stock WHERE product_id=f.product) IS DISTINCT FROM 1
     OR (SELECT count(*) FROM public.stock_movements WHERE reference_id=f.delivery
         AND reference_type='customer_handover') <> 1 THEN
    RAISE EXCEPTION 'Écriture du stock à la remise incohérente';
  END IF;
END
$$;
SELECT true AS delivery_planning_pass;
ROLLBACK;
