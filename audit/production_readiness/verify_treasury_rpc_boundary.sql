BEGIN;
CREATE TEMP TABLE role_fixtures (id uuid, role text, state text);
INSERT INTO role_fixtures
SELECT gen_random_uuid(), role, 'active'
FROM unnest(ARRAY['admin','comptable','sales_rep','acheteur','warehouse_staff','delivery_agent','b2b_customer']) AS role
UNION ALL SELECT gen_random_uuid(), 'admin', 'inactive'
UNION ALL SELECT gen_random_uuid(), 'comptable', 'password_required'
UNION ALL SELECT gen_random_uuid(), 'admin', 'no_profile';

INSERT INTO auth.users (id,email)
SELECT id, id || '@example.invalid' FROM role_fixtures;
UPDATE public.user_profiles p
SET role = r.role::public.user_role, is_active = r.state <> 'inactive',
    must_change_password = r.state = 'password_required'
FROM role_fixtures r WHERE p.id = r.id;
DELETE FROM public.user_profiles p USING role_fixtures r
WHERE p.id = r.id AND r.state = 'no_profile';
GRANT SELECT ON role_fixtures TO authenticated;

SET LOCAL ROLE authenticated;
DO $$
DECLARE
  t text;
  f text;
  fixture record;
  allowed boolean;
BEGIN
  FOREACH t IN ARRAY ARRAY['cash_registers','bank_accounts','cash_movements','bank_transactions']
  LOOP
    IF NOT has_table_privilege('authenticated','public.' || t,'SELECT')
      OR has_table_privilege('authenticated','public.' || t,'INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
      OR has_table_privilege('anon','public.' || t,'INSERT,UPDATE,DELETE,TRUNCATE,TRIGGER')
    THEN
      RAISE EXCEPTION 'Unexpected ledger grants for %', t;
    END IF;
  END LOOP;
  FOREACH f IN ARRAY ARRAY[
    'receive_invoice_payment(uuid,numeric,text,text,text,uuid,uuid,text)',
    'receive_invoice_payment(uuid,numeric,text,text,text,uuid,uuid)',
    'pay_supplier_bill_from_account(uuid,numeric,text,text,uuid,text,uuid,text)',
    'pay_supplier_bill_from_account(uuid,numeric,text,text,uuid,text,uuid)',
    'pay_expense_from_account(uuid,text,uuid)',
    'open_treasury_account(uuid,text,text,text,text,numeric)'
  ] LOOP
    IF has_function_privilege('anon','public.' || f,'EXECUTE')
       OR NOT has_function_privilege('authenticated','public.' || f,'EXECUTE')
    THEN RAISE EXCEPTION 'Unexpected privilege on %', f; END IF;
  END LOOP;
  FOR fixture IN SELECT * FROM role_fixtures LOOP
    PERFORM set_config('request.jwt.claim.sub',fixture.id::text,true);
    allowed := fixture.state = 'active' AND fixture.role IN ('admin','comptable');
    IF public.can_read_finance() IS DISTINCT FROM allowed THEN
      RAISE EXCEPTION 'Unexpected finance predicate for % %', fixture.role, fixture.state;
    END IF;
    IF NOT allowed THEN
      BEGIN
        PERFORM public.receive_invoice_payment(NULL,1,'CDF','check','cash',NULL,NULL,'cash');
        RAISE EXCEPTION 'Customer payment not rejected';
      EXCEPTION WHEN insufficient_privilege THEN NULL; END;
      BEGIN
        PERFORM public.pay_supplier_bill_from_account(NULL,1,'CDF','check',NULL,'cash',NULL,'cash');
        RAISE EXCEPTION 'Supplier payment not rejected';
      EXCEPTION WHEN insufficient_privilege THEN NULL; END;
      BEGIN
        PERFORM public.receive_invoice_payment(NULL,1,'CDF','check','cash',NULL,NULL);
        RAISE EXCEPTION 'Legacy customer payment not rejected';
      EXCEPTION WHEN insufficient_privilege THEN NULL; END;
      BEGIN
        PERFORM public.pay_supplier_bill_from_account(NULL,1,'CDF','check',NULL,'cash',NULL);
        RAISE EXCEPTION 'Legacy supplier payment not rejected';
      EXCEPTION WHEN insufficient_privilege THEN NULL; END;
      BEGIN
        PERFORM public.pay_expense_from_account(NULL,'cash',NULL);
        RAISE EXCEPTION 'Expense payment not rejected';
      EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    END IF;
    IF fixture.role <> 'admin' OR fixture.state <> 'active' THEN
      BEGIN
        PERFORM public.open_treasury_account(NULL,'cash','check',NULL,'CDF',0);
        RAISE EXCEPTION 'Account opening not rejected';
      EXCEPTION WHEN insufficient_privilege THEN NULL; END;
    END IF;
  END LOOP;
END
$$;
ROLLBACK;
SELECT true AS treasury_write_boundary_pass, 49 AS denied_rpc_calls, 6 AS rpc_grants_verified;
