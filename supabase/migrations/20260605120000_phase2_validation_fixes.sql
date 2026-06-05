-- Phase 2 validation fixes: close privilege gaps and align Flutter-facing RPCs.

-- Preserve pre-RPC stock as a baseline ledger entry. Without this reconciliation,
-- the first movement would replace seeded/legacy inventory with only the new delta.
INSERT INTO public.stock_movements (
    product_id, warehouse_id, movement_type, quantity,
    reference_type, notes, created_by
)
SELECT
    inventory.product_id,
    inventory.warehouse_id,
    'adjustment'::public.stock_movement_type,
    inventory.quantity - COALESCE(ledger.quantity, 0),
    'migration_reconciliation',
    'Phase 2 baseline reconciliation from inventory_stock',
    NULL
FROM public.inventory_stock AS inventory
LEFT JOIN (
    SELECT
        product_id,
        warehouse_id,
        SUM(CASE movement_type
            WHEN 'in' THEN quantity
            WHEN 'return' THEN quantity
            WHEN 'out' THEN -quantity
            WHEN 'adjustment' THEN quantity
            ELSE 0
        END)::INTEGER AS quantity
    FROM public.stock_movements
    GROUP BY product_id, warehouse_id
) AS ledger
    ON ledger.product_id = inventory.product_id
   AND ledger.warehouse_id = inventory.warehouse_id
WHERE inventory.quantity <> COALESCE(ledger.quantity, 0);

-- Automatic audit triggers must tolerate migrations/seeds where auth.uid() is
-- intentionally absent. Critical RPCs still require an explicit authenticated actor.
CREATE OR REPLACE FUNCTION public.log_audit_trail()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    IF TG_OP = 'DELETE' THEN
        INSERT INTO public.audit_logs(table_name, record_id, action_type, old_values, user_id)
        VALUES (TG_TABLE_NAME, OLD.id, 'delete', to_jsonb(OLD), auth.uid());
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.audit_logs(table_name, record_id, action_type, old_values, new_values, user_id)
        VALUES (TG_TABLE_NAME, NEW.id, 'update', to_jsonb(OLD), to_jsonb(NEW), auth.uid());
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO public.audit_logs(table_name, record_id, action_type, new_values, user_id)
        VALUES (TG_TABLE_NAME, NEW.id, 'insert', to_jsonb(NEW), auth.uid());
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$;

-- Make every legacy role helper honor inactive accounts and the first-login gate.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT public.current_user_role() = 'admin'::public.user_role $$;
CREATE OR REPLACE FUNCTION public.is_sales_rep()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT public.current_user_role() = 'sales_rep'::public.user_role $$;
CREATE OR REPLACE FUNCTION public.is_warehouse_staff()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT public.current_user_role() = 'warehouse_staff'::public.user_role $$;
CREATE OR REPLACE FUNCTION public.is_b2b_customer()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT public.current_user_role() = 'b2b_customer'::public.user_role $$;
CREATE OR REPLACE FUNCTION public.is_comptable()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT public.current_user_role() = 'comptable'::public.user_role $$;
CREATE OR REPLACE FUNCTION public.is_acheteur()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT public.current_user_role() = 'acheteur'::public.user_role $$;
CREATE OR REPLACE FUNCTION public.is_delivery_agent()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$ SELECT public.current_user_role() = 'delivery_agent'::public.user_role $$;

