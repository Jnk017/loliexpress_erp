-- P1.a G11 — RA1 à RA5. Ligne facturée figée, contrôle admin et plafonds serveur.
BEGIN;
CREATE TABLE IF NOT EXISTS public.invoice_lines (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id uuid NOT NULL REFERENCES public.invoices(id),
    order_item_id uuid NOT NULL REFERENCES public.order_items(id),
    original_qty integer NOT NULL CHECK (original_qty > 0),
    net_line_total numeric(12,2) NOT NULL CHECK (net_line_total >= 0),
    net_unit_price numeric GENERATED ALWAYS AS (net_line_total / original_qty) STORED,
    UNIQUE(invoice_id,order_item_id)
);
ALTER TABLE public.invoice_lines ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.invoice_lines FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.invoice_lines TO authenticated;
DROP POLICY IF EXISTS read_invoice_lines ON public.invoice_lines;
CREATE POLICY read_invoice_lines ON public.invoice_lines FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.invoices i WHERE i.id = invoice_lines.invoice_id));

CREATE OR REPLACE FUNCTION public.snapshot_invoice_lines()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $snapshot$
BEGIN
    INSERT INTO public.invoice_lines(invoice_id,order_item_id,original_qty,net_line_total)
    SELECT NEW.id,x.id,x.quantity,x.line_total - CASE WHEN NEW.subtotal > 0 THEN
        round(NEW.discount_amount * x.running_total / NEW.subtotal,2)
        - round(NEW.discount_amount * (x.running_total - x.line_total) / NEW.subtotal,2)
        ELSE 0 END
    FROM (
        SELECT i.id,i.quantity,i.line_total,
            sum(i.line_total) OVER (ORDER BY i.id ROWS UNBOUNDED PRECEDING) AS running_total
        FROM public.order_items i WHERE i.order_id = NEW.order_id
    ) x;
    RETURN NEW;
END;
$snapshot$;
DROP TRIGGER IF EXISTS snapshot_invoice_lines ON public.invoices;
CREATE TRIGGER snapshot_invoice_lines AFTER INSERT ON public.invoices
FOR EACH ROW EXECUTE FUNCTION public.snapshot_invoice_lines();

CREATE OR REPLACE FUNCTION public.reject_invoice_line_changes()
RETURNS trigger LANGUAGE plpgsql SET search_path = ''
AS $immutable$
BEGIN
    RAISE EXCEPTION 'Issued invoice line is immutable' USING ERRCODE = 'P4103';
END;
$immutable$;
DROP TRIGGER IF EXISTS immutable_invoice_line ON public.invoice_lines;
CREATE TRIGGER immutable_invoice_line BEFORE UPDATE OR DELETE ON public.invoice_lines
FOR EACH ROW EXECUTE FUNCTION public.reject_invoice_line_changes();

CREATE TABLE IF NOT EXISTS public.return_units_audit (
    return_id uuid PRIMARY KEY REFERENCES public.customer_return_inspections(id),
    rejected_quantity integer NOT NULL CHECK (rejected_quantity > 0),
    decision_note text NOT NULL,
    controlled_by uuid NOT NULL REFERENCES public.user_profiles(id),
    controlled_at timestamptz NOT NULL
);
ALTER TABLE public.return_units_audit ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.return_units_audit FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.return_units_audit TO authenticated;
DROP POLICY IF EXISTS read_return_units_audit ON public.return_units_audit;
CREATE POLICY read_return_units_audit ON public.return_units_audit FOR SELECT TO authenticated
USING (public.is_admin() OR public.is_warehouse_staff() OR public.is_comptable());

CREATE OR REPLACE FUNCTION public.enforce_return_sellability()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $return_control$
BEGIN
    IF NEW.sellable_quantity > 0 AND NOT public.is_admin() THEN
        RAISE EXCEPTION 'Administrator declaration required for sellable units' USING ERRCODE = '42501';
    END IF;
    IF NEW.returned_quantity > NEW.sellable_quantity THEN
        INSERT INTO public.return_units_audit(return_id,rejected_quantity,decision_note,controlled_by,controlled_at)
        VALUES (NEW.id,NEW.returned_quantity-NEW.sellable_quantity,NEW.inspection_note,NEW.inspected_by,NEW.inspected_at);
    END IF;
    RETURN NEW;
END;
$return_control$;
DROP TRIGGER IF EXISTS audit_return_sellability ON public.customer_return_inspections;
CREATE TRIGGER audit_return_sellability AFTER INSERT ON public.customer_return_inspections
FOR EACH ROW EXECUTE FUNCTION public.enforce_return_sellability();

ALTER TABLE public.invoice_item_credits ADD COLUMN IF NOT EXISTS invoice_line_id uuid REFERENCES public.invoice_lines(id);
ALTER TABLE public.invoice_item_credits ALTER COLUMN invoice_line_id SET NOT NULL;
DO $rename$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_attribute WHERE attrelid = 'public.invoice_item_credits'::regclass
        AND attname = 'inspection_id' AND NOT attisdropped) THEN
        ALTER TABLE public.invoice_item_credits RENAME COLUMN inspection_id TO return_id;
    END IF;
END;
$rename$;
CREATE UNIQUE INDEX IF NOT EXISTS invoice_item_credit_one_per_line_return
    ON public.invoice_item_credits(invoice_line_id,return_id);

