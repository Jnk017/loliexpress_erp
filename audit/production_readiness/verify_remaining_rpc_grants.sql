BEGIN;
SELECT set_config('request.jwt.claim.sub',id::text,true) FROM public.user_profiles
 WHERE role='b2b_customer' AND is_active AND NOT must_change_password LIMIT 1;
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  signature text;
  statement text;
BEGIN
  IF NOT public.is_b2b_customer() THEN RAISE EXCEPTION 'B2B Gate account missing'; END IF;
  FOREACH signature IN ARRAY ARRAY[
    'cancel_unreceived_purchase(uuid)','complete_password_setup()',
    'create_purchase_with_items(uuid,jsonb,text,numeric,text)',
    'get_customer_return_lines(text)','inspect_customer_return(uuid,integer,integer,text,uuid)',
    'receive_purchase_item(uuid,uuid,integer,uuid)','record_delivery_fee_credit(uuid,numeric,text,uuid)',
    'record_return_item_credit(uuid)','register_supplier_bill(uuid,text,date,numeric)',
    'save_invoice_draft(uuid,uuid,text,jsonb)'
  ] LOOP
    IF has_function_privilege('anon','public.' || signature,'EXECUTE')
      OR NOT has_function_privilege('authenticated','public.' || signature,'EXECUTE') THEN
      RAISE EXCEPTION 'Unexpected grants for %',signature;
    END IF;
  END LOOP;
  FOREACH statement IN ARRAY ARRAY[
    'cancel_unreceived_purchase(NULL)',
    'create_purchase_with_items(NULL,NULL,NULL,NULL,NULL)',
    'get_customer_return_lines(NULL)','inspect_customer_return(NULL,NULL,NULL,NULL,NULL)',
    'receive_purchase_item(NULL,NULL,NULL,NULL)','record_delivery_fee_credit(NULL,NULL,NULL,NULL)',
    'record_return_item_credit(NULL)','register_supplier_bill(NULL,NULL,NULL,NULL)',
    'save_invoice_draft(NULL,NULL,NULL,NULL)'
  ] LOOP
    BEGIN
      EXECUTE 'SELECT public.' || statement;
      RAISE EXCEPTION 'Unexpected access for B2B: %',statement;
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
  END LOOP;
  PERFORM set_config('request.jwt.claim.sub','',true);
  BEGIN
    PERFORM public.complete_password_setup();
    RAISE EXCEPTION 'Password setup accepted without identity';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$$;
SELECT true AS remaining_rpc_grants_pass,10 AS refusal_count;
ROLLBACK;
