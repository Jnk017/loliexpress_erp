-- P0.a.1 — contrôles après 000 et avant les migrations correctives.
-- Chaque ligne doit afficher passed = true.
WITH assertions(check_name, actual, expected) AS (
    VALUES
        ('public_tables', (SELECT count(*)::text FROM pg_class WHERE relnamespace = 'public'::regnamespace AND relkind = 'r'), '61'),
        ('public_rls_tables', (SELECT count(*)::text FROM pg_class WHERE relnamespace = 'public'::regnamespace AND relkind = 'r' AND relrowsecurity), '61'),
        ('public_indexes', (SELECT count(*)::text FROM pg_class WHERE relnamespace = 'public'::regnamespace AND relkind = 'i'), '222'),
        ('public_and_storage_policies', (SELECT count(*)::text FROM pg_policies WHERE schemaname IN ('public','storage')), '135'),
        ('create_order_body', (SELECT md5(pg_get_functiondef(to_regprocedure('public.create_order_with_items(uuid,jsonb,text)')))), 'e46de76027ef6bfdf6530a9262fba5f0'),
        ('adjust_stock_body', (SELECT md5(pg_get_functiondef(to_regprocedure('public.adjust_stock(uuid,uuid,integer,text)')))), 'dbd1979b5b2312b85b0ad0b1194e11ad'),
        ('transition_absent', (to_regprocedure('public.transition_order_status(uuid,public.order_status,text)') IS NULL)::text, 'true'),
        ('password_setup_absent', (to_regprocedure('public.complete_password_setup()') IS NULL)::text, 'true'),
        ('private_documents', (SELECT (NOT public)::text FROM storage.buckets WHERE id = 'erp-documents'), 'true')
)
SELECT check_name, actual, expected, actual IS NOT DISTINCT FROM expected AS passed
FROM assertions
ORDER BY check_name;
