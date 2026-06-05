-- Production hardening for transactional ERP operations, financial validation and RBAC.

CREATE TABLE IF NOT EXISTS public.exchange_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    base_currency TEXT NOT NULL CHECK (base_currency IN ('CDF', 'USD')),
    quote_currency TEXT NOT NULL CHECK (quote_currency IN ('CDF', 'USD')),
    rate NUMERIC(18,6) NOT NULL CHECK (rate > 0),
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT exchange_rates_distinct_currencies CHECK (base_currency <> quote_currency),
    CONSTRAINT exchange_rates_valid_window CHECK (valid_until IS NULL OR valid_until > valid_from)
);
CREATE INDEX IF NOT EXISTS exchange_rates_current_idx
    ON public.exchange_rates (base_currency, quote_currency, valid_from DESC)
    WHERE is_active;
ALTER TABLE public.exchange_rates ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.security_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    actor_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    success BOOLEAN NOT NULL,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.user_profiles
    ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.user_profiles
    WHERE id = auth.uid() AND is_active = true AND must_change_password = false
$$;

CREATE OR REPLACE FUNCTION public.has_role(VARIADIC p_roles public.user_role[])
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(public.current_user_role() = ANY(p_roles), false)
$$;

CREATE OR REPLACE FUNCTION public.customer_belongs_to_user(p_customer_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.customers
        WHERE id = p_customer_id AND user_id = auth.uid() AND is_active = true
    )
$$;

