BEGIN;

-- A wallet uses the existing non-cash ledger, with its own account category.
ALTER TABLE public.bank_accounts ADD COLUMN IF NOT EXISTS account_channel text
  NOT NULL DEFAULT 'bank_transfer' CHECK (account_channel IN ('bank_transfer','mobile_money'));
ALTER TABLE public.operational_treasury_postings ADD COLUMN IF NOT EXISTS payment_method text
  CHECK (payment_method IN ('cash','mobile_money','bank_transfer'));
ALTER TABLE public.supplier_bill_payments ADD COLUMN IF NOT EXISTS payment_method text
  CHECK (payment_method IN ('cash','mobile_money','bank_transfer'));

CREATE OR REPLACE FUNCTION public.validate_payment_account(p_method text,p_kind text,p_account_id uuid)
RETURNS void LANGUAGE plpgsql SET search_path = ''
AS $fn$
BEGIN
  IF p_method IS NULL OR p_method NOT IN ('cash','mobile_money','bank_transfer') OR p_account_id IS NULL
    OR (p_method='cash' AND p_kind IS DISTINCT FROM 'cash')
    OR (p_method<>'cash' AND (p_kind IS DISTINCT FROM 'bank' OR NOT EXISTS (
      SELECT FROM public.bank_accounts
      WHERE id=p_account_id AND is_active AND account_channel=p_method
    ))) THEN
    RAISE EXCEPTION 'Select an account matching the payment method' USING ERRCODE='22023';
  END IF;
