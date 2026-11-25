BEGIN;

CREATE TABLE IF NOT EXISTS public.operational_treasury_postings (
  source_type text NOT NULL,
  source_id uuid NOT NULL,
  operation_id uuid NOT NULL,
  account_kind text NOT NULL CHECK (account_kind IN ('cash','bank')),
  account_id uuid NOT NULL,
  currency text NOT NULL CHECK (currency IN ('CDF','USD')),
  signed_amount numeric(18,2) NOT NULL CHECK (signed_amount <> 0),
  PRIMARY KEY (source_type, source_id),
  UNIQUE (source_type, operation_id)
);
ALTER TABLE public.operational_treasury_postings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.operational_treasury_postings FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.post_operational_treasury(
  p_type text, p_source_id uuid, p_operation_id uuid, p_kind text, p_account_id uuid,
  p_currency text, p_signed_amount numeric
)
RETURNS void LANGUAGE plpgsql SET search_path = ''
AS $fn$
BEGIN
  IF p_kind IS NULL OR p_kind NOT IN ('cash','bank') OR p_account_id IS NULL
    OR p_currency IS NULL OR p_currency NOT IN ('CDF','USD') THEN
    RAISE EXCEPTION 'Select an active account in the transaction currency' USING ERRCODE='22023';
  END IF;
  INSERT INTO public.operational_treasury_postings
    VALUES (p_type,p_source_id,p_operation_id,p_kind,p_account_id,p_currency,p_signed_amount)
    ON CONFLICT (source_type,source_id) DO NOTHING;
  IF NOT FOUND THEN
    IF NOT EXISTS (
      SELECT FROM public.operational_treasury_postings
      WHERE source_type=p_type AND source_id=p_source_id AND operation_id=p_operation_id
        AND account_kind=p_kind AND account_id=p_account_id AND currency=p_currency
        AND signed_amount=p_signed_amount
    ) THEN
      RAISE EXCEPTION 'Payment already posted to another account' USING ERRCODE='22023';
    END IF;
    RETURN;
  END IF;

  IF p_kind='cash' THEN
    UPDATE public.cash_registers SET current_balance=current_balance+p_signed_amount
      WHERE id=p_account_id AND currency=p_currency AND is_active
        AND current_balance+p_signed_amount >= 0;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Cash register unavailable or insufficient balance' USING ERRCODE='22023';
    END IF;
    INSERT INTO public.cash_movements
      (cash_register_id,movement_type,amount,currency,reason,related_entity_type,related_entity_id,created_by)
      VALUES (p_account_id,CASE WHEN p_signed_amount>0 THEN 'in' ELSE 'out' END,
        abs(p_signed_amount),p_currency,p_type,p_type,p_source_id,auth.uid());
  ELSE
    UPDATE public.bank_accounts SET current_balance=current_balance+p_signed_amount
      WHERE id=p_account_id AND currency=p_currency AND is_active
        AND current_balance+p_signed_amount >= 0;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Bank account unavailable or insufficient balance' USING ERRCODE='22023';
    END IF;
    INSERT INTO public.bank_transactions
      (bank_account_id,transaction_type,amount,currency,reference,description,created_by)
      VALUES (p_account_id,CASE WHEN p_signed_amount>0 THEN 'credit' ELSE 'debit' END,
        abs(p_signed_amount),p_currency,p_source_id::text,p_type,auth.uid());
  END IF;