-- Completing first-login setup is only possible once Supabase Auth contains a
-- password hash. The profile flag cannot be cleared through a direct table update.
CREATE OR REPLACE FUNCTION public.complete_password_setup()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_has_password BOOLEAN;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    SELECT COALESCE(length(encrypted_password), 0) > 0
    INTO v_has_password
    FROM auth.users
    WHERE id = auth.uid();

    IF NOT COALESCE(v_has_password, false) THEN
        RAISE EXCEPTION 'A password must be configured before completing setup'
            USING ERRCODE = '42501';
    END IF;

    PERFORM set_config('app.password_setup_verified', 'true', true);
    UPDATE public.user_profiles
    SET must_change_password = false,
        updated_at = now()
    WHERE id = auth.uid()
      AND must_change_password = true;

    RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION public.prevent_profile_privilege_escalation()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    IF auth.uid() = OLD.id THEN
        IF NOT public.is_admin() AND NEW.role IS DISTINCT FROM OLD.role THEN
            RAISE EXCEPTION 'Users cannot modify their own role';
        END IF;
        IF NOT public.is_admin() AND NEW.is_active IS DISTINCT FROM OLD.is_active THEN
            RAISE EXCEPTION 'Users cannot modify their own active status';
        END IF;
        IF NEW.must_change_password IS DISTINCT FROM OLD.must_change_password
           AND COALESCE(current_setting('app.password_setup_verified', true), '') <> 'true' THEN
            RAISE EXCEPTION 'Password setup status can only be changed by the verification RPC';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- Status changes use a single audited path. This also prevents direct updates of
-- financial columns on sales_orders by otherwise authorized operational roles.
CREATE OR REPLACE FUNCTION public.transition_order_status(
    p_order_id UUID,
    p_new_status public.order_status,
    p_reason TEXT DEFAULT NULL
)
RETURNS public.sales_orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_order public.sales_orders%ROWTYPE;
    v_role public.user_role;
    v_old_status public.order_status;
BEGIN
    v_role := public.current_user_role();
    SELECT * INTO v_order
    FROM public.sales_orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order not found' USING ERRCODE = 'P0002';
    END IF;

    v_old_status := v_order.order_status;

    IF v_role IN ('admin', 'warehouse_staff') THEN
        NULL;
    ELSIF v_role = 'sales_rep' AND (
        v_order.sales_rep_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.customers c
            WHERE c.id = v_order.customer_id
              AND c.commercial_id = auth.uid()
        )
    ) THEN
        NULL;
    ELSIF v_role = 'b2b_customer'
          AND p_new_status = 'cancelled'
          AND v_order.order_status = 'pending'
          AND public.customer_belongs_to_user(v_order.customer_id) THEN
        NULL;
    ELSE
        RAISE EXCEPTION 'Insufficient order status permission' USING ERRCODE = '42501';
    END IF;

    UPDATE public.sales_orders
    SET order_status = p_new_status,
        notes = CASE
            WHEN NULLIF(btrim(p_reason), '') IS NULL THEN notes
            WHEN notes IS NULL OR notes = '' THEN btrim(p_reason)
            ELSE notes || E'\n' || btrim(p_reason)
        END,
        updated_at = now()
    WHERE id = p_order_id
    RETURNING * INTO v_order;

    PERFORM public.write_audit_log(
        'sales_orders',
        v_order.id,
        'update',
        jsonb_build_object('order_status', v_old_status),
        jsonb_build_object(
            'operation', 'transition_order_status',
            'order_status', p_new_status,
            'reason', NULLIF(btrim(p_reason), '')
        )
    );
    RETURN v_order;
END;
$$;

