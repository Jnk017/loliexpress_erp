BEGIN READ ONLY;
WITH RECURSIVE dependencies(target, dependent) AS (
  SELECT c.oid, c.oid FROM pg_class c
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname='public'
    AND c.relname IN ('company_settings','customer_product_prices',
                      'operational_treasury_postings','stock_handovers')
  UNION
  SELECT d.target, vw.oid
  FROM dependencies d
  JOIN pg_depend p ON p.refclassid='pg_class'::regclass AND p.refobjid=d.dependent
                   AND p.classid='pg_rewrite'::regclass
  JOIN pg_rewrite rw ON p.objid=rw.oid
  JOIN pg_class vw ON vw.oid=rw.ev_class AND vw.relkind IN ('v','m')
)
SELECT target::regclass::text AS protected_table, dependent::regclass::text AS view_name,
       COALESCE('security_invoker=true'=ANY(c.reloptions),false) AS security_invoker,
       has_table_privilege('anon',dependent,'SELECT') AS anon_select,
       has_table_privilege('authenticated',dependent,'SELECT') AS authenticated_select
FROM dependencies d JOIN pg_class c ON c.oid=d.dependent
WHERE target<>dependent
ORDER BY 1,2;
ROLLBACK;
