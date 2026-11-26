-- P1.a — débiter le stock au moment de la remise réelle au client.
BEGIN;
ALTER TABLE public.deliveries ADD COLUMN IF NOT EXISTS warehouse_id uuid
    REFERENCES public.warehouse_locations(id);
DROP POLICY IF EXISTS warehouse_read_pending_deliveries ON public.deliveries;
CREATE POLICY warehouse_read_pending_deliveries ON public.deliveries
FOR SELECT TO authenticated USING (public.is_warehouse_staff() AND status = 'pending');
CREATE TABLE IF NOT EXISTS public.stock_handovers (
    order_id uuid PRIMARY KEY REFERENCES public.sales_orders(id),
    delivery_id uuid NOT NULL UNIQUE REFERENCES public.deliveries(id),
    warehouse_id uuid NOT NULL REFERENCES public.warehouse_locations(id),
    handed_over_by uuid NOT NULL REFERENCES public.user_profiles(id),
    handed_over_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.stock_handovers ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.stock_handovers FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.assign_delivery_warehouse(p_delivery_id uuid,p_warehouse_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $assign$
BEGIN
    IF NOT (public.is_admin() OR public.is_warehouse_staff()) THEN
        RAISE EXCEPTION 'Warehouse assignment denied' USING ERRCODE = '42501';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.warehouse_locations WHERE id = p_warehouse_id AND is_active) THEN
        RAISE EXCEPTION 'Choose an active warehouse' USING ERRCODE = '22023';
    END IF;
    UPDATE public.deliveries SET warehouse_id = p_warehouse_id
    WHERE id = p_delivery_id AND status = 'pending';
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Only a pending delivery can be assigned a warehouse' USING ERRCODE = '22023';
    END IF;
END;
$assign$;

CREATE OR REPLACE FUNCTION public.require_stock_handover()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $guard$
BEGIN
    IF NEW.status = 'delivered' AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM NEW.status)
        AND NOT EXISTS (SELECT 1 FROM public.stock_handovers h WHERE h.delivery_id = NEW.id) THEN
        RAISE EXCEPTION 'Confirm delivery through the stock handover' USING ERRCODE = '22023';
    END IF;
    IF TG_OP = 'UPDATE' AND OLD.status = 'delivered'
        AND (NEW.status IS DISTINCT FROM OLD.status OR NEW.order_id IS DISTINCT FROM OLD.order_id
            OR NEW.warehouse_id IS DISTINCT FROM OLD.warehouse_id) THEN
        RAISE EXCEPTION 'Confirmed handover cannot be edited' USING ERRCODE = '22023';
    END IF;
    RETURN NEW;
END;
$guard$;
DROP TRIGGER IF EXISTS require_stock_handover ON public.deliveries;
CREATE TRIGGER require_stock_handover BEFORE INSERT OR UPDATE ON public.deliveries
FOR EACH ROW EXECUTE FUNCTION public.require_stock_handover();

CREATE OR REPLACE FUNCTION public.require_order_stock_handover()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $guard$
BEGIN
    IF NEW.order_status = 'delivered' AND (TG_OP = 'INSERT' OR OLD.order_status IS DISTINCT FROM NEW.order_status)
        AND NOT EXISTS (SELECT 1 FROM public.stock_handovers h WHERE h.order_id = NEW.id) THEN
        RAISE EXCEPTION 'Confirm the customer handover first' USING ERRCODE = '22023';
    END IF;
    RETURN NEW;
END;
$guard$;
DROP TRIGGER IF EXISTS require_order_stock_handover ON public.sales_orders;
CREATE TRIGGER require_order_stock_handover BEFORE INSERT OR UPDATE OF order_status ON public.sales_orders
FOR EACH ROW EXECUTE FUNCTION public.require_order_stock_handover();

