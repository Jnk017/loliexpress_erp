-- P1.a — enregistrer la réception physique indépendamment du règlement.
BEGIN;
CREATE TABLE IF NOT EXISTS public.purchase_receipts (
    id uuid PRIMARY KEY,
    purchase_item_id uuid NOT NULL REFERENCES public.purchase_items(id),
    warehouse_id uuid NOT NULL REFERENCES public.warehouse_locations(id),
    quantity integer NOT NULL CHECK (quantity > 0),
    received_by uuid NOT NULL REFERENCES public.user_profiles(id),
    created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.purchase_receipts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.purchase_receipts FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.purchase_receipts TO authenticated;
DROP POLICY IF EXISTS purchase_receipts_read ON public.purchase_receipts;
CREATE POLICY purchase_receipts_read ON public.purchase_receipts FOR SELECT TO authenticated
USING (public.can_read_procurement() OR public.is_warehouse_staff());

CREATE OR REPLACE FUNCTION public.receive_purchase_item(
    p_purchase_item_id uuid, p_warehouse_id uuid, p_quantity integer, p_request_id uuid
)
RETURNS public.purchase_receipts LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $receipt$
DECLARE
    item_row public.purchase_items%ROWTYPE;
    purchase_row public.purchases%ROWTYPE;
    receipt_row public.purchase_receipts%ROWTYPE;
BEGIN
    IF coalesce(public.current_user_role(),'') NOT IN ('admin','acheteur','warehouse_staff') THEN
        RAISE EXCEPTION 'Receipt denied' USING ERRCODE = '42501';
    END IF;
    IF p_quantity IS NULL OR p_quantity < 1 OR p_request_id IS NULL THEN
        RAISE EXCEPTION 'Invalid receipt quantity or request' USING ERRCODE = '22023';
    END IF;
    SELECT p.* INTO purchase_row FROM public.purchases p
    JOIN public.purchase_items i ON i.purchase_id = p.id
    WHERE i.id = p_purchase_item_id FOR UPDATE OF p;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Purchase line not found' USING ERRCODE = 'P0002';
    END IF;
    SELECT * INTO receipt_row FROM public.purchase_receipts WHERE id = p_request_id;
    IF FOUND THEN
        IF receipt_row.purchase_item_id IS DISTINCT FROM p_purchase_item_id
            OR receipt_row.warehouse_id IS DISTINCT FROM p_warehouse_id
            OR receipt_row.quantity IS DISTINCT FROM p_quantity
            OR receipt_row.received_by IS DISTINCT FROM auth.uid() THEN
            RAISE EXCEPTION 'Receipt request already used with other details' USING ERRCODE = '22023';
        END IF;
        RETURN receipt_row;
    END IF;
    SELECT * INTO STRICT item_row FROM public.purchase_items WHERE id = p_purchase_item_id FOR UPDATE;
    IF purchase_row.status NOT IN ('pending','partial') OR purchase_row.status IS NULL
       OR p_quantity > item_row.quantity - coalesce(item_row.received_quantity,0)
       OR NOT EXISTS (SELECT 1 FROM public.warehouse_locations WHERE id = p_warehouse_id AND is_active) THEN
        RAISE EXCEPTION 'Receipt exceeds ordered quantity or warehouse is unavailable' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.inventory_stock(product_id,warehouse_id,quantity)
    VALUES (item_row.product_id,p_warehouse_id,0)
    ON CONFLICT (product_id,warehouse_id) DO NOTHING;
    PERFORM 1 FROM public.inventory_stock
    WHERE product_id = item_row.product_id AND warehouse_id = p_warehouse_id FOR UPDATE;
    INSERT INTO public.purchase_receipts(id,purchase_item_id,warehouse_id,quantity,received_by)
    VALUES (p_request_id,p_purchase_item_id,p_warehouse_id,p_quantity,auth.uid())
    RETURNING * INTO receipt_row;
    INSERT INTO public.stock_movements(product_id,warehouse_id,movement_type,quantity,
        reference_id,reference_type,created_by)
    VALUES (item_row.product_id,p_warehouse_id,'in',p_quantity,p_request_id,'purchase_receipt',auth.uid());
    UPDATE public.purchase_items SET received_quantity = coalesce(received_quantity,0)+p_quantity
    WHERE id = p_purchase_item_id;
    UPDATE public.purchases SET status = CASE WHEN EXISTS (
        SELECT 1 FROM public.purchase_items i
        WHERE i.purchase_id = purchase_row.id AND coalesce(i.received_quantity,0) < i.quantity
    ) THEN 'partial' ELSE 'received' END, received_by = auth.uid()
    WHERE id = purchase_row.id;
    INSERT INTO public.audit_logs(table_name,record_id,action_type,new_values,user_id)
    VALUES ('purchase_receipts',receipt_row.id,'insert',to_jsonb(receipt_row),auth.uid());
    RETURN receipt_row;
END;
$receipt$;
REVOKE ALL ON FUNCTION public.receive_purchase_item(uuid,uuid,integer,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.receive_purchase_item(uuid,uuid,integer,uuid) TO authenticated;
REVOKE UPDATE, DELETE ON public.purchase_items FROM PUBLIC, anon, authenticated;
COMMIT;
