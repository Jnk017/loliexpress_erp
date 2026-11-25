BEGIN;
CREATE TEMP TABLE procurement_fixture AS
SELECT gen_random_uuid() AS admin, gen_random_uuid() AS buyer, gen_random_uuid() AS outsider,
       gen_random_uuid() AS active_product, gen_random_uuid() AS inactive_product;
GRANT SELECT ON procurement_fixture TO authenticated;
INSERT INTO auth.users(id,email)
SELECT id,id || '@example.invalid' FROM procurement_fixture f
CROSS JOIN LATERAL unnest(ARRAY[f.admin,f.buyer,f.outsider]) AS id;
UPDATE public.user_profiles SET role='admin',is_active=true,must_change_password=false
WHERE id=(SELECT admin FROM procurement_fixture);
UPDATE public.user_profiles SET role='acheteur',is_active=true,must_change_password=false
WHERE id=(SELECT buyer FROM procurement_fixture);
UPDATE public.user_profiles SET role='warehouse_staff',is_active=true,must_change_password=false
WHERE id=(SELECT outsider FROM procurement_fixture);
SELECT set_config('request.jwt.claim.sub',admin::text,true) FROM procurement_fixture;
INSERT INTO public.products(id,sku,name,unit_price,cost_price,currency,is_active)
SELECT active_product,active_product::text,'Gate achat actif',10,2,'CDF',true FROM procurement_fixture
UNION ALL
SELECT inactive_product,inactive_product::text,'Gate achat inactif',10,2,'CDF',false FROM procurement_fixture;
SET LOCAL ROLE authenticated;
DO $$
DECLARE f procurement_fixture; row_data jsonb;
BEGIN
  SELECT * INTO STRICT f FROM procurement_fixture;
  PERFORM set_config('request.jwt.claim.sub',f.buyer::text,true);
  SELECT to_jsonb(p) INTO row_data FROM public.list_procurement_product_choices() p WHERE p.id=f.active_product;
  IF row_data IS DISTINCT FROM jsonb_build_object('id',f.active_product,'name','Gate achat actif')
     OR EXISTS (SELECT FROM public.list_procurement_product_choices() WHERE id=f.inactive_product)
     OR EXISTS (SELECT FROM public.products WHERE id=f.active_product) THEN
    RAISE EXCEPTION 'Unexpected procurement product visibility';
  END IF;
  PERFORM set_config('request.jwt.claim.sub',f.outsider::text,true);
  BEGIN
    PERFORM public.list_procurement_product_choices();
    RAISE EXCEPTION 'Non-procurement account accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END
$$;
SELECT true AS procurement_product_choices_pass;
ROLLBACK;
