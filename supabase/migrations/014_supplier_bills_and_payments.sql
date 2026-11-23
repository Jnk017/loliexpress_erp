-- P1.a — matérialiser séparément la dette fournisseur et son règlement.
BEGIN;
CREATE TABLE IF NOT EXISTS public.supplier_bills (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id uuid NOT NULL REFERENCES public.purchases(id),
    supplier_id uuid NOT NULL REFERENCES public.suppliers(id),
    bill_number text NOT NULL CHECK (btrim(bill_number) <> ''),
    due_date date NOT NULL,
    currency text NOT NULL CHECK (currency IN ('CDF','USD')),
    amount numeric(12,2) NOT NULL CHECK (amount > 0 AND amount <> 'NaN'::numeric),
    amount_paid numeric(12,2) NOT NULL DEFAULT 0 CHECK (amount_paid BETWEEN 0 AND amount),
    entered_by uuid NOT NULL REFERENCES public.user_profiles(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(supplier_id,bill_number)
);
CREATE TABLE IF NOT EXISTS public.supplier_bill_payments (
    id uuid PRIMARY KEY,
    bill_id uuid NOT NULL REFERENCES public.supplier_bills(id),
    amount numeric(12,2) NOT NULL CHECK (amount > 0 AND amount <> 'NaN'::numeric),
    currency text NOT NULL CHECK (currency IN ('CDF','USD')),
    reference text NOT NULL CHECK (btrim(reference) <> ''),
    entered_by uuid NOT NULL REFERENCES public.user_profiles(id),
    created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.supplier_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_bill_payments ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.supplier_bills, public.supplier_bill_payments FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.supplier_bills, public.supplier_bill_payments TO authenticated;
DROP POLICY IF EXISTS read_supplier_bills ON public.supplier_bills;
CREATE POLICY read_supplier_bills ON public.supplier_bills FOR SELECT TO authenticated
USING (public.can_read_procurement());
DROP POLICY IF EXISTS read_supplier_bill_payments ON public.supplier_bill_payments;
CREATE POLICY read_supplier_bill_payments ON public.supplier_bill_payments FOR SELECT TO authenticated
USING (public.can_read_finance());

CREATE OR REPLACE FUNCTION public.register_supplier_bill(
    p_purchase_id uuid,p_bill_number text,p_due_date date,p_amount numeric
)
RETURNS public.supplier_bills LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $bill$
DECLARE
    purchase_row public.purchases%ROWTYPE;
    bill_row public.supplier_bills%ROWTYPE;
    billed numeric;
BEGIN
    IF coalesce(public.current_user_role(),'') NOT IN ('admin','comptable','acheteur') THEN
        RAISE EXCEPTION 'Supplier bill denied' USING ERRCODE = '42501';
    END IF;
    IF p_amount IS NULL OR p_amount::text IN ('NaN','Infinity','-Infinity') OR p_amount <= 0
        OR round(p_amount,2) <> p_amount OR p_due_date IS NULL
        OR coalesce(length(btrim(p_bill_number)),0) NOT BETWEEN 1 AND 100 THEN
        RAISE EXCEPTION 'Invalid supplier bill' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO purchase_row FROM public.purchases WHERE id = p_purchase_id FOR UPDATE;
    IF NOT FOUND OR purchase_row.status = 'cancelled' OR purchase_row.supplier_id IS NULL THEN
        RAISE EXCEPTION 'Valid purchase required' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO bill_row FROM public.supplier_bills
    WHERE supplier_id = purchase_row.supplier_id AND bill_number = btrim(p_bill_number);
    IF FOUND THEN
        IF bill_row.purchase_id IS DISTINCT FROM p_purchase_id OR bill_row.amount IS DISTINCT FROM p_amount
            OR bill_row.due_date IS DISTINCT FROM p_due_date THEN
            RAISE EXCEPTION 'Supplier bill number already used with different details' USING ERRCODE = '22023';
        END IF;
        RETURN bill_row;
    END IF;
    SELECT coalesce(sum(amount),0) INTO billed FROM public.supplier_bills WHERE purchase_id = p_purchase_id;
    IF billed + p_amount > purchase_row.total_amount THEN
        RAISE EXCEPTION 'Supplier bills exceed purchase amount' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.supplier_bills(purchase_id,supplier_id,bill_number,due_date,currency,amount,entered_by)
    VALUES (p_purchase_id,purchase_row.supplier_id,btrim(p_bill_number),p_due_date,purchase_row.currency,p_amount,auth.uid())
    RETURNING * INTO bill_row;
    RETURN bill_row;
END;
$bill$;

CREATE OR REPLACE FUNCTION public.record_supplier_bill_payment(
    p_bill_id uuid,p_amount numeric,p_currency text,p_reference text,p_request_id uuid
)
RETURNS public.supplier_bill_payments LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $payment$
DECLARE
    bill_row public.supplier_bills%ROWTYPE;
    purchase_row public.purchases%ROWTYPE;
    payment_row public.supplier_bill_payments%ROWTYPE;
    purchase_paid numeric;
BEGIN
    IF NOT public.can_read_finance() THEN
        RAISE EXCEPTION 'Supplier payment denied' USING ERRCODE = '42501';
    END IF;
    IF p_request_id IS NULL OR p_amount IS NULL OR p_amount::text IN ('NaN','Infinity','-Infinity')
        OR p_amount <= 0 OR round(p_amount,2) <> p_amount
        OR coalesce(length(btrim(p_reference)),0) NOT BETWEEN 1 AND 100 THEN
        RAISE EXCEPTION 'Invalid supplier payment' USING ERRCODE = '22023';
    END IF;
    SELECT p.* INTO purchase_row FROM public.purchases p
    JOIN public.supplier_bills b ON b.purchase_id = p.id
    WHERE b.id = p_bill_id FOR UPDATE OF p;
    IF NOT FOUND OR purchase_row.status = 'cancelled' THEN
        RAISE EXCEPTION 'Supplier bill unavailable' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO STRICT bill_row FROM public.supplier_bills WHERE id = p_bill_id FOR UPDATE;
    SELECT * INTO payment_row FROM public.supplier_bill_payments WHERE id = p_request_id;
    IF FOUND THEN
        IF payment_row.bill_id IS DISTINCT FROM p_bill_id OR payment_row.amount IS DISTINCT FROM p_amount
            OR payment_row.currency IS DISTINCT FROM p_currency OR payment_row.reference IS DISTINCT FROM btrim(p_reference)
            OR payment_row.entered_by IS DISTINCT FROM auth.uid() THEN
            RAISE EXCEPTION 'Payment request already used with different details' USING ERRCODE = '22023';
        END IF;
        RETURN payment_row;
    END IF;
    IF p_currency IS DISTINCT FROM bill_row.currency OR bill_row.amount_paid + p_amount > bill_row.amount THEN
        RAISE EXCEPTION 'Payment exceeds supplier debt or currency differs' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.supplier_bill_payments(id,bill_id,amount,currency,reference,entered_by)
    VALUES (p_request_id,p_bill_id,p_amount,p_currency,btrim(p_reference),auth.uid())
    RETURNING * INTO payment_row;
    UPDATE public.supplier_bills SET amount_paid = amount_paid + p_amount WHERE id = p_bill_id;
    SELECT sum(amount_paid) INTO purchase_paid FROM public.supplier_bills WHERE purchase_id = purchase_row.id;
    UPDATE public.purchases SET payment_status =
        CASE WHEN purchase_paid = purchase_row.total_amount THEN 'paid' ELSE 'partial' END
    WHERE id = purchase_row.id;
    RETURN payment_row;
END;
$payment$;
REVOKE ALL ON FUNCTION public.register_supplier_bill(uuid,text,date,numeric),
    public.record_supplier_bill_payment(uuid,numeric,text,text,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_supplier_bill(uuid,text,date,numeric),
    public.record_supplier_bill_payment(uuid,numeric,text,text,uuid) TO authenticated;
REVOKE UPDATE ON public.purchases FROM PUBLIC, anon, authenticated;
GRANT UPDATE (notes,updated_at) ON public.purchases TO authenticated;
REVOKE DELETE ON public.purchases FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.cancel_unreceived_purchase(p_purchase_id uuid)
RETURNS public.purchases LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $cancel$
DECLARE
    purchase_row public.purchases%ROWTYPE;
BEGIN
    IF coalesce(public.current_user_role(),'') NOT IN ('admin','acheteur') THEN
        RAISE EXCEPTION 'Purchase cancellation denied' USING ERRCODE = '42501';
    END IF;
    SELECT * INTO purchase_row FROM public.purchases WHERE id = p_purchase_id FOR UPDATE;
    IF NOT FOUND OR purchase_row.status IS NULL OR purchase_row.status NOT IN ('pending','cancelled')
        OR EXISTS (SELECT 1 FROM public.purchase_items WHERE purchase_id = p_purchase_id AND received_quantity > 0)
        OR EXISTS (SELECT 1 FROM public.supplier_bills WHERE purchase_id = p_purchase_id) THEN
        RAISE EXCEPTION 'Only unreceived and unbilled purchases can be cancelled' USING ERRCODE = '22023';
    END IF;
    UPDATE public.purchases SET status = 'cancelled' WHERE id = p_purchase_id RETURNING * INTO purchase_row;
    RETURN purchase_row;
END;
$cancel$;
REVOKE ALL ON FUNCTION public.cancel_unreceived_purchase(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cancel_unreceived_purchase(uuid) TO authenticated;
COMMIT;
