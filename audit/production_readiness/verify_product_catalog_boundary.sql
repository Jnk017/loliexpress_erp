BEGIN READ ONLY;
DO $$
BEGIN
  IF has_table_privilege('authenticated','public.products','SELECT,TRUNCATE,TRIGGER')
     OR has_table_privilege('anon','public.products','SELECT,TRUNCATE,TRIGGER')
     OR has_column_privilege('authenticated','public.products','cost_price','SELECT')
     OR NOT has_column_privilege('authenticated','public.products','name','SELECT')
     OR NOT has_column_privilege('authenticated','public.products','unit_price','SELECT') THEN
    RAISE EXCEPTION 'Droits du catalogue inattendus';
  END IF;
END
$$;
SELECT true AS product_catalog_boundary_pass;
ROLLBACK;
