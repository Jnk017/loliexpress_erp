-- Run on the isolated gate database after migration 022. Roll back all fixtures.
BEGIN;
CREATE TEMP TABLE qa_setup_roles (role_name text PRIMARY KEY, user_id uuid NOT NULL);
INSERT INTO qa_setup_roles VALUES
  ('admin',(SELECT id FROM public.user_profiles WHERE email='admin@loliexpress.test' AND is_active AND role='admin')),
  ('buyer',(SELECT id FROM public.user_profiles WHERE email='acheteur@loliexpress.test' AND is_active AND role='acheteur')),
  ('customer',(SELECT id FROM public.user_profiles WHERE email='client-a@loliexpress.test' AND is_active AND role='b2b_customer'));
GRANT SELECT ON qa_setup_roles TO authenticated;
SELECT set_config('request.jwt.claims','{}',true);
SELECT set_config('request.jwt.claim.sub',user_id::text,true) FROM qa_setup_roles WHERE role_name='admin';
SET LOCAL ROLE authenticated;
DO $qa$
DECLARE
  cash_id uuid := gen_random_uuid();
  bank_id uuid := gen_random_uuid();
  wallet_id uuid := gen_random_uuid();
  warehouse_id uuid;
  supplier_id uuid;
BEGIN
  PERFORM public.open_treasury_account(cash_id,'cash','QA caisse',NULL,'CDF',125.50);
  PERFORM public.open_treasury_account(cash_id,'cash','QA caisse',NULL,'CDF',125.50);
  PERFORM public.open_treasury_account(bank_id,'bank_transfer','QA banque','QA fournisseur','USD',0);
  PERFORM public.open_treasury_account(wallet_id,'mobile_money','QA portefeuille','QA opérateur','USD',5);
  IF (SELECT current_balance FROM public.cash_registers WHERE id=cash_id) IS DISTINCT FROM 125.50
    OR (SELECT opening_balance FROM public.cash_registers WHERE id=cash_id) IS DISTINCT FROM 125.50
    OR (SELECT count(*) FROM public.cash_movements WHERE cash_register_id=cash_id AND movement_type='in') <> 1
    OR (SELECT current_balance FROM public.bank_accounts WHERE id=bank_id) IS DISTINCT FROM 0
    OR EXISTS (SELECT FROM public.bank_transactions WHERE bank_account_id=bank_id)
    OR (SELECT current_balance FROM public.bank_accounts WHERE id=wallet_id AND account_channel='mobile_money') IS DISTINCT FROM 5
    OR (SELECT count(*) FROM public.bank_transactions WHERE bank_account_id=wallet_id AND transaction_type='credit') <> 1 THEN
    RAISE EXCEPTION 'Account opening does not reconcile';
  END IF;
  BEGIN
    PERFORM public.open_treasury_account(cash_id,'cash','QA caisse',NULL,'CDF',126);
    RAISE EXCEPTION 'Conflicting request accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    INSERT INTO public.cash_registers(name,currency,opening_balance,current_balance) VALUES ('Bypass QA','CDF',10,10);
    RAISE EXCEPTION 'Direct account insert accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  INSERT INTO public.warehouse_locations(name,address,is_active)
    VALUES ('QA entrepôt','QA adresse',true) RETURNING id INTO warehouse_id;
  IF NOT EXISTS (SELECT FROM public.warehouse_locations WHERE id=warehouse_id AND is_active) THEN
    RAISE EXCEPTION 'Warehouse not readable after insert';
  END IF;

  PERFORM set_config('request.jwt.claim.sub',(SELECT user_id::text FROM qa_setup_roles WHERE role_name='buyer'),true);
  INSERT INTO public.suppliers(company_name,address,is_active)
    VALUES ('QA fournisseur','QA adresse',true) RETURNING id INTO supplier_id;
  IF NOT EXISTS (SELECT FROM public.suppliers WHERE id=supplier_id AND is_active) THEN
    RAISE EXCEPTION 'Supplier not readable after insert';
  END IF;
  BEGIN
    PERFORM public.open_treasury_account(gen_random_uuid(),'cash','QA refusée',NULL,'CDF',0);
    RAISE EXCEPTION 'Buyer can open treasury account';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;

  PERFORM set_config('request.jwt.claim.sub',(SELECT user_id::text FROM qa_setup_roles WHERE role_name='customer'),true);
  BEGIN
    INSERT INTO public.warehouse_locations(name,is_active) VALUES ('QA refus',true);
    RAISE EXCEPTION 'B2B can create a warehouse';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    INSERT INTO public.suppliers(company_name,is_active) VALUES ('QA refus',true);
    RAISE EXCEPTION 'B2B can create a supplier';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$qa$;
SELECT true AS account_opening_pass, true AS warehouse_and_supplier_pass, true AS role_guards_pass;
ROLLBACK;