-- Delivery confirmation must agree with the global order transition state machine.
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

    SELECT * INTO v_delivery
    FROM public.deliveries
    WHERE id = p_delivery_id
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Delivery not found' USING ERRCODE = 'P0002';
    END IF;
    IF v_delivery.status <> 'in_transit' THEN
        RAISE EXCEPTION 'Only in-transit deliveries can be confirmed' USING ERRCODE = '22023';
    END IF;
    IF public.current_user_role() = 'delivery_agent' AND NOT EXISTS (
        SELECT 1
        FROM public.delivery_routes
        WHERE id = v_delivery.route_id
          AND driver_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Delivery is not assigned to this agent' USING ERRCODE = '42501';
    END IF;

    SELECT order_status INTO v_order_status
    FROM public.sales_orders
    WHERE id = v_delivery.order_id
    FOR UPDATE;
    IF v_order_status <> 'shipped' THEN
        RAISE EXCEPTION 'Only shipped orders can be delivered' USING ERRCODE = '22023';
    END IF;

    UPDATE public.deliveries
    SET status = 'delivered',
        actual_delivery_time = now(),
        signature_url = COALESCE(NULLIF(btrim(p_signature_url), ''), signature_url),
        notes = COALESCE(NULLIF(btrim(p_notes), ''), notes),
        updated_at = now()
    WHERE id = p_delivery_id
    RETURNING * INTO v_delivery;

    UPDATE public.sales_orders
    SET order_status = 'delivered',
        updated_at = now()
    WHERE id = v_delivery.order_id;

    PERFORM public.write_audit_log(
        'deliveries',
        v_delivery.id,
        'update',
        jsonb_build_object('status', 'in_transit'),
        jsonb_build_object('operation', 'confirm_delivery', 'status', 'delivered')
    );
    RETURN v_delivery;
END;
$$;

REVOKE ALL ON FUNCTION public.create_order_with_items(UUID, JSONB, TEXT, TEXT, NUMERIC, TEXT, NUMERIC) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.adjust_stock(UUID, UUID, INTEGER, TEXT, UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.confirm_delivery(UUID, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.record_payment(UUID, NUMERIC, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.complete_password_setup() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.transition_order_status(UUID, public.order_status, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_order_with_items(UUID, JSONB, TEXT, TEXT, NUMERIC, TEXT, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.adjust_stock(UUID, UUID, INTEGER, TEXT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_delivery(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_payment(UUID, NUMERIC, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_password_setup() TO authenticated;
GRANT EXECUTE ON FUNCTION public.transition_order_status(UUID, public.order_status, TEXT) TO authenticated;
REVOKE UPDATE ON public.sales_orders FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.inventory_stock FROM authenticated;
REVOKE UPDATE, DELETE ON public.deliveries FROM authenticated;


CREATE OR REPLACE FUNCTION public.enforce_order_customer_scope()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.current_user_role() = 'sales_rep' AND NOT EXISTS (
        SELECT 1 FROM public.customers
        WHERE id = NEW.customer_id
          AND commercial_id = auth.uid()
          AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Sales representatives may only order for assigned customers'
            USING ERRCODE = '42501';
    END IF;
    IF public.current_user_role() = 'b2b_customer'
       AND NOT public.customer_belongs_to_user(NEW.customer_id) THEN
        RAISE EXCEPTION 'Customers may only order for their own account'
            USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS enforce_order_customer_scope_trigger ON public.sales_orders;
CREATE TRIGGER enforce_order_customer_scope_trigger
BEFORE INSERT ON public.sales_orders
FOR EACH ROW EXECUTE FUNCTION public.enforce_order_customer_scope();

CREATE OR REPLACE FUNCTION public.assign_sales_rep_to_new_customer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF public.current_user_role() = 'sales_rep' AND NEW.commercial_id IS NULL THEN
        NEW.commercial_id := auth.uid();
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS assign_sales_rep_to_new_customer_trigger ON public.customers;
CREATE TRIGGER assign_sales_rep_to_new_customer_trigger
BEFORE INSERT ON public.customers
FOR EACH ROW EXECUTE FUNCTION public.assign_sales_rep_to_new_customer();

-- Product cost is confidential. PostgREST callers receive only catalog columns;
-- internal SECURITY DEFINER reporting functions retain access to cost_price.
REVOKE SELECT ON public.products FROM authenticated;
GRANT SELECT (
    id, sku, name, description, category_id, unit_price, image_url,
    barcode, is_active, created_at, updated_at, currency
) ON public.products TO authenticated;

CREATE OR REPLACE FUNCTION public.can_read_customer(p_customer_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.customers c
        WHERE c.id = p_customer_id
          AND (
              public.current_user_role() IN ('admin', 'warehouse_staff', 'comptable', 'acheteur')
              OR c.user_id = auth.uid()
              OR (public.current_user_role() = 'sales_rep' AND c.commercial_id = auth.uid())
              OR (
                  public.current_user_role() = 'delivery_agent'
                  AND EXISTS (
                      SELECT 1
                      FROM public.sales_orders so
                      JOIN public.deliveries d ON d.order_id = so.id
                      JOIN public.delivery_routes dr ON dr.id = d.route_id
                      WHERE so.customer_id = c.id
                        AND dr.driver_id = auth.uid()
                  )
              )
          )
    )
$$;

CREATE OR REPLACE FUNCTION public.can_read_order(p_order_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.sales_orders so
        JOIN public.customers c ON c.id = so.customer_id
        WHERE so.id = p_order_id
          AND (
              public.current_user_role() IN ('admin', 'warehouse_staff', 'comptable')
              OR c.user_id = auth.uid()
              OR (
                  public.current_user_role() = 'sales_rep'
                  AND (so.sales_rep_id = auth.uid() OR c.commercial_id = auth.uid())
              )
              OR (
                  public.current_user_role() = 'delivery_agent'
                  AND EXISTS (
                      SELECT 1
                      FROM public.deliveries d
                      JOIN public.delivery_routes dr ON dr.id = d.route_id
                      WHERE d.order_id = so.id
                        AND dr.driver_id = auth.uid()
                  )
              )
          )
    )
$$;

CREATE OR REPLACE FUNCTION public.can_read_delivery(p_delivery_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.deliveries d
        JOIN public.sales_orders so ON so.id = d.order_id
        JOIN public.customers c ON c.id = so.customer_id
        LEFT JOIN public.delivery_routes dr ON dr.id = d.route_id
        WHERE d.id = p_delivery_id
          AND (
              public.current_user_role() IN ('admin', 'warehouse_staff')
              OR c.user_id = auth.uid()
              OR (public.current_user_role() = 'sales_rep' AND c.commercial_id = auth.uid())
              OR (public.current_user_role() = 'delivery_agent' AND dr.driver_id = auth.uid())
          )
    )
$$;

CREATE OR REPLACE FUNCTION public.can_access_document_entity(
    p_entity_type public.attachment_entity_type,
    p_entity_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT CASE
        WHEN public.current_user_role() = 'admin' THEN true
        WHEN p_entity_type = 'customer' THEN EXISTS (
            SELECT 1 FROM public.customers c
            WHERE c.id = p_entity_id
              AND (
                  c.user_id = auth.uid()
                  OR (public.current_user_role() = 'sales_rep' AND c.commercial_id = auth.uid())
                  OR public.current_user_role() IN ('warehouse_staff', 'comptable', 'acheteur')
              )
        )
        WHEN p_entity_type = 'invoice' THEN EXISTS (
            SELECT 1 FROM public.invoices i
            JOIN public.customers c ON c.id = i.customer_id
            WHERE i.id = p_entity_id
              AND (
                  c.user_id = auth.uid()
                  OR public.current_user_role() = 'comptable'
                  OR (public.current_user_role() = 'sales_rep' AND c.commercial_id = auth.uid())
              )
        )
        WHEN p_entity_type = 'delivery' THEN EXISTS (
            SELECT 1
            FROM public.deliveries d
            JOIN public.sales_orders so ON so.id = d.order_id
            JOIN public.customers c ON c.id = so.customer_id
            LEFT JOIN public.delivery_routes dr ON dr.id = d.route_id
            WHERE d.id = p_entity_id
              AND (
                  c.user_id = auth.uid()
                  OR public.current_user_role() = 'warehouse_staff'
                  OR (public.current_user_role() = 'sales_rep' AND c.commercial_id = auth.uid())
                  OR (public.current_user_role() = 'delivery_agent' AND dr.driver_id = auth.uid())
              )
        )
        WHEN p_entity_type = 'expense' THEN public.current_user_role() = 'comptable'
            AND EXISTS (SELECT 1 FROM public.expenses e WHERE e.id = p_entity_id)
        WHEN p_entity_type = 'purchase_order' THEN public.current_user_role() IN ('acheteur', 'comptable', 'warehouse_staff')
            AND EXISTS (SELECT 1 FROM public.purchases p WHERE p.id = p_entity_id)
        ELSE false
    END
$$;

-- Replace inherited policies that remained broader than the documented matrix.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = ANY(ARRAY[
              'inventory_stock', 'suppliers', 'purchase_items', 'invoices',
              'delivery_routes'
          ])
    LOOP
        EXECUTE format(
            'DROP POLICY IF EXISTS %I ON %I.%I',
            r.policyname,
            r.schemaname,
            r.tablename
        );
    END LOOP;
END $$;

DROP POLICY IF EXISTS customers_staff_read ON public.customers;
DROP POLICY IF EXISTS customers_sales_manage ON public.customers;
DROP POLICY IF EXISTS sales_orders_read ON public.sales_orders;
DROP POLICY IF EXISTS sales_orders_staff_update ON public.sales_orders;
DROP POLICY IF EXISTS order_items_read ON public.order_items;
DROP POLICY IF EXISTS deliveries_read ON public.deliveries;
DROP POLICY IF EXISTS deliveries_manage ON public.deliveries;
DROP POLICY IF EXISTS documents_read ON public.document_attachments;
DROP POLICY IF EXISTS documents_create ON public.document_attachments;
DROP POLICY IF EXISTS documents_owner_manage ON public.document_attachments;
DROP POLICY IF EXISTS documents_owner_delete ON public.document_attachments;
DROP POLICY IF EXISTS expenses_read ON public.expenses;
DROP POLICY IF EXISTS expenses_create ON public.expenses;
DROP POLICY IF EXISTS expenses_finance_manage ON public.expenses;

CREATE POLICY expenses_read
ON public.expenses
FOR SELECT TO authenticated
USING (
    public.has_role('admin', 'comptable')
    OR (
        public.current_user_role() IN ('sales_rep', 'warehouse_staff', 'acheteur', 'delivery_agent')
        AND (requested_by = auth.uid() OR created_by = auth.uid())
    )
);
CREATE POLICY expenses_create
ON public.expenses
FOR INSERT TO authenticated
WITH CHECK (
    public.current_user_role() IN ('admin', 'sales_rep', 'warehouse_staff', 'comptable', 'acheteur', 'delivery_agent')
    AND (requested_by = auth.uid() OR created_by = auth.uid())
);
CREATE POLICY expenses_finance_manage
ON public.expenses
FOR UPDATE TO authenticated
USING (
    public.has_role('admin', 'comptable')
    OR (
        public.current_user_role() IN ('sales_rep', 'warehouse_staff', 'acheteur', 'delivery_agent')
        AND requested_by = auth.uid()
    )
)
WITH CHECK (
    public.has_role('admin', 'comptable')
    OR (
        public.current_user_role() IN ('sales_rep', 'warehouse_staff', 'acheteur', 'delivery_agent')
        AND requested_by = auth.uid()
    )
);

CREATE POLICY inventory_stock_read
ON public.inventory_stock
FOR SELECT TO authenticated
USING (public.has_role('admin', 'sales_rep', 'warehouse_staff', 'comptable'));

CREATE POLICY suppliers_procurement_read
ON public.suppliers
FOR SELECT TO authenticated
USING (public.has_role('admin', 'acheteur', 'comptable'));
CREATE POLICY suppliers_procurement_manage
ON public.suppliers
FOR ALL TO authenticated
USING (public.has_role('admin', 'acheteur'))
WITH CHECK (public.has_role('admin', 'acheteur'));

CREATE POLICY purchase_items_procurement_read
ON public.purchase_items
FOR SELECT TO authenticated
USING (public.has_role('admin', 'acheteur', 'comptable', 'warehouse_staff'));
CREATE POLICY purchase_items_procurement_manage
ON public.purchase_items
FOR ALL TO authenticated
USING (public.has_role('admin', 'acheteur'))
WITH CHECK (public.has_role('admin', 'acheteur'));

CREATE POLICY invoices_finance_read
ON public.invoices
FOR SELECT TO authenticated
USING (
    public.has_role('admin', 'comptable')
    OR (
        public.current_user_role() = 'sales_rep'
        AND EXISTS (
            SELECT 1 FROM public.customers c
            WHERE c.id = customer_id
              AND c.commercial_id = auth.uid()
        )
    )
    OR EXISTS (
        SELECT 1 FROM public.customers c
        WHERE c.id = customer_id
          AND c.user_id = auth.uid()
    )
);
CREATE POLICY invoices_admin_manage
ON public.invoices
FOR ALL TO authenticated
USING (public.has_role('admin'))
WITH CHECK (public.has_role('admin'));

CREATE POLICY delivery_routes_read
ON public.delivery_routes
FOR SELECT TO authenticated
USING (
    public.has_role('admin', 'sales_rep', 'warehouse_staff')
    OR (public.current_user_role() = 'delivery_agent' AND driver_id = auth.uid())
);
CREATE POLICY delivery_routes_manage
ON public.delivery_routes
FOR ALL TO authenticated
USING (public.has_role('admin', 'warehouse_staff'))
WITH CHECK (public.has_role('admin', 'warehouse_staff'));

CREATE POLICY customers_staff_read
ON public.customers
FOR SELECT TO authenticated
USING (public.can_read_customer(id));

CREATE POLICY customers_sales_manage
ON public.customers
FOR ALL TO authenticated
USING (
    public.has_role('admin')
    OR (public.current_user_role() = 'sales_rep' AND commercial_id = auth.uid())
)
WITH CHECK (
    public.has_role('admin')
    OR (public.current_user_role() = 'sales_rep' AND commercial_id = auth.uid())
);

CREATE POLICY sales_orders_read
ON public.sales_orders
FOR SELECT TO authenticated
USING (public.can_read_order(id));

CREATE POLICY order_items_read
ON public.order_items
FOR SELECT TO authenticated
USING (public.can_read_order(order_id));

CREATE POLICY deliveries_read
ON public.deliveries
FOR SELECT TO authenticated
USING (public.can_read_delivery(id));

CREATE POLICY deliveries_manage
ON public.deliveries
FOR INSERT TO authenticated
WITH CHECK (public.has_role('admin', 'warehouse_staff'));

CREATE POLICY documents_read
ON public.document_attachments
FOR SELECT TO authenticated
USING (
    uploaded_by = auth.uid()
    OR public.can_access_document_entity(entity_type, entity_id)
);
CREATE POLICY documents_create
ON public.document_attachments
FOR INSERT TO authenticated
WITH CHECK (
    uploaded_by = auth.uid()
    AND public.can_access_document_entity(entity_type, entity_id)
);
CREATE POLICY documents_owner_manage
ON public.document_attachments
FOR UPDATE TO authenticated
USING (uploaded_by = auth.uid() OR public.current_user_role() = 'admin')
WITH CHECK (
    (uploaded_by = auth.uid() OR public.current_user_role() = 'admin')
    AND public.can_access_document_entity(entity_type, entity_id)
);
CREATE POLICY documents_owner_delete
ON public.document_attachments
FOR DELETE TO authenticated
USING (uploaded_by = auth.uid() OR public.current_user_role() = 'admin');

COMMENT ON FUNCTION public.complete_password_setup() IS
'Clears must_change_password only after Supabase Auth has a password hash.';
COMMENT ON FUNCTION public.transition_order_status(UUID, public.order_status, TEXT) IS
'Audited and role-checked sales order state transition.';