CREATE OR REPLACE FUNCTION public.confirm_delivery(
    p_delivery_id uuid, p_signature_url text DEFAULT NULL, p_notes text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $handover$
DECLARE
    delivery_row public.deliveries%ROWTYPE;
    order_row public.sales_orders%ROWTYPE;
    line record;
    available integer;
    ledger_quantity bigint;
BEGIN
    SELECT * INTO delivery_row FROM public.deliveries WHERE id = p_delivery_id FOR UPDATE;
    IF NOT FOUND OR NOT (
        public.is_admin() OR (public.is_delivery_agent() AND EXISTS (
            SELECT 1 FROM public.delivery_routes r
            WHERE r.id = delivery_row.route_id AND r.driver_id = auth.uid()))
    ) THEN
        RAISE EXCEPTION 'Delivery confirmation denied' USING ERRCODE = '42501';
    END IF;
    IF EXISTS (SELECT 1 FROM public.stock_handovers WHERE delivery_id = p_delivery_id) THEN
        RETURN jsonb_build_object('success',true,'delivery_id',p_delivery_id);
    END IF;
    IF delivery_row.status IS NULL OR delivery_row.status NOT IN ('pending','in_transit')
        OR NOT EXISTS (SELECT 1 FROM public.warehouse_locations WHERE id = delivery_row.warehouse_id AND is_active) THEN
        RAISE EXCEPTION 'Pending delivery and active assigned warehouse required' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO order_row FROM public.sales_orders WHERE id = delivery_row.order_id FOR UPDATE;
    IF NOT FOUND OR order_row.order_status IS DISTINCT FROM 'shipped' THEN
        RAISE EXCEPTION 'The order must be shipped before handover' USING ERRCODE = '22023';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.order_items WHERE order_id = order_row.id)
        OR EXISTS (SELECT 1 FROM public.order_items WHERE order_id = order_row.id
                    AND (product_id IS NULL OR quantity IS NULL OR quantity < 1)) THEN
        RAISE EXCEPTION 'Order items are unavailable' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.stock_handovers(order_id,delivery_id,warehouse_id,handed_over_by)
    VALUES (order_row.id,p_delivery_id,delivery_row.warehouse_id,auth.uid());
    FOR line IN SELECT product_id,sum(quantity)::integer AS quantity
        FROM public.order_items WHERE order_id = order_row.id GROUP BY product_id ORDER BY product_id
    LOOP
        SELECT s.quantity INTO available FROM public.inventory_stock s
        WHERE s.product_id = line.product_id AND s.warehouse_id = delivery_row.warehouse_id FOR UPDATE;
        IF NOT FOUND OR available IS NULL OR available < line.quantity THEN
            RAISE EXCEPTION 'Insufficient stock in the assigned warehouse' USING ERRCODE = '22003';
        END IF;
        SELECT coalesce(sum(CASE WHEN m.movement_type = 'out' THEN -m.quantity::bigint ELSE m.quantity END),0)
        INTO ledger_quantity FROM public.stock_movements m
        WHERE m.product_id = line.product_id AND m.warehouse_id = delivery_row.warehouse_id;
        IF ledger_quantity <> available THEN
            RAISE EXCEPTION 'Reconcile the warehouse stock before handover' USING ERRCODE = '22003';
        END IF;
        INSERT INTO public.stock_movements(product_id,warehouse_id,movement_type,quantity,
            reference_id,reference_type,created_by)
        VALUES (line.product_id,delivery_row.warehouse_id,'out',line.quantity,
            p_delivery_id,'customer_handover',auth.uid());
    END LOOP;
    UPDATE public.deliveries SET status = 'delivered', actual_delivery_time = now(),
        signature_url = coalesce(p_signature_url,signature_url), notes = coalesce(p_notes,notes)
    WHERE id = p_delivery_id;
    UPDATE public.sales_orders SET order_status = 'delivered' WHERE id = order_row.id;
    INSERT INTO public.audit_logs(table_name,record_id,action_type,new_values,user_id)
    VALUES ('deliveries',p_delivery_id,'update',jsonb_build_object(
        'operation','customer_handover','warehouse_id',delivery_row.warehouse_id),auth.uid());
    RETURN jsonb_build_object('success',true,'delivery_id',p_delivery_id);
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success',false,'error',SQLERRM);
END;
$handover$;
REVOKE ALL ON FUNCTION public.require_stock_handover(),public.require_order_stock_handover() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.assign_delivery_warehouse(uuid,uuid),public.confirm_delivery(uuid,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assign_delivery_warehouse(uuid,uuid),public.confirm_delivery(uuid,text,text) TO authenticated;
REVOKE UPDATE ON public.deliveries FROM PUBLIC, anon, authenticated;
GRANT UPDATE (order_id, route_id, delivery_address, latitude, longitude, estimated_time,
    status, actual_delivery_time, signature_url, notes, updated_at)
ON public.deliveries TO authenticated;
COMMIT;
