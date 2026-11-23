-- P1.a — avoir traçable sur les frais de livraison, sur décision de l'admin.
BEGIN;
ALTER TABLE public.invoices
    ADD COLUMN IF NOT EXISTS delivery_fee_credited numeric(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS item_amount_credited numeric(12,2) NOT NULL DEFAULT 0;
DO $constraint$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.invoices'::regclass
        AND conname = 'invoices_delivery_fee_credit_ceiling') THEN
        ALTER TABLE public.invoices ADD CONSTRAINT invoices_delivery_fee_credit_ceiling
            CHECK (delivery_fee_credited BETWEEN 0 AND delivery_fee);
    END IF;
END;
$constraint$;
CREATE TABLE IF NOT EXISTS public.invoice_delivery_fee_credits (
    id uuid PRIMARY KEY,
    invoice_id uuid NOT NULL REFERENCES public.invoices(id),
    amount numeric(12,2) NOT NULL CHECK (amount > 0 AND amount <> 'NaN'::numeric),
    reason text NOT NULL CHECK (length(btrim(reason)) BETWEEN 1 AND 1000),
    approved_by uuid NOT NULL REFERENCES public.user_profiles(id),
    created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.invoice_delivery_fee_credits ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.invoice_delivery_fee_credits FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.invoice_delivery_fee_credits TO authenticated;
DROP POLICY IF EXISTS invoice_delivery_fee_credit_read ON public.invoice_delivery_fee_credits;
CREATE POLICY invoice_delivery_fee_credit_read ON public.invoice_delivery_fee_credits
FOR SELECT TO authenticated USING (public.is_admin() OR public.is_comptable());

CREATE OR REPLACE FUNCTION public.record_delivery_fee_credit(
    p_invoice_id uuid, p_amount numeric, p_reason text, p_request_id uuid
)
RETURNS public.invoice_delivery_fee_credits
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $credit$
DECLARE
    invoice_row public.invoices%ROWTYPE;
    credit_row public.invoice_delivery_fee_credits%ROWTYPE;
    credited numeric;
    status public.payment_status;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Only administrators can authorize a delivery fee credit' USING ERRCODE = '42501';
    END IF;
    IF p_amount IS NULL OR p_amount::text IN ('NaN','Infinity','-Infinity')
        OR p_amount <= 0 OR p_amount <> round(p_amount,2) OR p_request_id IS NULL
        OR coalesce(length(btrim(p_reason)),0) NOT BETWEEN 1 AND 1000 THEN
        RAISE EXCEPTION 'Invalid delivery fee credit or reason' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO invoice_row FROM public.invoices WHERE id = p_invoice_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invoice not found' USING ERRCODE = 'P0002';
    END IF;
    SELECT * INTO credit_row FROM public.invoice_delivery_fee_credits WHERE id = p_request_id;
    IF FOUND THEN
        IF credit_row.invoice_id IS DISTINCT FROM p_invoice_id
            OR credit_row.amount IS DISTINCT FROM p_amount
            OR credit_row.reason IS DISTINCT FROM btrim(p_reason)
            OR credit_row.approved_by IS DISTINCT FROM auth.uid() THEN
            RAISE EXCEPTION 'Credit request already used with different details' USING ERRCODE = '22023';
        END IF;
        RETURN credit_row;
    END IF;
    credited := invoice_row.delivery_fee_credited + p_amount;
    IF NOT invoice_row.home_delivery OR credited > invoice_row.delivery_fee THEN
        RAISE EXCEPTION 'Credit exceeds the invoiced delivery fee' USING ERRCODE = '22023';
    END IF;
    status := CASE WHEN coalesce(invoice_row.amount_paid,0) + credited + invoice_row.item_amount_credited >= invoice_row.total_amount
        THEN 'paid'::public.payment_status
        WHEN coalesce(invoice_row.amount_paid,0) > 0 THEN 'partial'::public.payment_status
        ELSE 'pending'::public.payment_status END;
    INSERT INTO public.invoice_delivery_fee_credits(id,invoice_id,amount,reason,approved_by)
    VALUES (p_request_id,p_invoice_id,p_amount,btrim(p_reason),auth.uid())
    RETURNING * INTO credit_row;
    UPDATE public.invoices SET delivery_fee_credited = credited, payment_status = status
    WHERE id = p_invoice_id;
    UPDATE public.sales_orders SET payment_status = status WHERE id = invoice_row.order_id;
    INSERT INTO public.audit_logs(table_name,record_id,action_type,new_values,user_id)
    VALUES ('invoice_delivery_fee_credits',credit_row.id,'insert',
        to_jsonb(credit_row) || jsonb_build_object('operation','admin_decision'),auth.uid());
    RETURN credit_row;
END;
$credit$;
REVOKE ALL ON FUNCTION public.record_delivery_fee_credit(uuid,numeric,text,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_delivery_fee_credit(uuid,numeric,text,uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.record_payment(
    p_invoice_id uuid, p_amount numeric, p_currency text DEFAULT 'CDF',
    p_payment_method text DEFAULT NULL, p_reference_number text DEFAULT NULL, p_notes text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $payment$
DECLARE
    invoice_row public.invoices%ROWTYPE;
    payment_id uuid;
    existing_payment public.payments%ROWTYPE;
    paid numeric;
    balance_due numeric;
    status public.payment_status;
BEGIN
    IF NOT (public.is_admin() OR public.is_comptable()) THEN
        RAISE EXCEPTION 'Payment denied' USING ERRCODE = '42501';
    END IF;
    IF p_amount IS NULL OR p_amount::text IN ('NaN','Infinity','-Infinity')
        OR p_amount <= 0 OR p_amount <> round(p_amount,2) THEN
        RAISE EXCEPTION 'Invalid payment amount' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO invoice_row FROM public.invoices WHERE id = p_invoice_id FOR UPDATE;
    IF NOT FOUND OR p_currency IS NULL OR p_currency IS DISTINCT FROM invoice_row.currency THEN
        RAISE EXCEPTION 'Invoice or payment currency unavailable' USING ERRCODE = '22023';
    END IF;
    IF nullif(btrim(p_reference_number),'') IS NOT NULL THEN
        SELECT * INTO existing_payment FROM public.payments
        WHERE invoice_id = p_invoice_id AND reference_number = btrim(p_reference_number)
        ORDER BY created_at,id LIMIT 1;
        IF FOUND THEN
            IF existing_payment.amount IS DISTINCT FROM p_amount
                OR existing_payment.currency IS DISTINCT FROM p_currency
                OR existing_payment.payment_method IS DISTINCT FROM p_payment_method THEN
                RAISE EXCEPTION 'Payment reference already used with different details' USING ERRCODE = '22023';
            END IF;
            RETURN jsonb_build_object('success',true,'payment_id',existing_payment.id);
        END IF;
    END IF;
    paid := coalesce(invoice_row.amount_paid,0) + p_amount;
    balance_due := invoice_row.total_amount - invoice_row.delivery_fee_credited - invoice_row.item_amount_credited;
    IF paid > balance_due THEN
        RAISE EXCEPTION 'Payment exceeds the net invoice balance' USING ERRCODE = '22023';
    END IF;
    status := CASE WHEN paid = balance_due THEN 'paid'::public.payment_status ELSE 'partial'::public.payment_status END;
    INSERT INTO public.payments(invoice_id,amount,payment_method,reference_number,notes,currency)
    VALUES (p_invoice_id,p_amount,p_payment_method,nullif(btrim(p_reference_number),''),p_notes,p_currency)
    RETURNING id INTO payment_id;
    UPDATE public.invoices SET amount_paid = paid, payment_status = status WHERE id = p_invoice_id;
    UPDATE public.sales_orders SET payment_status = status WHERE id = invoice_row.order_id;
    INSERT INTO public.audit_logs(table_name,record_id,action_type,new_values,user_id)
    VALUES ('payments',payment_id,'insert',jsonb_build_object('rpc','record_payment','amount',p_amount),auth.uid());
    RETURN jsonb_build_object('success',true,'payment_id',payment_id);
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success',false,'error',SQLERRM);
END;
$payment$;

CREATE OR REPLACE VIEW public.invoice_open_balances WITH (security_invoker = true) AS
SELECT id AS invoice_id, customer_id, order_id, due_date, currency, total_amount,
    coalesce(amount_paid,0) AS amount_paid,
    total_amount - coalesce(amount_paid,0) - delivery_fee_credited - item_amount_credited AS outstanding_amount
FROM public.invoices
WHERE total_amount > coalesce(amount_paid,0) + delivery_fee_credited + item_amount_credited;

CREATE OR REPLACE VIEW public.invoice_delivery_refunds_due WITH (security_invoker = true) AS
SELECT id AS invoice_id, currency,
    least(delivery_fee_credited, coalesce(amount_paid,0) + delivery_fee_credited + item_amount_credited - total_amount) AS refund_due
FROM public.invoices
WHERE delivery_fee_credited > 0 AND coalesce(amount_paid,0) + delivery_fee_credited + item_amount_credited > total_amount;
REVOKE ALL ON public.invoice_delivery_refunds_due FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.invoice_delivery_refunds_due TO authenticated;
COMMIT;
