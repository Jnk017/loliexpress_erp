-- P1.a — tracer le contrôle du retour et réintégrer seulement le vendable.
BEGIN;
CREATE TABLE IF NOT EXISTS public.customer_return_inspections (
    id uuid PRIMARY KEY,
    order_item_id uuid NOT NULL REFERENCES public.order_items(id),
    warehouse_id uuid NOT NULL REFERENCES public.warehouse_locations(id),
    returned_quantity integer NOT NULL CHECK (returned_quantity > 0),
    sellable_quantity integer NOT NULL CHECK (sellable_quantity BETWEEN 0 AND returned_quantity),
    inspection_note text NOT NULL CHECK (length(btrim(inspection_note)) BETWEEN 1 AND 1000),
    inspected_by uuid NOT NULL REFERENCES public.user_profiles(id),
    inspected_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS customer_return_inspections_order_item_idx
    ON public.customer_return_inspections(order_item_id);
ALTER TABLE public.customer_return_inspections ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.customer_return_inspections FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.customer_return_inspections TO authenticated;
DROP POLICY IF EXISTS read_inspected_customer_returns ON public.customer_return_inspections;
CREATE POLICY read_inspected_customer_returns ON public.customer_return_inspections
FOR SELECT TO authenticated
USING (public.is_admin() OR public.is_warehouse_staff() OR public.is_comptable());

CREATE OR REPLACE FUNCTION public.get_customer_return_lines(p_order_number text)
RETURNS TABLE(order_item_id uuid, product_name text, sku text, remaining_quantity integer, warehouse_name text)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $lookup$
BEGIN
    IF NOT (public.is_admin() OR public.is_warehouse_staff()) THEN
        RAISE EXCEPTION 'Return lookup denied' USING ERRCODE = '42501';
    END IF;
    RETURN QUERY
    SELECT i.id,p.name,p.sku,
        (i.quantity - coalesce(sum(r.returned_quantity),0))::integer,w.name
    FROM public.sales_orders o
    JOIN public.stock_handovers h ON h.order_id = o.id
    JOIN public.order_items i ON i.order_id = o.id
    JOIN public.products p ON p.id = i.product_id
    JOIN public.warehouse_locations w ON w.id = h.warehouse_id
    LEFT JOIN public.customer_return_inspections r ON r.order_item_id = i.id
    WHERE o.order_number = upper(btrim(p_order_number))
    GROUP BY i.id,p.name,p.sku,w.name
    HAVING i.quantity > coalesce(sum(r.returned_quantity),0)
    ORDER BY p.name,i.id;
END;
$lookup$;

CREATE OR REPLACE FUNCTION public.inspect_customer_return(
    p_order_item_id uuid, p_returned_quantity integer, p_sellable_quantity integer,
    p_inspection_note text, p_request_id uuid
)
RETURNS public.customer_return_inspections
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $inspection$
DECLARE
    item_row public.order_items%ROWTYPE;
    inspection public.customer_return_inspections%ROWTYPE;
    warehouse uuid;
    already_returned bigint;
    stock_quantity integer;
    ledger_quantity bigint;
BEGIN
    IF NOT (public.is_admin() OR public.is_warehouse_staff()) THEN
        RAISE EXCEPTION 'Return inspection denied' USING ERRCODE = '42501';
    END IF;
    IF p_request_id IS NULL OR p_returned_quantity IS NULL OR p_returned_quantity <= 0
        OR p_sellable_quantity IS NULL OR p_sellable_quantity NOT BETWEEN 0 AND p_returned_quantity
        OR coalesce(length(btrim(p_inspection_note)),0) NOT BETWEEN 1 AND 1000 THEN
        RAISE EXCEPTION 'Explicit quantities and inspection note required' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO item_row FROM public.order_items WHERE id = p_order_item_id FOR UPDATE;
    IF NOT FOUND OR item_row.product_id IS NULL THEN
        RAISE EXCEPTION 'Order item unavailable' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO inspection FROM public.customer_return_inspections WHERE id = p_request_id;
    IF FOUND THEN
        IF inspection.order_item_id IS DISTINCT FROM p_order_item_id
            OR inspection.returned_quantity IS DISTINCT FROM p_returned_quantity
            OR inspection.sellable_quantity IS DISTINCT FROM p_sellable_quantity
            OR inspection.inspection_note IS DISTINCT FROM btrim(p_inspection_note)
            OR inspection.inspected_by IS DISTINCT FROM auth.uid() THEN
            RAISE EXCEPTION 'Request already used with other return details' USING ERRCODE = '22023';
        END IF;
        RETURN inspection;
    END IF;
    SELECT h.warehouse_id INTO warehouse FROM public.stock_handovers h
    WHERE h.order_id = item_row.order_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Return requires a confirmed customer handover' USING ERRCODE = '22023';
    END IF;
    SELECT coalesce(sum(r.returned_quantity),0) INTO already_returned
    FROM public.customer_return_inspections r WHERE r.order_item_id = p_order_item_id;
    IF already_returned + p_returned_quantity > item_row.quantity THEN
        RAISE EXCEPTION 'Return exceeds handed-over quantity' USING ERRCODE = 'P4104';
    END IF;
    IF p_sellable_quantity > 0 THEN
        IF NOT EXISTS (SELECT 1 FROM public.warehouse_locations WHERE id = warehouse AND is_active)
            OR NOT EXISTS (SELECT 1 FROM public.products WHERE id = item_row.product_id AND is_active) THEN
            RAISE EXCEPTION 'Active product and original warehouse required' USING ERRCODE = '22023';
        END IF;
        SELECT quantity INTO stock_quantity FROM public.inventory_stock
        WHERE product_id = item_row.product_id AND warehouse_id = warehouse FOR UPDATE;
        SELECT coalesce(sum(CASE WHEN m.movement_type = 'out' THEN -m.quantity::bigint ELSE m.quantity END),0)
        INTO ledger_quantity FROM public.stock_movements m
        WHERE m.product_id = item_row.product_id AND m.warehouse_id = warehouse;
        IF stock_quantity IS DISTINCT FROM ledger_quantity THEN
            RAISE EXCEPTION 'Reconcile warehouse stock before restocking' USING ERRCODE = '22003';
        END IF;
    END IF;
    INSERT INTO public.customer_return_inspections
        (id,order_item_id,warehouse_id,returned_quantity,sellable_quantity,inspection_note,inspected_by)
    VALUES (p_request_id,p_order_item_id,warehouse,p_returned_quantity,p_sellable_quantity,
        btrim(p_inspection_note),auth.uid())
    RETURNING * INTO inspection;
    IF p_sellable_quantity > 0 THEN
        INSERT INTO public.stock_movements
            (product_id,warehouse_id,movement_type,quantity,reference_id,reference_type,created_by)
        VALUES (item_row.product_id,warehouse,'return',p_sellable_quantity,p_request_id,
            'inspected_customer_return',auth.uid());
    END IF;
    INSERT INTO public.audit_logs(table_name,record_id,action_type,new_values,user_id)
    VALUES ('customer_return_inspections',inspection.id,'insert',to_jsonb(inspection),auth.uid());
    RETURN inspection;
END;
$inspection$;
REVOKE ALL ON FUNCTION public.get_customer_return_lines(text),
    public.inspect_customer_return(uuid,integer,integer,text,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_customer_return_lines(text),
    public.inspect_customer_return(uuid,integer,integer,text,uuid) TO authenticated;
COMMIT;
