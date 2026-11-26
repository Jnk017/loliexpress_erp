BEGIN;
SELECT set_config('request.jwt.claim.sub', id::text, true)
FROM public.user_profiles WHERE email='admin@loliexpress.test' AND role='admin' AND is_active;

CREATE TEMP TABLE qa_products AS
SELECT gen_random_uuid() AS id, active FROM (VALUES (true), (false)) AS states(active);
GRANT SELECT ON qa_products TO authenticated;
INSERT INTO public.products(id, sku, name, unit_price, is_active)
SELECT id, 'gate-warehouse-lookup-' || id::text, 'Gate catalogue lookup', 1, active FROM qa_products;

SELECT set_config('request.jwt.claim.sub', id::text, true)
FROM public.user_profiles WHERE role='warehouse_staff' AND is_active AND NOT must_change_password LIMIT 1;
SET LOCAL ROLE authenticated;
DO $verify$
BEGIN
  IF NOT public.is_warehouse_staff() THEN
    RAISE EXCEPTION 'An active warehouse fixture is required';
  END IF;
  IF (SELECT count(*) FROM public.products p JOIN qa_products f ON f.id=p.id WHERE f.active) <> 1
     OR EXISTS (SELECT 1 FROM public.products p JOIN qa_products f ON f.id=p.id WHERE NOT f.active) THEN
    RAISE EXCEPTION 'The warehouse catalogue must expose active products only';
  END IF;
  IF has_column_privilege(current_user, 'public.products', 'cost_price', 'SELECT') THEN
    RAISE EXCEPTION 'The warehouse catalogue must not expose cost price';
  END IF;
END;
$verify$;
SELECT true AS warehouse_product_lookup_pass;
ROLLBACK;
