BEGIN;
CREATE TEMP TABLE gate_delivery_actor AS
SELECT gen_random_uuid() AS driver, gen_random_uuid() AS route, gen_random_uuid() AS delivery;
GRANT SELECT ON gate_delivery_actor TO authenticated;
INSERT INTO auth.users (id,email) SELECT driver,driver || '@example.invalid' FROM gate_delivery_actor;
UPDATE public.user_profiles SET role='delivery_agent',is_active=true,must_change_password=false
WHERE id=(SELECT driver FROM gate_delivery_actor);
INSERT INTO public.delivery_routes (id,route_name,driver_id,route_date)
SELECT route,'Gate confirmation fixture',driver,current_date FROM gate_delivery_actor;
INSERT INTO public.deliveries (id,route_id,delivery_address,status)
SELECT delivery,route,'Gate confirmation fixture','pending' FROM gate_delivery_actor;
SELECT set_config('request.jwt.claim.sub',driver::text,true) FROM gate_delivery_actor;
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  target uuid := (SELECT delivery FROM gate_delivery_actor);
  signature text;
BEGIN
  IF NOT EXISTS (SELECT FROM public.deliveries WHERE id=target) THEN
    RAISE EXCEPTION 'Le livreur doit lire sa livraison affectée';
  END IF;
  UPDATE public.deliveries SET notes='Modification directe' WHERE id=target;
  IF FOUND THEN RAISE EXCEPTION 'Modification directe de la livraison autorisée'; END IF;
  IF (public.confirm_delivery(target)->>'error') IS DISTINCT FROM
       'Pending delivery and active assigned warehouse required' THEN
    RAISE EXCEPTION 'Le livreur affecté doit atteindre les contrôles métier';
  END IF;
  PERFORM set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
  IF EXISTS (SELECT FROM public.deliveries WHERE id=target)
     OR (public.confirm_delivery(target)->>'error') IS DISTINCT FROM
       'Delivery confirmation denied' THEN
    RAISE EXCEPTION 'Le compte sans profil doit être refusé';
  END IF;
  FOREACH signature IN ARRAY ARRAY[
    'public.assign_delivery_warehouse(uuid,uuid)',
    'public.confirm_delivery(uuid,text,text)',
    'public.transition_order_status(uuid,public.order_status,text)',
    'public.adjust_stock(uuid,uuid,integer,text,uuid,text)',
    'public.transfer_stock(uuid,uuid,uuid,integer,text)',
    'public.record_physical_stock_count(uuid,uuid,integer,integer,text)'
  ] LOOP
    IF has_function_privilege('anon',signature,'EXECUTE')
       OR NOT has_function_privilege('authenticated',signature,'EXECUTE') THEN
      RAISE EXCEPTION 'Privilèges inattendus pour %',signature;
    END IF;
  END LOOP;
  IF has_table_privilege('authenticated','public.stock_movements','TRUNCATE,TRIGGER')
     OR has_table_privilege('anon','public.deliveries','TRUNCATE,TRIGGER') THEN
    RAISE EXCEPTION 'Droits de commande de table encore présents';
  END IF;
END
$$;
SELECT true AS delivery_client_boundary_pass;
ROLLBACK;
