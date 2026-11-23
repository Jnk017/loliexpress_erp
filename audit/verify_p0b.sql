-- P0.b — exécuter après restore_p0b_clean.sh. Toutes les lignes doivent être true.
BEGIN;
SELECT 'empty_demo_data' AS scenario, (
    NOT EXISTS (SELECT 1 FROM auth.users)
    AND NOT EXISTS (SELECT 1 FROM public.user_profiles)
    AND NOT EXISTS (SELECT 1 FROM public.customers)
    AND NOT EXISTS (SELECT 1 FROM public.products)
    AND NOT EXISTS (SELECT 1 FROM public.inventory_stock)
    AND NOT EXISTS (SELECT 1 FROM public.sales_orders)
    AND NOT EXISTS (SELECT 1 FROM public.invoices)
    AND NOT EXISTS (SELECT 1 FROM public.payments)
    AND NOT EXISTS (SELECT 1 FROM public.purchases)
    AND NOT EXISTS (SELECT 1 FROM storage.objects WHERE bucket_id = 'erp-documents')
) AS passed;
SELECT 'private_document_bucket' AS scenario,
    EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'erp-documents' AND NOT public) AS passed;

CREATE TEMP TABLE test_ids (
    label text PRIMARY KEY, id uuid NOT NULL DEFAULT gen_random_uuid()
);
INSERT INTO test_ids(label) VALUES
    ('client-a'), ('client-b'), ('driver-a'), ('driver-b'),
    ('customer-a'), ('customer-b'), ('route-a'), ('route-b');
GRANT SELECT ON test_ids TO authenticated;

INSERT INTO auth.users(id, email, raw_user_meta_data)
SELECT id, id::text || '@example.invalid',
    CASE WHEN label = 'client-a' THEN '{"role":"admin"}'::jsonb ELSE '{}'::jsonb END
FROM test_ids WHERE label IN ('client-a','client-b','driver-a','driver-b');

UPDATE public.user_profiles SET role = 'delivery_agent'
WHERE id IN (SELECT id FROM test_ids WHERE label IN ('driver-a','driver-b'));
INSERT INTO public.customers(id, user_id, company_name, contact_person, email, phone, is_active)
SELECT c.id, u.id, c.label, 'Fixture', c.id::text || '@example.invalid', '000000000', true
FROM test_ids c JOIN test_ids u ON right(c.label, 1) = right(u.label, 1)
WHERE c.label IN ('customer-a','customer-b') AND u.label IN ('client-a','client-b');
INSERT INTO public.delivery_routes(id, route_name, driver_id, route_date)
SELECT r.id, r.label, u.id, current_date
FROM test_ids r JOIN test_ids u ON right(r.label, 1) = right(u.label, 1)
WHERE r.label IN ('route-a','route-b') AND u.label IN ('driver-a','driver-b');
INSERT INTO public.deliveries(route_id, delivery_address)
SELECT id, label FROM test_ids WHERE label IN ('route-a','route-b');
INSERT INTO storage.objects(bucket_id, name, owner)
SELECT 'erp-documents', label || '/fixture.pdf', id
FROM test_ids WHERE label IN ('client-a','client-b');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', (SELECT id::text FROM test_ids WHERE label = 'client-a'), true);
SELECT 'b2b_a_scope_and_role' AS scenario,
    (SELECT array_agg(company_name ORDER BY company_name) FROM public.customers)
        IS NOT DISTINCT FROM ARRAY['customer-a']::text[]
    AND NOT public.is_admin_from_auth() AS passed;
SELECT 'storage_a_scope' AS scenario,
    (SELECT array_agg(name ORDER BY name) FROM storage.objects WHERE bucket_id = 'erp-documents')
        IS NOT DISTINCT FROM ARRAY['client-a/fixture.pdf']::text[] AS passed;
SELECT set_config('request.jwt.claim.sub', (SELECT id::text FROM test_ids WHERE label = 'client-b'), true);
SELECT 'b2b_b_scope' AS scenario,
    (SELECT array_agg(company_name ORDER BY company_name) FROM public.customers)
        IS NOT DISTINCT FROM ARRAY['customer-b']::text[] AS passed;
SELECT 'storage_b_scope' AS scenario,
    (SELECT array_agg(name ORDER BY name) FROM storage.objects WHERE bucket_id = 'erp-documents')
        IS NOT DISTINCT FROM ARRAY['client-b/fixture.pdf']::text[] AS passed;
SELECT set_config('request.jwt.claim.sub', (SELECT id::text FROM test_ids WHERE label = 'driver-a'), true);
SELECT 'driver_a_scope' AS scenario,
    (SELECT array_agg(delivery_address ORDER BY delivery_address) FROM public.deliveries)
        IS NOT DISTINCT FROM ARRAY['route-a']::text[] AS passed;
SELECT set_config('request.jwt.claim.sub', (SELECT id::text FROM test_ids WHERE label = 'driver-b'), true);
SELECT 'driver_b_scope' AS scenario,
    (SELECT array_agg(delivery_address ORDER BY delivery_address) FROM public.deliveries)
        IS NOT DISTINCT FROM ARRAY['route-b']::text[] AS passed;
RESET ROLE;
ROLLBACK;

\ir verify_p0b_settings.sql