END;
$fn$;
REVOKE ALL ON FUNCTION public.post_operational_treasury(text,uuid,uuid,text,uuid,text,numeric)
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.receive_invoice_payment(
  p_invoice_id uuid, p_amount numeric, p_currency text, p_reference text,
  p_kind text, p_account_id uuid, p_request_id uuid
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
  SELECT * INTO STRICT invoice FROM public.invoices WHERE id=p_invoice_id FOR UPDATE;
  SELECT pay.* INTO existing FROM public.payments pay JOIN public.operational_treasury_postings t
    ON t.source_id=pay.id AND t.source_type='customer_payment' WHERE t.operation_id=p_request_id;
  IF FOUND THEN
    IF existing.invoice_id IS DISTINCT FROM p_invoice_id OR existing.reference_number IS DISTINCT FROM btrim(p_reference) THEN
      RAISE EXCEPTION 'Conflicting payment request' USING ERRCODE='22023';
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
    CASE WHEN p_kind='cash' THEN 'Espèces' ELSE 'Virement' END,btrim(p_reference),NULL);
  IF result->>'success' IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'Payment rejected: %', result->>'error' USING ERRCODE='22023';
  END IF;
  paid_id := (result->>'payment_id')::uuid;
  PERFORM public.post_operational_treasury('customer_payment',paid_id,p_request_id,
    p_kind,p_account_id,p_currency,p_amount);
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
  p_kind text,p_account_id uuid
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE paid public.supplier_bill_payments%ROWTYPE;
BEGIN
  paid := public.record_supplier_bill_payment(p_bill_id,p_amount,p_currency,p_reference,p_request_id);
  PERFORM public.post_operational_treasury('supplier_payment',paid.id,p_request_id,
    p_kind,p_account_id,p_currency,-p_amount);
  RETURN paid.id;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.pay_expense_from_account(
  p_expense_id uuid,p_kind text,p_account_id uuid
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE expense public.expenses%ROWTYPE;
BEGIN
  IF NOT public.can_read_finance() THEN
    RAISE EXCEPTION 'Expense payment denied' USING ERRCODE='42501';
  END IF;
  SELECT * INTO STRICT expense FROM public.expenses WHERE id=p_expense_id FOR UPDATE;
  IF expense.status IN ('paid','executed') AND EXISTS (
    SELECT FROM public.operational_treasury_postings WHERE source_type='expense' AND source_id=p_expense_id
  ) THEN
    PERFORM public.post_operational_treasury('expense',expense.id,expense.id,
      p_kind,p_account_id,expense.currency,-expense.amount);
    RETURN;
  END IF;
  IF coalesce(expense.status,'') NOT IN ('pending_payment','approved') OR expense.approved_by IS NULL
    OR expense.amount IS NULL OR expense.amount<=0
    OR expense.amount::text IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'Approved unpaid expense required' USING ERRCODE='22023';
  END IF;
  PERFORM public.post_operational_treasury('expense',expense.id,expense.id,
    p_kind,p_account_id,expense.currency,-expense.amount);
  UPDATE public.expenses SET status='paid',paid_by=auth.uid(),paid_at=now(),updated_at=now()
    WHERE id=p_expense_id;
  INSERT INTO public.expense_approval_history(expense_id,action,performed_by)
    VALUES (p_expense_id,'paid',auth.uid());
END;
$fn$;

-- Guard the old direct payment APIs. Owners can still use them inside the wrappers.
REVOKE EXECUTE ON FUNCTION public.record_payment(uuid,numeric,text,text,text,text),
  public.record_supplier_bill_payment(uuid,numeric,text,text,uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.receive_invoice_payment(uuid,numeric,text,text,text,uuid,uuid),
  public.pay_supplier_bill_from_account(uuid,numeric,text,text,uuid,text,uuid),
  public.pay_expense_from_account(uuid,text,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.receive_invoice_payment(uuid,numeric,text,text,text,uuid,uuid),
  public.pay_supplier_bill_from_account(uuid,numeric,text,text,uuid,text,uuid),
  public.pay_expense_from_account(uuid,text,uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.guard_expense_payment()
RETURNS trigger LANGUAGE plpgsql SET search_path = ''
AS $fn$
BEGIN
  IF current_user IN ('anon','authenticated') THEN
    IF TG_OP='INSERT' THEN
      IF NEW.status IS DISTINCT FROM 'pending_approval' OR NEW.paid_by IS NOT NULL OR NEW.paid_at IS NOT NULL
        OR NEW.approved_by IS NOT NULL OR NEW.approved_at IS NOT NULL THEN
        RAISE EXCEPTION 'New expense must be pending approval' USING ERRCODE='42501';
      END IF;
    ELSIF NEW.paid_by IS DISTINCT FROM OLD.paid_by OR NEW.paid_at IS DISTINCT FROM OLD.paid_at
      OR (NEW.status='paid' AND OLD.status IS DISTINCT FROM 'paid')
      OR (NEW.status='executed' AND OLD.status NOT IN ('paid','executed'))
      OR (OLD.status IN ('paid','executed') AND
        (NEW.status NOT IN ('paid','executed') OR NEW.amount IS DISTINCT FROM OLD.amount OR NEW.currency IS DISTINCT FROM OLD.currency))
    THEN
      RAISE EXCEPTION 'Expense payment must use the treasury workflow' USING ERRCODE='42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$fn$;
DROP TRIGGER IF EXISTS guard_expense_payment ON public.expenses;
CREATE TRIGGER guard_expense_payment BEFORE INSERT OR UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.guard_expense_payment();

REVOKE INSERT, UPDATE, DELETE ON public.cash_movements, public.bank_transactions
  FROM PUBLIC, anon, authenticated;
REVOKE UPDATE, DELETE ON public.cash_registers, public.bank_accounts
  FROM PUBLIC, anon, authenticated;
REVOKE DELETE ON public.expenses FROM PUBLIC, anon, authenticated;

COMMIT;