CREATE OR REPLACE FUNCTION public.write_audit_log(
    p_table_name TEXT,
    p_record_id UUID,
    p_action public.audit_action_type,
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'An authenticated audit actor is required' USING ERRCODE = '42501';
    END IF;
    INSERT INTO public.audit_logs(table_name, record_id, action_type, old_values, new_values, user_id)
    VALUES (p_table_name, p_record_id, p_action, p_old_values, p_new_values, p_user_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.validated_exchange_rate(
    p_currency TEXT,
    p_requested_rate NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rate NUMERIC;
    v_tolerance NUMERIC := 0.0001;
BEGIN
    IF p_currency NOT IN ('CDF', 'USD') THEN
        RAISE EXCEPTION 'Unsupported currency: %', p_currency USING ERRCODE = '22023';
    END IF;
    IF p_currency = 'CDF' THEN
        IF p_requested_rate IS NOT NULL AND abs(p_requested_rate - 1) > v_tolerance THEN
            RAISE EXCEPTION 'CDF exchange rate must be 1' USING ERRCODE = '22023';
        END IF;
        RETURN 1;
    END IF;

    SELECT rate INTO v_rate
    FROM public.exchange_rates
    WHERE base_currency = 'USD' AND quote_currency = 'CDF'
      AND is_active = true AND valid_from <= now()
      AND (valid_until IS NULL OR valid_until > now())
    ORDER BY valid_from DESC LIMIT 1;

    IF v_rate IS NULL THEN
        SELECT NULLIF(config_value, '')::NUMERIC INTO v_rate
        FROM public.system_configuration
        WHERE config_key = 'usd_cdf_exchange_rate';
    END IF;
    IF v_rate IS NULL OR v_rate <= 0 THEN
        RAISE EXCEPTION 'No active USD/CDF exchange rate configured' USING ERRCODE = '22023';
    END IF;
    IF p_requested_rate IS NOT NULL AND abs(p_requested_rate - v_rate) > greatest(v_tolerance, v_rate * 0.001) THEN
        RAISE EXCEPTION 'Stale or manipulated exchange rate' USING ERRCODE = '22023';
    END IF;
    RETURN v_rate;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_order_with_items(
    p_customer_id UUID,
    p_items JSONB,
    p_notes TEXT DEFAULT NULL,
    p_currency TEXT DEFAULT 'CDF',
    p_exchange_rate NUMERIC DEFAULT 1,
    p_payment_type TEXT DEFAULT 'cash',
    p_discount NUMERIC DEFAULT 0
)
RETURNS public.sales_orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_actor UUID := auth.uid();
    v_role public.user_role;
    v_order public.sales_orders%ROWTYPE;
    v_item JSONB;
    v_product public.products%ROWTYPE;
    v_quantity INTEGER;
    v_unit_price NUMERIC(12,2);
    v_client_price NUMERIC;
    v_line_total NUMERIC(12,2);
    v_subtotal NUMERIC(12,2) := 0;
    v_discount NUMERIC(12,2) := round(COALESCE(p_discount, 0), 2);
    v_max_discount_percent NUMERIC := 0;
    v_rate NUMERIC;
BEGIN
    SELECT role INTO v_role FROM public.user_profiles WHERE id = v_actor AND is_active = true;
    IF v_role IS NULL OR v_role NOT IN ('admin', 'sales_rep', 'b2b_customer') THEN
        RAISE EXCEPTION 'Role is not allowed to create orders' USING ERRCODE = '42501';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.customers WHERE id = p_customer_id AND is_active = true) THEN
        RAISE EXCEPTION 'Customer does not exist or is inactive' USING ERRCODE = '23503';
    END IF;
    IF v_role = 'b2b_customer' AND NOT public.customer_belongs_to_user(p_customer_id) THEN
        RAISE EXCEPTION 'Customers may only create their own orders' USING ERRCODE = '42501';
    END IF;
    IF p_payment_type NOT IN ('cash', 'credit') THEN
        RAISE EXCEPTION 'Invalid payment type' USING ERRCODE = '22023';
    END IF;
    IF p_items IS NULL OR jsonb_typeof(p_items) <> 'array' OR jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'At least one order item is required' USING ERRCODE = '22023';
    END IF;
    IF jsonb_array_length(p_items) > 500 THEN
        RAISE EXCEPTION 'Order item limit exceeded' USING ERRCODE = '54000';
    END IF;

    v_rate := public.validated_exchange_rate(p_currency, p_exchange_rate);

    FOR v_item IN SELECT value FROM jsonb_array_elements(p_items)
    LOOP
        BEGIN
            v_quantity := (v_item->>'quantity')::INTEGER;
        EXCEPTION WHEN OTHERS THEN
            RAISE EXCEPTION 'Each quantity must be an integer' USING ERRCODE = '22023';
        END;
        IF v_quantity IS NULL OR v_quantity <= 0 OR v_quantity > 100000 THEN
            RAISE EXCEPTION 'Invalid item quantity' USING ERRCODE = '22023';
        END IF;

        SELECT * INTO v_product FROM public.products
        WHERE id = (v_item->>'product_id')::UUID AND is_active = true
        FOR SHARE;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % does not exist or is inactive', v_item->>'product_id' USING ERRCODE = '23503';
        END IF;

        v_unit_price := round(CASE
            WHEN COALESCE(v_product.currency, 'CDF') = p_currency THEN v_product.unit_price
            WHEN v_product.currency = 'CDF' AND p_currency = 'USD' THEN v_product.unit_price / v_rate
            WHEN v_product.currency = 'USD' AND p_currency = 'CDF' THEN v_product.unit_price * v_rate
            ELSE NULL
        END, 2);
        IF v_unit_price IS NULL OR v_unit_price < 0 THEN
            RAISE EXCEPTION 'Cannot price product % in %', v_product.id, p_currency USING ERRCODE = '22023';
        END IF;

        IF v_item ? 'unit_price' THEN
            v_client_price := (v_item->>'unit_price')::NUMERIC;
            IF abs(v_client_price - v_unit_price) > 0.01 THEN
                RAISE EXCEPTION 'Price mismatch for product %', v_product.id USING ERRCODE = '22023';
            END IF;
        END IF;
        v_subtotal := v_subtotal + round(v_quantity * v_unit_price, 2);
    END LOOP;

    IF v_discount < 0 OR v_discount > v_subtotal THEN
        RAISE EXCEPTION 'Invalid discount amount' USING ERRCODE = '22023';
    END IF;
    IF v_role = 'admin' THEN
        v_max_discount_percent := 100;
    ELSIF v_role = 'sales_rep' THEN
        SELECT COALESCE(NULLIF(config_value, '')::NUMERIC, 10) INTO v_max_discount_percent
        FROM public.system_configuration WHERE config_key = 'sales_rep_max_discount_percent';
        v_max_discount_percent := COALESCE(v_max_discount_percent, 10);
    ELSE
        v_max_discount_percent := 0;
    END IF;
    IF v_subtotal > 0 AND (v_discount / v_subtotal * 100) > v_max_discount_percent THEN
        RAISE EXCEPTION 'Discount exceeds role limit of % percent', v_max_discount_percent USING ERRCODE = '42501';
    END IF;

    INSERT INTO public.sales_orders(
        order_number, customer_id, sales_rep_id, subtotal, tax_amount,
        discount_amount, total_amount, order_status, payment_status,
        notes, currency, exchange_rate, payment_type
    ) VALUES (
        public.generate_order_number(), p_customer_id,
        CASE WHEN v_role IN ('admin', 'sales_rep') THEN v_actor ELSE NULL END,
        v_subtotal, 0, v_discount, v_subtotal - v_discount,
        'pending', 'pending', NULLIF(btrim(p_notes), ''), p_currency, v_rate, p_payment_type
    ) RETURNING * INTO v_order;

    FOR v_item IN SELECT value FROM jsonb_array_elements(p_items)
    LOOP
        v_quantity := (v_item->>'quantity')::INTEGER;
        SELECT * INTO STRICT v_product FROM public.products
        WHERE id = (v_item->>'product_id')::UUID AND is_active = true;
        v_unit_price := round(CASE
            WHEN COALESCE(v_product.currency, 'CDF') = p_currency THEN v_product.unit_price
            WHEN v_product.currency = 'CDF' AND p_currency = 'USD' THEN v_product.unit_price / v_rate
            ELSE v_product.unit_price * v_rate
        END, 2);
        v_line_total := round(v_quantity * v_unit_price, 2);
        INSERT INTO public.order_items(order_id, product_id, quantity, unit_price, discount_percent, line_total)
        VALUES (v_order.id, v_product.id, v_quantity, v_unit_price, 0, v_line_total);
    END LOOP;

    PERFORM public.write_audit_log('sales_orders', v_order.id, 'insert', NULL,
        jsonb_build_object('operation', 'create_order_with_items', 'order_number', v_order.order_number,
            'customer_id', p_customer_id, 'subtotal', v_order.subtotal,
            'discount_amount', v_order.discount_amount, 'total_amount', v_order.total_amount,
            'currency', v_order.currency, 'item_count', jsonb_array_length(p_items)));
    RETURN v_order;
END;
$$;

CREATE OR REPLACE FUNCTION public.adjust_stock(
    p_product_id UUID,
    p_warehouse_id UUID,
    p_quantity_delta INTEGER,
    p_reason TEXT,
    p_reference_id UUID DEFAULT NULL,
    p_reference_type TEXT DEFAULT 'manual_adjustment'
)
RETURNS public.inventory_stock
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_stock public.inventory_stock%ROWTYPE;
    v_movement_id UUID;
BEGIN
    IF NOT public.has_role('admin', 'warehouse_staff') THEN
        RAISE EXCEPTION 'Insufficient stock permission' USING ERRCODE = '42501';
    END IF;
    IF p_quantity_delta = 0 OR p_reason IS NULL OR length(btrim(p_reason)) < 3 THEN
        RAISE EXCEPTION 'A non-zero quantity and reason are required' USING ERRCODE = '22023';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = p_product_id AND is_active) OR
       NOT EXISTS (SELECT 1 FROM public.warehouse_locations WHERE id = p_warehouse_id AND is_active) THEN
        RAISE EXCEPTION 'Invalid product or warehouse' USING ERRCODE = '23503';
    END IF;

    INSERT INTO public.inventory_stock(product_id, warehouse_id, quantity)
    VALUES (p_product_id, p_warehouse_id, 0)
    ON CONFLICT (product_id, warehouse_id) DO NOTHING;
    SELECT * INTO v_stock FROM public.inventory_stock
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id FOR UPDATE;
    IF v_stock.quantity + p_quantity_delta < 0 THEN
        RAISE EXCEPTION 'Insufficient stock' USING ERRCODE = '22003';
    END IF;
    INSERT INTO public.stock_movements(product_id, warehouse_id, movement_type, quantity,
        reference_id, reference_type, notes, created_by)
    VALUES (p_product_id, p_warehouse_id, 'adjustment', p_quantity_delta,
        p_reference_id, p_reference_type, btrim(p_reason), auth.uid()) RETURNING id INTO v_movement_id;
    SELECT * INTO v_stock FROM public.inventory_stock
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;
    IF v_stock.quantity < 0 THEN
        RAISE EXCEPTION 'Insufficient stock' USING ERRCODE = '22003';
    END IF;
    PERFORM public.write_audit_log('stock_movements', v_movement_id, 'insert', NULL,
        jsonb_build_object('operation', 'adjust_stock', 'delta', p_quantity_delta,
            'resulting_quantity', v_stock.quantity, 'reason', btrim(p_reason)));
    RETURN v_stock;
END;
$$;

CREATE OR REPLACE FUNCTION public.confirm_delivery(
    p_delivery_id UUID,
    p_signature_url TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS public.deliveries
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_delivery public.deliveries%ROWTYPE;
    v_order_status public.order_status;
BEGIN
    IF NOT public.has_role('admin', 'delivery_agent') THEN
        RAISE EXCEPTION 'Insufficient delivery permission' USING ERRCODE = '42501';
    END IF;
    SELECT * INTO v_delivery FROM public.deliveries WHERE id = p_delivery_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Delivery not found' USING ERRCODE = 'P0002'; END IF;
    IF v_delivery.status <> 'in_transit' THEN
        RAISE EXCEPTION 'Only in-transit deliveries can be confirmed' USING ERRCODE = '22023';
    END IF;
    IF public.current_user_role() = 'delivery_agent' AND NOT EXISTS (
        SELECT 1 FROM public.delivery_routes WHERE id = v_delivery.route_id AND driver_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Delivery is not assigned to this agent' USING ERRCODE = '42501';
    END IF;
    SELECT order_status INTO v_order_status FROM public.sales_orders WHERE id = v_delivery.order_id FOR UPDATE;
    IF v_order_status NOT IN ('confirmed', 'processing', 'shipped') THEN
        RAISE EXCEPTION 'Order status does not permit delivery confirmation' USING ERRCODE = '22023';
    END IF;
    UPDATE public.deliveries SET status = 'delivered', actual_delivery_time = now(),
        signature_url = COALESCE(p_signature_url, signature_url), notes = COALESCE(p_notes, notes), updated_at = now()
    WHERE id = p_delivery_id RETURNING * INTO v_delivery;
    UPDATE public.sales_orders SET order_status = 'delivered', updated_at = now() WHERE id = v_delivery.order_id;
    PERFORM public.write_audit_log('deliveries', v_delivery.id, 'update',
        jsonb_build_object('status', 'in_transit'), jsonb_build_object('operation', 'confirm_delivery', 'status', 'delivered'));
    RETURN v_delivery;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_payment(
    p_invoice_id UUID,
    p_amount NUMERIC,
    p_payment_method TEXT,
    p_reference_number TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_currency TEXT DEFAULT NULL
)
RETURNS public.payments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invoice public.invoices%ROWTYPE;
    v_payment public.payments%ROWTYPE;
    v_new_paid NUMERIC;
BEGIN
    IF NOT public.has_role('admin', 'comptable') THEN
        RAISE EXCEPTION 'Insufficient payment permission' USING ERRCODE = '42501';
    END IF;
    IF p_amount IS NULL OR p_amount <= 0 OR NULLIF(btrim(p_payment_method), '') IS NULL THEN
        RAISE EXCEPTION 'Positive amount and payment method are required' USING ERRCODE = '22023';
    END IF;
    SELECT * INTO v_invoice FROM public.invoices WHERE id = p_invoice_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Invoice not found' USING ERRCODE = 'P0002'; END IF;
    IF v_invoice.payment_status IN ('paid', 'refunded', 'failed') THEN
        RAISE EXCEPTION 'Invoice status does not accept payments' USING ERRCODE = '22023';
    END IF;
    IF COALESCE(p_currency, v_invoice.currency) <> v_invoice.currency THEN
        RAISE EXCEPTION 'Payment currency must match invoice currency' USING ERRCODE = '22023';
    END IF;
    v_new_paid := COALESCE(v_invoice.amount_paid, 0) + round(p_amount, 2);
    IF v_new_paid > v_invoice.total_amount THEN
        RAISE EXCEPTION 'Payment exceeds outstanding invoice amount' USING ERRCODE = '22003';
    END IF;
    INSERT INTO public.payments(invoice_id, amount, payment_method, reference_number, notes, currency)
    VALUES (p_invoice_id, round(p_amount, 2), btrim(p_payment_method), NULLIF(btrim(p_reference_number), ''),
        NULLIF(btrim(p_notes), ''), v_invoice.currency) RETURNING * INTO v_payment;
    UPDATE public.invoices SET amount_paid = v_new_paid,
        payment_status = CASE WHEN v_new_paid = total_amount THEN 'paid'::public.payment_status ELSE 'partial'::public.payment_status END
    WHERE id = p_invoice_id;
    UPDATE public.sales_orders SET payment_status = CASE WHEN v_new_paid = v_invoice.total_amount THEN 'paid'::public.payment_status ELSE 'partial'::public.payment_status END,
        updated_at = now() WHERE id = v_invoice.order_id;
    PERFORM public.write_audit_log('payments', v_payment.id, 'insert', NULL,
        jsonb_build_object('operation', 'record_payment', 'invoice_id', p_invoice_id,
            'amount', v_payment.amount, 'currency', v_payment.currency, 'reference_number', v_payment.reference_number));
    RETURN v_payment;
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_order_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF NEW.order_status IS DISTINCT FROM OLD.order_status AND NOT (
        (OLD.order_status = 'pending' AND NEW.order_status IN ('confirmed', 'cancelled')) OR
        (OLD.order_status = 'confirmed' AND NEW.order_status IN ('processing', 'cancelled')) OR
        (OLD.order_status = 'processing' AND NEW.order_status IN ('shipped', 'cancelled')) OR
        (OLD.order_status = 'shipped' AND NEW.order_status IN ('delivered', 'cancelled'))
    ) THEN
        RAISE EXCEPTION 'Invalid order status transition: % -> %', OLD.order_status, NEW.order_status USING ERRCODE = '22023';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS enforce_order_status_transition_trigger ON public.sales_orders;
CREATE TRIGGER enforce_order_status_transition_trigger BEFORE UPDATE OF order_status ON public.sales_orders
FOR EACH ROW EXECUTE FUNCTION public.enforce_order_status_transition();

-- Critical writes must use audited RPCs.
REVOKE INSERT ON public.sales_orders, public.order_items FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.stock_movements FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.payments FROM authenticated;
GRANT EXECUTE ON FUNCTION public.create_order_with_items(UUID, JSONB, TEXT, TEXT, NUMERIC, TEXT, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.adjust_stock(UUID, UUID, INTEGER, TEXT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_delivery(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_payment(UUID, NUMERIC, TEXT, TEXT, TEXT, TEXT) TO authenticated;
REVOKE ALL ON FUNCTION public.write_audit_log(TEXT, UUID, public.audit_action_type, JSONB, JSONB, UUID) FROM PUBLIC, authenticated;
REVOKE ALL ON FUNCTION public.validated_exchange_rate(TEXT, NUMERIC) FROM PUBLIC, authenticated;

-- Replace accumulated permissive policies on the reviewed tables with an explicit matrix.
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT schemaname, tablename, policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = ANY(ARRAY[
      'user_profiles','customers','sales_orders','order_items','products','stock_movements',
      'purchases','expenses','document_attachments','deliveries','payments','exchange_rates','security_events'
    ])
  LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', r.policyname, r.schemaname, r.tablename); END LOOP;
END $$;

CREATE POLICY user_profiles_read ON public.user_profiles FOR SELECT TO authenticated
USING (id = auth.uid() OR public.has_role('admin'));
CREATE POLICY user_profiles_self_update ON public.user_profiles FOR UPDATE TO authenticated
USING (id = auth.uid() OR public.has_role('admin')) WITH CHECK (id = auth.uid() OR public.has_role('admin'));

CREATE POLICY customers_staff_read ON public.customers FOR SELECT TO authenticated
USING (public.has_role('admin','sales_rep','comptable','warehouse_staff','acheteur','delivery_agent') OR user_id = auth.uid());
CREATE POLICY customers_sales_manage ON public.customers FOR ALL TO authenticated
USING (public.has_role('admin','sales_rep')) WITH CHECK (public.has_role('admin','sales_rep'));

CREATE POLICY products_authenticated_read ON public.products FOR SELECT TO authenticated USING (is_active OR public.has_role('admin','warehouse_staff'));
CREATE POLICY products_admin_manage ON public.products FOR ALL TO authenticated
USING (public.has_role('admin')) WITH CHECK (public.has_role('admin'));

CREATE POLICY sales_orders_read ON public.sales_orders FOR SELECT TO authenticated
USING (public.has_role('admin','sales_rep','warehouse_staff','comptable','delivery_agent') OR public.customer_belongs_to_user(customer_id));
CREATE POLICY sales_orders_staff_update ON public.sales_orders FOR UPDATE TO authenticated
USING (public.has_role('admin','sales_rep','warehouse_staff')) WITH CHECK (public.has_role('admin','sales_rep','warehouse_staff'));
CREATE POLICY order_items_read ON public.order_items FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.sales_orders so WHERE so.id = order_id AND
    (public.has_role('admin','sales_rep','warehouse_staff','comptable','delivery_agent') OR public.customer_belongs_to_user(so.customer_id))));

CREATE POLICY stock_movements_read ON public.stock_movements FOR SELECT TO authenticated
USING (public.has_role('admin','warehouse_staff','comptable'));
CREATE POLICY purchases_read ON public.purchases FOR SELECT TO authenticated
USING (public.has_role('admin','acheteur','comptable','warehouse_staff'));
CREATE POLICY purchases_manage ON public.purchases FOR ALL TO authenticated
USING (public.has_role('admin','acheteur')) WITH CHECK (public.has_role('admin','acheteur'));
CREATE POLICY expenses_read ON public.expenses FOR SELECT TO authenticated
USING (public.has_role('admin','comptable') OR requested_by = auth.uid() OR created_by = auth.uid());
CREATE POLICY expenses_create ON public.expenses FOR INSERT TO authenticated
WITH CHECK (requested_by = auth.uid() OR created_by = auth.uid());
CREATE POLICY expenses_finance_manage ON public.expenses FOR UPDATE TO authenticated
USING (public.has_role('admin','comptable') OR requested_by = auth.uid())
WITH CHECK (public.has_role('admin','comptable') OR requested_by = auth.uid());

CREATE POLICY documents_read ON public.document_attachments FOR SELECT TO authenticated
USING (uploaded_by = auth.uid() OR public.has_role('admin','sales_rep','warehouse_staff','comptable','acheteur','delivery_agent'));
CREATE POLICY documents_create ON public.document_attachments FOR INSERT TO authenticated WITH CHECK (uploaded_by = auth.uid());
CREATE POLICY documents_owner_manage ON public.document_attachments FOR UPDATE TO authenticated
USING (uploaded_by = auth.uid() OR public.has_role('admin')) WITH CHECK (uploaded_by = auth.uid() OR public.has_role('admin'));
CREATE POLICY documents_owner_delete ON public.document_attachments FOR DELETE TO authenticated
USING (uploaded_by = auth.uid() OR public.has_role('admin'));

CREATE POLICY deliveries_read ON public.deliveries FOR SELECT TO authenticated
USING (public.has_role('admin','sales_rep','warehouse_staff','delivery_agent') OR EXISTS (
    SELECT 1 FROM public.sales_orders so WHERE so.id = order_id AND public.customer_belongs_to_user(so.customer_id)));
CREATE POLICY deliveries_manage ON public.deliveries FOR ALL TO authenticated
USING (public.has_role('admin','warehouse_staff')) WITH CHECK (public.has_role('admin','warehouse_staff'));
CREATE POLICY payments_read ON public.payments FOR SELECT TO authenticated
USING (public.has_role('admin','comptable') OR EXISTS (
    SELECT 1 FROM public.invoices i JOIN public.customers c ON c.id = i.customer_id
    WHERE i.id = invoice_id AND c.user_id = auth.uid()));
CREATE POLICY exchange_rates_read ON public.exchange_rates FOR SELECT TO authenticated USING (is_active OR public.has_role('admin'));
CREATE POLICY exchange_rates_admin_manage ON public.exchange_rates FOR ALL TO authenticated
USING (public.has_role('admin')) WITH CHECK (public.has_role('admin'));
CREATE POLICY security_events_admin_read ON public.security_events FOR SELECT TO authenticated USING (public.has_role('admin'));

INSERT INTO public.system_configuration(config_key, config_value, config_type, description, category)
VALUES
 ('sales_rep_max_discount_percent', '10', 'number', 'Maximum order discount percentage for sales representatives', 'sales'),
 ('bootstrap_admin_enabled', 'true', 'boolean', 'Must be disabled immediately after initial administrator bootstrap', 'security')
ON CONFLICT (config_key) DO NOTHING;
