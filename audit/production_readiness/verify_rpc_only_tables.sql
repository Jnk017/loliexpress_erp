BEGIN READ ONLY;
SELECT set_config('request.jwt.claim.sub', id::text, true)
  FROM public.user_profiles WHERE role = 'admin' AND is_active LIMIT 1;
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  target text;
  visible_count bigint;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Profil admin de test manquant'; END IF;
  FOREACH target IN ARRAY ARRAY[
    'company_settings', 'customer_product_prices',
    'operational_treasury_postings', 'stock_handovers'
  ] LOOP
    BEGIN
      EXECUTE format('SELECT count(*) FROM public.%I', target) INTO visible_count;
      IF visible_count <> 0 THEN
        RAISE EXCEPTION 'Des lignes sont exposées par lecture directe dans %', target;
      END IF;
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
  END LOOP;
END
$$;
ROLLBACK;

BEGIN;
SELECT set_config('request.jwt.claim.sub', id::text, true)
  FROM public.user_profiles WHERE role = 'admin' AND is_active LIMIT 1;
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  target text;
  affected bigint;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Profil admin de test manquant'; END IF;
  FOREACH target IN ARRAY ARRAY[
    'company_settings', 'customer_product_prices',
    'operational_treasury_postings', 'stock_handovers'
  ] LOOP
    BEGIN
      EXECUTE format('INSERT INTO public.%I DEFAULT VALUES', target);
      RAISE EXCEPTION 'Insertion directe autorisée dans %', target;
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
    BEGIN
      EXECUTE format('DELETE FROM public.%I', target);
      GET DIAGNOSTICS affected = ROW_COUNT;
      IF affected <> 0 THEN
        RAISE EXCEPTION 'Suppression directe possible dans %', target;
      END IF;
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
  END LOOP;
END
$$;
ROLLBACK;
SELECT true AS rpc_only_tables_pass;
