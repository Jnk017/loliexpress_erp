BEGIN;
CREATE TEMP TABLE role_fixture AS
SELECT gen_random_uuid() AS actor, canonical AS role, true AS enabled, false AS needs_password
FROM unnest(ARRAY['admin','sales_rep','warehouse_staff','b2b_customer','comptable','acheteur','delivery_agent']) canonical
UNION ALL SELECT gen_random_uuid(),'admin',false,false
UNION ALL SELECT gen_random_uuid(),'admin',true,true
UNION ALL SELECT gen_random_uuid(),NULL,true,false;
GRANT SELECT ON role_fixture TO authenticated;
INSERT INTO auth.users(id,email)
SELECT actor,actor || '@example.invalid' FROM role_fixture WHERE role IS NOT NULL;
UPDATE public.user_profiles p SET
  role=f.role::public.user_role,is_active=f.enabled,must_change_password=f.needs_password
FROM role_fixture f WHERE f.actor=p.id;
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  f role_fixture;
  actual boolean[];
  expected boolean[];
  effective_role text;
  signature text;
BEGIN
  FOREACH signature IN ARRAY ARRAY[
    'can_read_finance','can_read_procurement','is_acheteur','is_admin',
    'is_admin_from_auth','is_b2b_customer','is_comptable','is_delivery_agent',
    'is_sales_rep','is_system_admin','is_warehouse_staff'
  ] LOOP
    IF has_function_privilege('anon','public.' || signature || '()','EXECUTE')
       OR NOT has_function_privilege('authenticated','public.' || signature || '()','EXECUTE') THEN
      RAISE EXCEPTION 'Privilèges inattendus : %',signature;
    END IF;
  END LOOP;
  FOR f IN SELECT * FROM role_fixture LOOP
    PERFORM set_config('request.jwt.claim.sub',f.actor::text,true);
    effective_role := CASE WHEN f.enabled AND NOT f.needs_password THEN coalesce(f.role,'') ELSE '' END;
    actual := ARRAY[
      public.can_read_finance(), public.can_read_procurement(), public.is_acheteur(), public.is_admin(),
      public.is_admin_from_auth(), public.is_b2b_customer(), public.is_comptable(), public.is_delivery_agent(),
      public.is_sales_rep(), public.is_system_admin(), public.is_warehouse_staff()
    ];
    expected := ARRAY[
      effective_role IN ('admin','comptable'), effective_role IN ('admin','acheteur','comptable'),
      effective_role='acheteur', effective_role='admin', effective_role='admin',
      effective_role='b2b_customer', effective_role='comptable', effective_role='delivery_agent',
      effective_role='sales_rep', effective_role='admin', effective_role='warehouse_staff'
    ];
    IF actual IS DISTINCT FROM expected THEN RAISE EXCEPTION 'Prédicats incohérents pour %',f.role; END IF;
  END LOOP;
END
$$;
SELECT true AS role_predicates_pass, 11 AS signatures, 110 AS evaluations;
ROLLBACK;
