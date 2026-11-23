-- P0.a — aligner le changement de statut et protéger la séquence des transitions.
BEGIN;
CREATE OR REPLACE FUNCTION public.enforce_order_status_transition()
RETURNS trigger LANGUAGE plpgsql SET search_path = ''
AS $fn$
BEGIN
    IF NEW.order_status IS DISTINCT FROM OLD.order_status AND NOT (
        (OLD.order_status = 'pending' AND NEW.order_status IN ('confirmed', 'cancelled')) OR
        (OLD.order_status = 'confirmed' AND NEW.order_status IN ('processing', 'cancelled')) OR
        (OLD.order_status = 'processing' AND NEW.order_status IN ('shipped', 'cancelled')) OR
        (OLD.order_status = 'shipped' AND NEW.order_status IN ('delivered', 'cancelled'))
    ) THEN
        RAISE EXCEPTION 'Invalid order status transition' USING ERRCODE = '22023';
    END IF;
    RETURN NEW;
END;
$fn$;
DROP TRIGGER IF EXISTS enforce_order_status_transition ON public.sales_orders;
CREATE TRIGGER enforce_order_status_transition
BEFORE UPDATE OF order_status ON public.sales_orders
FOR EACH ROW EXECUTE FUNCTION public.enforce_order_status_transition();

CREATE OR REPLACE FUNCTION public.transition_order_status(
    p_order_id uuid, p_new_status public.order_status, p_reason text DEFAULT NULL
)
RETURNS public.sales_orders
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE
    actor_role text := public.current_user_role();
    order_row public.sales_orders%ROWTYPE;
BEGIN
    SELECT * INTO order_row FROM public.sales_orders WHERE id = p_order_id FOR UPDATE;
    IF NOT FOUND OR p_new_status IS NULL OR NOT EXISTS (
        SELECT 1 FROM public.customers c
        WHERE c.id = order_row.customer_id AND
          (actor_role IN ('admin', 'warehouse_staff')
           OR (actor_role = 'sales_rep' AND (order_row.sales_rep_id = auth.uid() OR c.commercial_id = auth.uid()))
           OR (actor_role = 'b2b_customer' AND c.user_id = auth.uid()
               AND order_row.order_status = 'pending' AND p_new_status = 'cancelled'))
    ) THEN
        RAISE EXCEPTION 'Order transition denied' USING ERRCODE = '42501';
    END IF;
    UPDATE public.sales_orders SET order_status = p_new_status,
        notes = concat_ws(E'\n', nullif(notes, ''), nullif(btrim(p_reason), ''))
    WHERE id = p_order_id RETURNING * INTO order_row;
    RETURN order_row;
END;
$fn$;
REVOKE ALL ON FUNCTION public.enforce_order_status_transition() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.transition_order_status(uuid, public.order_status, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.transition_order_status(uuid, public.order_status, text) TO authenticated;
COMMIT;
