-- P1.a — facturation TTC à 0 %, frais de livraison à domicile facultatifs.
BEGIN;
ALTER TABLE public.invoices
    ADD COLUMN IF NOT EXISTS home_delivery boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS delivery_fee numeric(12,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS discount_amount numeric(12,2) NOT NULL DEFAULT 0;
DO $constraint$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
        WHERE conrelid = 'public.invoices'::regclass AND conname = 'invoices_home_delivery_fee_valid') THEN
        ALTER TABLE public.invoices ADD CONSTRAINT invoices_home_delivery_fee_valid
            CHECK (delivery_fee >= 0 AND delivery_fee <> 'NaN'::numeric
                AND (home_delivery OR delivery_fee = 0));
    END IF;
END;
$constraint$;
CREATE UNIQUE INDEX IF NOT EXISTS invoices_single_issue_per_order
    ON public.invoices(order_id) WHERE order_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.issue_order_invoice(
    p_order_id uuid, p_due_date timestamptz, p_home_delivery boolean DEFAULT false,
    p_delivery_fee numeric DEFAULT 0
)
RETURNS public.invoices
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $invoice$
DECLARE
    order_row public.sales_orders%ROWTYPE;
    invoice_row public.invoices%ROWTYPE;
    fee numeric(12,2);
BEGIN
    IF coalesce(public.current_user_role(), '') NOT IN ('admin','comptable') THEN
        RAISE EXCEPTION 'Invoice issuance denied' USING ERRCODE = '42501';
    END IF;
    IF p_due_date IS NULL OR p_home_delivery IS NULL OR p_delivery_fee IS NULL
        OR p_delivery_fee < 0 OR p_delivery_fee::text IN ('NaN','Infinity','-Infinity')
        OR (NOT p_home_delivery AND p_delivery_fee <> 0) THEN
        RAISE EXCEPTION 'Invalid invoice due date or delivery fee' USING ERRCODE = '22023';
    END IF;
    fee := round(p_delivery_fee,2);
    SELECT * INTO order_row FROM public.sales_orders WHERE id = p_order_id FOR UPDATE;
    IF NOT FOUND OR order_row.customer_id IS NULL OR order_row.order_status IS NULL
        OR order_row.order_status IN ('pending','cancelled') THEN
        RAISE EXCEPTION 'A confirmed order is required' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO invoice_row FROM public.invoices WHERE order_id = p_order_id;
    IF FOUND THEN
        IF invoice_row.home_delivery IS DISTINCT FROM p_home_delivery
            OR invoice_row.delivery_fee IS DISTINCT FROM fee
            OR invoice_row.due_date IS DISTINCT FROM p_due_date THEN
            RAISE EXCEPTION 'The order has already been invoiced with other terms' USING ERRCODE = '22023';
        END IF;
        RETURN invoice_row;
    END IF;
    IF order_row.currency IS NULL OR order_row.currency NOT IN ('CDF','USD')
        OR order_row.subtotal < coalesce(order_row.discount_amount,0) THEN
        RAISE EXCEPTION 'Invalid order amount or currency' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.invoices(order_id, customer_id, invoice_date, due_date,
        subtotal, tax_amount, discount_amount, home_delivery, delivery_fee,
        total_amount, amount_paid, payment_status, notes, currency, exchange_rate)
    VALUES (order_row.id, order_row.customer_id, now(), p_due_date,
        order_row.subtotal, 0, coalesce(order_row.discount_amount,0), p_home_delivery, fee,
        order_row.subtotal - coalesce(order_row.discount_amount,0) + fee,
        0, 'pending', order_row.notes, order_row.currency, order_row.exchange_rate)
    RETURNING * INTO invoice_row;
    RETURN invoice_row;
END;
$invoice$;
REVOKE ALL ON FUNCTION public.issue_order_invoice(uuid,timestamptz,boolean,numeric) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.issue_order_invoice(uuid,timestamptz,boolean,numeric) TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.invoices, public.payments FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.record_payment(uuid,numeric,text,text,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_payment(uuid,numeric,text,text,text,text) TO authenticated;

ALTER VIEW public.receivables_aging SET (security_invoker = true);
REVOKE ALL ON public.receivables_aging FROM PUBLIC, anon;
CREATE OR REPLACE VIEW public.invoice_open_balances WITH (security_invoker = true) AS
SELECT id AS invoice_id, customer_id, order_id, due_date, currency, total_amount,
    coalesce(amount_paid,0) AS amount_paid,
    total_amount - coalesce(amount_paid,0) AS outstanding_amount
FROM public.invoices
WHERE total_amount > coalesce(amount_paid,0);
REVOKE ALL ON public.invoice_open_balances FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.invoice_open_balances TO authenticated;
COMMIT;