CREATE OR REPLACE FUNCTION public.enforce_item_credit_quantity()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $credit_limit$
DECLARE
    source_line public.invoice_lines%ROWTYPE;
    source_return public.customer_return_inspections%ROWTYPE;
    credited bigint;
BEGIN
    SELECT * INTO STRICT source_line FROM public.invoice_lines WHERE id = NEW.invoice_line_id FOR UPDATE;
    SELECT * INTO STRICT source_return FROM public.customer_return_inspections WHERE id = NEW.return_id;
    IF source_return.sellable_quantity = 0 THEN
        RAISE EXCEPTION 'Non-sellable units cannot be credited' USING ERRCODE = 'P4101';
    END IF;
    IF source_return.order_item_id IS DISTINCT FROM source_line.order_item_id
        OR NEW.invoice_id IS DISTINCT FROM source_line.invoice_id
        OR NEW.quantity IS DISTINCT FROM source_return.sellable_quantity THEN
        RAISE EXCEPTION 'Credit must match original invoice line and sellable units' USING ERRCODE = 'P4102';
    END IF;
    SELECT coalesce(sum(quantity),0) INTO credited FROM public.invoice_item_credits
    WHERE invoice_line_id = NEW.invoice_line_id;
    IF credited + NEW.quantity > source_line.original_qty OR EXISTS (
        SELECT 1 FROM public.invoice_item_credits WHERE invoice_line_id = NEW.invoice_line_id
        AND return_id = NEW.return_id
    ) THEN
        RAISE EXCEPTION 'Units already credited or invoice quantity exceeded' USING ERRCODE = 'P4104';
    END IF;
    RETURN NEW;
END;
$credit_limit$;
DROP TRIGGER IF EXISTS enforce_item_credit_quantity ON public.invoice_item_credits;
CREATE TRIGGER enforce_item_credit_quantity BEFORE INSERT ON public.invoice_item_credits
FOR EACH ROW EXECUTE FUNCTION public.enforce_item_credit_quantity();

CREATE OR REPLACE FUNCTION public.record_return_item_credit(p_inspection_id uuid)
RETURNS public.invoice_item_credits LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $credit$
DECLARE
    inspection public.customer_return_inspections%ROWTYPE;
    source_line public.invoice_lines%ROWTYPE;
    invoice_row public.invoices%ROWTYPE;
    credit_row public.invoice_item_credits%ROWTYPE;
    credited bigint;
    credit_amount numeric;
    net_credited numeric;
    state public.payment_status;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Item credit approval denied' USING ERRCODE = '42501';
    END IF;
    SELECT * INTO inspection FROM public.customer_return_inspections WHERE id = p_inspection_id;
    IF NOT FOUND OR inspection.sellable_quantity = 0 THEN
        RAISE EXCEPTION 'Non-sellable units cannot be credited' USING ERRCODE = 'P4101';
    END IF;
    SELECT l.* INTO source_line FROM public.invoice_lines l
    WHERE l.order_item_id = inspection.order_item_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Original issued invoice line required' USING ERRCODE = 'P4102';
    END IF;
    SELECT * INTO STRICT invoice_row FROM public.invoices WHERE id = source_line.invoice_id FOR UPDATE;
    IF EXISTS (SELECT 1 FROM public.invoice_item_credits WHERE return_id = p_inspection_id) THEN
        RAISE EXCEPTION 'Units already credited' USING ERRCODE = 'P4104';
    END IF;
    SELECT coalesce(sum(quantity),0) INTO credited FROM public.invoice_item_credits
    WHERE invoice_line_id = source_line.id;
    credit_amount := round(source_line.net_line_total * (credited + inspection.sellable_quantity)
        / source_line.original_qty,2) - round(source_line.net_line_total * credited / source_line.original_qty,2);
    IF credit_amount <= 0 THEN
        RAISE EXCEPTION 'No amount creditable on this line' USING ERRCODE = 'P4102';
    END IF;
    INSERT INTO public.invoice_item_credits(invoice_id,invoice_line_id,return_id,quantity,amount,approved_by)
    VALUES (invoice_row.id,source_line.id,p_inspection_id,inspection.sellable_quantity,credit_amount,auth.uid())
    RETURNING * INTO credit_row;
    net_credited := invoice_row.item_amount_credited + credit_amount;
    state := CASE WHEN coalesce(invoice_row.amount_paid,0)+invoice_row.delivery_fee_credited+net_credited
        >= invoice_row.total_amount THEN 'paid'::public.payment_status
        WHEN coalesce(invoice_row.amount_paid,0) > 0 THEN 'partial'::public.payment_status
        ELSE 'pending'::public.payment_status END;
    UPDATE public.invoices SET item_amount_credited = net_credited,payment_status = state WHERE id = invoice_row.id;
    UPDATE public.sales_orders SET payment_status = state WHERE id = invoice_row.order_id;
    INSERT INTO public.audit_logs(table_name,record_id,action_type,new_values,user_id)
    VALUES ('invoice_item_credits',credit_row.id,'insert',to_jsonb(credit_row),auth.uid());
    RETURN credit_row;
END;
$credit$;
REVOKE ALL ON FUNCTION public.snapshot_invoice_lines(),public.reject_invoice_line_changes(),
    public.enforce_return_sellability(),public.enforce_item_credit_quantity() FROM PUBLIC, anon, authenticated;
COMMIT;
