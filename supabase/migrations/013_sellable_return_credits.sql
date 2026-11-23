-- P1.a — les avoirs d'articles couvrent uniquement les unités revendables contrôlées.
BEGIN;
DO $constraint$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.invoices'::regclass
        AND conname = 'invoices_item_credit_ceiling') THEN
        ALTER TABLE public.invoices ADD CONSTRAINT invoices_item_credit_ceiling
            CHECK (item_amount_credited BETWEEN 0 AND subtotal - discount_amount);
    END IF;
END;
$constraint$;
CREATE TABLE IF NOT EXISTS public.invoice_item_credits (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id uuid NOT NULL REFERENCES public.invoices(id),
    inspection_id uuid NOT NULL UNIQUE REFERENCES public.customer_return_inspections(id),
    quantity integer NOT NULL CHECK (quantity > 0),
    amount numeric(12,2) NOT NULL CHECK (amount > 0 AND amount <> 'NaN'::numeric),
    approved_by uuid NOT NULL REFERENCES public.user_profiles(id),
    created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.invoice_item_credits ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.invoice_item_credits FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.invoice_item_credits TO authenticated;
DROP POLICY IF EXISTS read_invoice_item_credits ON public.invoice_item_credits;
CREATE POLICY read_invoice_item_credits ON public.invoice_item_credits FOR SELECT TO authenticated
USING (public.is_admin() OR public.is_comptable());

CREATE OR REPLACE FUNCTION public.record_return_item_credit(p_inspection_id uuid)
RETURNS public.invoice_item_credits LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $credit$
DECLARE
    inspection public.customer_return_inspections%ROWTYPE;
    item_row public.order_items%ROWTYPE;
    invoice_row public.invoices%ROWTYPE;
    credit_row public.invoice_item_credits%ROWTYPE;
    previous_line_total numeric;
    line_net numeric;
    previous_quantity bigint;
    credit_amount numeric;
    item_credit_total numeric;
    payment_state public.payment_status;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Item credit approval denied' USING ERRCODE = '42501';
    END IF;
    SELECT * INTO inspection FROM public.customer_return_inspections WHERE id = p_inspection_id;
    IF NOT FOUND OR inspection.sellable_quantity = 0 THEN
        RAISE EXCEPTION 'Only inspected sellable items can be credited' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO STRICT item_row FROM public.order_items WHERE id = inspection.order_item_id;
    SELECT * INTO invoice_row FROM public.invoices WHERE order_id = item_row.order_id FOR UPDATE;
    IF NOT FOUND OR invoice_row.subtotal <= 0 THEN
        RAISE EXCEPTION 'Issued order invoice required' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO credit_row FROM public.invoice_item_credits WHERE inspection_id = p_inspection_id;
    IF FOUND THEN RETURN credit_row; END IF;
    SELECT coalesce(sum(i.line_total),0) INTO previous_line_total
    FROM public.order_items i WHERE i.order_id = item_row.order_id AND i.id < item_row.id;
    -- Distribue l'arrondi de remise entre lignes, puis entre unités au fil des avoirs.
    line_net := item_row.line_total
        - round(invoice_row.discount_amount * (previous_line_total + item_row.line_total) / invoice_row.subtotal,2)
        + round(invoice_row.discount_amount * previous_line_total / invoice_row.subtotal,2);
    SELECT coalesce(sum(c.quantity),0) INTO previous_quantity
    FROM public.invoice_item_credits c
    JOIN public.customer_return_inspections ri ON ri.id = c.inspection_id
    WHERE c.invoice_id = invoice_row.id AND ri.order_item_id = item_row.id;
    IF previous_quantity + inspection.sellable_quantity > item_row.quantity THEN
        RAISE EXCEPTION 'Credit quantity exceeds the invoice line' USING ERRCODE = '22023';
    END IF;
    credit_amount := round(line_net * (previous_quantity + inspection.sellable_quantity) / item_row.quantity,2)
        - round(line_net * previous_quantity / item_row.quantity,2);
    item_credit_total := invoice_row.item_amount_credited + credit_amount;
    IF credit_amount <= 0 OR item_credit_total > invoice_row.subtotal - invoice_row.discount_amount THEN
        RAISE EXCEPTION 'No creditable amount on the invoice' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.invoice_item_credits(invoice_id,inspection_id,quantity,amount,approved_by)
    VALUES (invoice_row.id,p_inspection_id,inspection.sellable_quantity,credit_amount,auth.uid())
    RETURNING * INTO credit_row;
    payment_state := CASE WHEN coalesce(invoice_row.amount_paid,0) + invoice_row.delivery_fee_credited + item_credit_total
            >= invoice_row.total_amount THEN 'paid'::public.payment_status
        WHEN coalesce(invoice_row.amount_paid,0) > 0 THEN 'partial'::public.payment_status
        ELSE 'pending'::public.payment_status END;
    UPDATE public.invoices SET item_amount_credited = item_credit_total, payment_status = payment_state
    WHERE id = invoice_row.id;
    UPDATE public.sales_orders SET payment_status = payment_state WHERE id = item_row.order_id;
    INSERT INTO public.audit_logs(table_name,record_id,action_type,new_values,user_id)
    VALUES ('invoice_item_credits',credit_row.id,'insert',to_jsonb(credit_row),auth.uid());
    RETURN credit_row;
END;
$credit$;
REVOKE ALL ON FUNCTION public.record_return_item_credit(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_return_item_credit(uuid) TO authenticated;

CREATE OR REPLACE VIEW public.invoice_refunds_due WITH (security_invoker = true) AS
SELECT id AS invoice_id,currency,
    coalesce(amount_paid,0) + delivery_fee_credited + item_amount_credited - total_amount AS refund_due
FROM public.invoices
WHERE coalesce(amount_paid,0) + delivery_fee_credited + item_amount_credited > total_amount;
REVOKE ALL ON public.invoice_refunds_due FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.invoice_refunds_due TO authenticated;
COMMIT;