END;
$fn$;
REVOKE ALL ON FUNCTION public.validate_payment_account(text,text,uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.receive_invoice_payment(
  p_invoice_id uuid, p_amount numeric, p_currency text, p_reference text,
  p_kind text, p_account_id uuid, p_request_id uuid, p_method text
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE
  invoice public.invoices%ROWTYPE;
  result jsonb;
  paid_id uuid;
  existing public.payments%ROWTYPE;
BEGIN
  IF NOT public.can_read_finance() THEN
    RAISE EXCEPTION 'Payment denied' USING ERRCODE='42501';
  END IF;
  IF p_request_id IS NULL OR p_amount IS NULL OR p_amount::text IN ('NaN','Infinity','-Infinity')
    OR p_amount<=0 OR p_amount<>round(p_amount,2)
    OR coalesce(length(btrim(p_reference)),0) NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'Invalid payment' USING ERRCODE='22023';
  END IF;
  PERFORM public.validate_payment_account(p_method,p_kind,p_account_id);
  SELECT * INTO STRICT invoice FROM public.invoices WHERE id=p_invoice_id FOR UPDATE;
  SELECT pay.* INTO existing FROM public.payments pay JOIN public.operational_treasury_postings t
    ON t.source_id=pay.id AND t.source_type='customer_payment' WHERE t.operation_id=p_request_id;
  IF FOUND THEN
    IF existing.invoice_id IS DISTINCT FROM p_invoice_id OR existing.reference_number IS DISTINCT FROM btrim(p_reference) THEN
      RAISE EXCEPTION 'Conflicting payment request' USING ERRCODE='22023';
    END IF;
    IF NOT EXISTS (
      SELECT FROM public.operational_treasury_postings
      WHERE source_type='customer_payment' AND source_id=existing.id
        AND coalesce(payment_method,CASE WHEN account_kind='cash' THEN 'cash' ELSE 'bank_transfer' END)=p_method
    ) THEN
      RAISE EXCEPTION 'Conflicting payment method' USING ERRCODE='22023';
    END IF;
    PERFORM public.post_operational_treasury('customer_payment',existing.id,p_request_id,
      p_kind,p_account_id,p_currency,p_amount);
    RETURN existing.id;
  END IF;
  IF p_currency IS DISTINCT FROM invoice.currency OR p_amount >
      invoice.total_amount-coalesce(invoice.amount_paid,0)-invoice.item_amount_credited-invoice.delivery_fee_credited THEN
    RAISE EXCEPTION 'Amount exceeds net invoice balance or currency differs' USING ERRCODE='22023';
  END IF;
  result := public.record_payment(p_invoice_id,p_amount,p_currency,
    CASE p_method WHEN 'cash' THEN 'Espèces' WHEN 'mobile_money' THEN 'Mobile Money' ELSE 'Virement bancaire' END,btrim(p_reference),NULL);
  IF result->>'success' IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'Payment rejected: %', result->>'error' USING ERRCODE='22023';
  END IF;
  paid_id := (result->>'payment_id')::uuid;
  PERFORM public.post_operational_treasury('customer_payment',paid_id,p_request_id,
    p_kind,p_account_id,p_currency,p_amount);
  UPDATE public.operational_treasury_postings SET payment_method=p_method
    WHERE source_type='customer_payment' AND source_id=paid_id;
  IF coalesce(invoice.amount_paid,0)+p_amount+invoice.item_amount_credited+invoice.delivery_fee_credited = invoice.total_amount THEN
    UPDATE public.invoices SET payment_status='paid' WHERE id=p_invoice_id;
    UPDATE public.sales_orders SET payment_status='paid' WHERE id=invoice.order_id;
  ELSE
    UPDATE public.invoices SET payment_status='partial' WHERE id=p_invoice_id;
    UPDATE public.sales_orders SET payment_status='partial' WHERE id=invoice.order_id;
  END IF;
  RETURN paid_id;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.pay_supplier_bill_from_account(
  p_bill_id uuid,p_amount numeric,p_currency text,p_reference text,p_request_id uuid,
  p_kind text,p_account_id uuid,p_method text
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE paid public.supplier_bill_payments%ROWTYPE;
BEGIN
  IF NOT public.can_read_finance() THEN
    RAISE EXCEPTION 'Supplier payment denied' USING ERRCODE='42501';
  END IF;
  PERFORM public.validate_payment_account(p_method,p_kind,p_account_id);
  paid := public.record_supplier_bill_payment(p_bill_id,p_amount,p_currency,p_reference,p_request_id);
  IF EXISTS (
    SELECT FROM public.operational_treasury_postings
    WHERE source_type='supplier_payment' AND source_id=paid.id
      AND coalesce(payment_method,CASE WHEN account_kind='cash' THEN 'cash' ELSE 'bank_transfer' END)<>p_method
  ) THEN
    RAISE EXCEPTION 'Conflicting payment method' USING ERRCODE='22023';
  END IF;
  PERFORM public.post_operational_treasury('supplier_payment',paid.id,p_request_id,
    p_kind,p_account_id,p_currency,-p_amount);
  UPDATE public.operational_treasury_postings SET payment_method=p_method
    WHERE source_type='supplier_payment' AND source_id=paid.id;
  UPDATE public.supplier_bill_payments SET payment_method=p_method WHERE id=paid.id;
  RETURN paid.id;
END;
$fn$;

-- Preserve the previous client contract and infer only its original two channels.
CREATE OR REPLACE FUNCTION public.receive_invoice_payment(
  p_invoice_id uuid, p_amount numeric, p_currency text, p_reference text,
  p_kind text, p_account_id uuid, p_request_id uuid
)
RETURNS uuid LANGUAGE sql SECURITY DEFINER SET search_path = ''
AS $fn$
  SELECT public.receive_invoice_payment(p_invoice_id,p_amount,p_currency,p_reference,
    p_kind,p_account_id,p_request_id,CASE WHEN p_kind='cash' THEN 'cash' ELSE 'bank_transfer' END);
$fn$;

CREATE OR REPLACE FUNCTION public.pay_supplier_bill_from_account(
  p_bill_id uuid,p_amount numeric,p_currency text,p_reference text,p_request_id uuid,
  p_kind text,p_account_id uuid
)
RETURNS uuid LANGUAGE sql SECURITY DEFINER SET search_path = ''
AS $fn$
  SELECT public.pay_supplier_bill_from_account(p_bill_id,p_amount,p_currency,p_reference,p_request_id,
    p_kind,p_account_id,CASE WHEN p_kind='cash' THEN 'cash' ELSE 'bank_transfer' END);
$fn$;

REVOKE ALL ON FUNCTION public.receive_invoice_payment(uuid,numeric,text,text,text,uuid,uuid,text),
  public.pay_supplier_bill_from_account(uuid,numeric,text,text,uuid,text,uuid,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.receive_invoice_payment(uuid,numeric,text,text,text,uuid,uuid,text),
  public.pay_supplier_bill_from_account(uuid,numeric,text,text,uuid,text,uuid,text) TO authenticated;

COMMIT;
