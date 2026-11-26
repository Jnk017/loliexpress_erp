BEGIN;

CREATE OR REPLACE FUNCTION public.open_treasury_account(
  p_request_id uuid, p_method text, p_name text, p_provider text,
  p_currency text, p_opening numeric
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE
  kind text;
  details jsonb;
  previous jsonb;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Treasury account creation requires an active administrator' USING ERRCODE='42501';
  END IF;
  IF p_request_id IS NULL OR p_method IS NULL
    OR p_method NOT IN ('cash','mobile_money','bank_transfer')
    OR coalesce(length(btrim(p_name)),0) NOT BETWEEN 1 AND 100
    OR (p_method<>'cash' AND coalesce(length(btrim(p_provider)),0) NOT BETWEEN 1 AND 100)
    OR p_currency IS NULL OR p_currency NOT IN ('CDF','USD')
    OR p_opening IS NULL OR p_opening::text IN ('NaN','Infinity','-Infinity')
    OR p_opening<0 OR p_opening<>round(p_opening,2) OR p_opening>=10000000000000000 THEN
    RAISE EXCEPTION 'Invalid treasury account or opening balance' USING ERRCODE='22023';
  END IF;

  kind := CASE WHEN p_method='cash' THEN 'cash' ELSE 'bank' END;
  details := jsonb_build_object('event','treasury_account_opened','method',p_method,
    'name',btrim(p_name),'provider',CASE WHEN kind='bank' THEN btrim(p_provider) END,
    'currency',p_currency,'opening_balance',p_opening,'actor',auth.uid());
  PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::text, 22));
  SELECT new_values INTO previous FROM public.audit_logs
    WHERE record_id=p_request_id AND new_values->>'event'='treasury_account_opened';
  IF FOUND THEN
    IF previous IS DISTINCT FROM details THEN
      RAISE EXCEPTION 'Account request already used with different data' USING ERRCODE='22023';
    END IF;
    RETURN p_request_id;
  END IF;

  IF kind='cash' THEN
    INSERT INTO public.cash_registers(id,name,currency,opening_balance,current_balance)
      VALUES (p_request_id,btrim(p_name),p_currency,p_opening,0);
  ELSE
    INSERT INTO public.bank_accounts(id,account_name,bank_name,currency,current_balance,account_channel)
      VALUES (p_request_id,btrim(p_name),btrim(p_provider),p_currency,0,p_method);
  END IF;
  IF p_opening>0 THEN
    PERFORM public.post_operational_treasury('opening_balance',p_request_id,p_request_id,
      kind,p_request_id,p_currency,p_opening);
  END IF;
  INSERT INTO public.audit_logs(table_name,record_id,action_type,new_values,user_id)
    VALUES (CASE WHEN kind='cash' THEN 'cash_registers' ELSE 'bank_accounts' END,
      p_request_id,'insert',details,auth.uid());
  RETURN p_request_id;
END;
$fn$;

REVOKE ALL ON FUNCTION public.open_treasury_account(uuid,text,text,text,text,numeric)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.open_treasury_account(uuid,text,text,text,text,numeric)
  TO authenticated;
REVOKE INSERT ON public.cash_registers, public.bank_accounts
  FROM PUBLIC, anon, authenticated;

COMMIT;
