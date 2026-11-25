BEGIN;
CREATE TEMP TABLE reporting_fixture AS
SELECT gen_random_uuid() AS admin_id, gen_random_uuid() AS finance_id;
GRANT SELECT ON reporting_fixture TO authenticated;
INSERT INTO auth.users (id,email)
SELECT admin_id,admin_id || '@example.invalid' FROM reporting_fixture
UNION ALL SELECT finance_id,finance_id || '@example.invalid' FROM reporting_fixture;
UPDATE public.user_profiles SET role='admin',is_active=true,must_change_password=false
WHERE id=(SELECT admin_id FROM reporting_fixture);
UPDATE public.user_profiles SET role='comptable',is_active=true,must_change_password=false
WHERE id=(SELECT finance_id FROM reporting_fixture);
SET LOCAL ROLE authenticated;
DO $$
DECLARE f reporting_fixture; signature text;
BEGIN
  SELECT * INTO STRICT f FROM reporting_fixture;
  FOREACH signature IN ARRAY ARRAY[
    'get_admin_total_report(timestamptz,timestamptz)',
    'get_company_settings()','update_company_settings(jsonb)','get_workspace_setup_progress()'
  ] LOOP
    IF has_function_privilege('anon','public.' || signature,'EXECUTE')
      OR NOT has_function_privilege('authenticated','public.' || signature,'EXECUTE') THEN
      RAISE EXCEPTION 'Privilèges inattendus pour %',signature;
    END IF;
  END LOOP;
  PERFORM set_config('request.jwt.claim.sub',f.finance_id::text,true);
  BEGIN
    PERFORM public.get_admin_total_report(now()-interval '1 day',now());
    RAISE EXCEPTION 'Rapport administratif permis au comptable';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
    WHEN raise_exception THEN
      IF SQLERRM IS DISTINCT FROM 'admin only' THEN RAISE; END IF;
  END;
  PERFORM set_config('request.jwt.claim.sub',f.admin_id::text,true);
  IF public.get_admin_total_report(now()-interval '1 day',now()) IS NULL THEN
    RAISE EXCEPTION 'Rapport absent pour l’administrateur';
  END IF;
END
$$;
SELECT true AS admin_reporting_boundary_pass;
ROLLBACK;
