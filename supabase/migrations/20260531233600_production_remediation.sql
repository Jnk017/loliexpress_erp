-- ============================================================================
-- Production remediation: security, RLS, numbering, stock sync, support tickets
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Auth/profile hardening
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role, phone, company_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        'b2b_customer'::public.user_role,
        NEW.raw_user_meta_data->>'phone',
        NEW.raw_user_meta_data->>'company_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.prevent_profile_privilege_escalation()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    IF auth.uid() = OLD.id AND NOT public.is_admin() THEN
        IF NEW.role IS DISTINCT FROM OLD.role THEN
            RAISE EXCEPTION 'Users cannot modify their own role';
        END IF;
        IF NEW.is_active IS DISTINCT FROM OLD.is_active THEN
            RAISE EXCEPTION 'Users cannot modify their own active status';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_prevent_profile_privilege_escalation ON public.user_profiles;
CREATE TRIGGER trigger_prevent_profile_privilege_escalation
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_profile_privilege_escalation();

DROP POLICY IF EXISTS "users_update_own_profile" ON public.user_profiles;
CREATE POLICY "users_update_own_profile"
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- ---------------------------------------------------------------------------
-- Restrictive RLS for procurement, configuration, workflows and notifications
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_comptable()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'comptable' AND is_active = true
    );
$$;

CREATE OR REPLACE FUNCTION public.is_acheteur()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'acheteur' AND is_active = true
    );
$$;

CREATE OR REPLACE FUNCTION public.can_read_procurement()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT public.is_admin() OR public.is_acheteur() OR public.is_comptable()
$$;

DROP POLICY IF EXISTS "suppliers_admin_all" ON public.suppliers;
DROP POLICY IF EXISTS "suppliers_all" ON public.suppliers;
DROP POLICY IF EXISTS "suppliers_read" ON public.suppliers;
DROP POLICY IF EXISTS "suppliers_admin_acheteur_manage" ON public.suppliers;
CREATE POLICY "suppliers_admin_acheteur_manage"
ON public.suppliers
FOR ALL TO authenticated
USING (public.is_admin() OR public.is_acheteur())
WITH CHECK (public.is_admin() OR public.is_acheteur());
CREATE POLICY "suppliers_procurement_read"
ON public.suppliers
FOR SELECT TO authenticated
USING (public.can_read_procurement());

DROP POLICY IF EXISTS "purchases_admin_all" ON public.purchases;
DROP POLICY IF EXISTS "purchases_all" ON public.purchases;
DROP POLICY IF EXISTS "purchases_read" ON public.purchases;
DROP POLICY IF EXISTS "purchases_admin_acheteur_manage" ON public.purchases;
CREATE POLICY "purchases_admin_acheteur_manage"
ON public.purchases
FOR ALL TO authenticated
USING (public.is_admin() OR public.is_acheteur())
WITH CHECK (public.is_admin() OR public.is_acheteur());
CREATE POLICY "purchases_procurement_read"
ON public.purchases
FOR SELECT TO authenticated
USING (public.can_read_procurement());

DROP POLICY IF EXISTS "purchase_items_admin_all" ON public.purchase_items;
DROP POLICY IF EXISTS "purchase_items_all" ON public.purchase_items;
DROP POLICY IF EXISTS "purchase_items_read" ON public.purchase_items;
DROP POLICY IF EXISTS "purchase_items_admin_acheteur_manage" ON public.purchase_items;
CREATE POLICY "purchase_items_admin_acheteur_manage"
ON public.purchase_items
FOR ALL TO authenticated
USING (public.is_admin() OR public.is_acheteur())
WITH CHECK (public.is_admin() OR public.is_acheteur());
CREATE POLICY "purchase_items_procurement_read"
ON public.purchase_items
FOR SELECT TO authenticated
USING (public.can_read_procurement());

DROP POLICY IF EXISTS "users_view_system_config" ON public.system_configuration;
DROP POLICY IF EXISTS "users_view_workflow_states" ON public.workflow_states;
DROP POLICY IF EXISTS "users_create_workflow_states" ON public.workflow_states;

DROP POLICY IF EXISTS "users_create_own_notifications" ON public.notification_queue;
CREATE POLICY "users_create_own_notifications"
ON public.notification_queue
FOR INSERT TO authenticated
WITH CHECK (recipient_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "users_update_own_notifications" ON public.notification_queue;
CREATE POLICY "users_update_own_notifications"
ON public.notification_queue
FOR UPDATE TO authenticated
USING (recipient_id = auth.uid())
WITH CHECK (recipient_id = auth.uid());

DROP POLICY IF EXISTS "failed_login_service_insert" ON public.failed_login_attempts;
CREATE POLICY "failed_login_service_insert"
ON public.failed_login_attempts
FOR INSERT TO authenticated
WITH CHECK (true);

-- ---------------------------------------------------------------------------
-- Broken notification functions
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.check_overdue_invoices()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    overdue_invoice RECORD;
BEGIN
    FOR overdue_invoice IN
        SELECT 
            i.id,
            i.customer_id,
            c.commercial_id,
            up.email,
            i.invoice_date,
            i.due_date,
            c.company_name AS customer_name
        FROM public.invoices i
        JOIN public.customers c ON i.customer_id = c.id
        JOIN public.user_profiles up ON c.commercial_id = up.id
        WHERE i.payment_status != 'paid'
        AND i.due_date < CURRENT_DATE
        AND NOT EXISTS (
            SELECT 1 FROM public.notification_queue nq
            WHERE nq.related_entity_id = i.id
            AND nq.notification_type = 'overdue_invoice'
            AND nq.created_at > CURRENT_DATE - INTERVAL '1 day'
        )
    LOOP
        INSERT INTO public.notification_queue (
            notification_type, recipient_id, recipient_email, channel, subject,
            message, related_entity_type, related_entity_id
        ) VALUES (
            'overdue_invoice'::public.notification_type,
            overdue_invoice.commercial_id,
            overdue_invoice.email,
            'email'::public.notification_channel,
            'Alerte : Facture échue',
            'Alerte : Facture #' || overdue_invoice.id::TEXT || ' du client ' || overdue_invoice.customer_name || ' est échue. Veuillez procéder au recouvrement.',
            'invoice',
            overdue_invoice.id
        );
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_low_stock()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    low_stock_item RECORD;
    warehouse_user RECORD;
BEGIN
    FOR low_stock_item IN
        SELECT 
            p.id,
            p.name,
            MIN(s.reorder_level) AS reorder_level,
            COALESCE(SUM(s.quantity), 0) AS total_quantity
        FROM public.products p
        JOIN public.inventory_stock s ON p.id = s.product_id
        GROUP BY p.id, p.name
        HAVING COALESCE(SUM(s.quantity), 0) <= MIN(s.reorder_level)
        AND NOT EXISTS (
            SELECT 1 FROM public.notification_queue nq
            WHERE nq.related_entity_id = p.id
            AND nq.notification_type = 'low_stock'
            AND nq.created_at > CURRENT_DATE - INTERVAL '1 day'
        )
    LOOP
        FOR warehouse_user IN
            SELECT id, email FROM public.user_profiles
            WHERE role IN ('admin', 'warehouse_staff') AND is_active = true
        LOOP
            INSERT INTO public.notification_queue (
                notification_type, recipient_id, recipient_email, channel, subject,
                message, related_entity_type, related_entity_id
            ) VALUES (
                'low_stock'::public.notification_type,
                warehouse_user.id,
                warehouse_user.email,
                'both'::public.notification_channel,
                'Alerte stock bas',
                'Le produit ' || low_stock_item.name || ' est sous le seuil de réapprovisionnement (' ||
                    low_stock_item.total_quantity || '/' || low_stock_item.reorder_level || ').',
                'product',
                low_stock_item.id
            );
        END LOOP;
    END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_payment_received()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    admin_user RECORD;
    customer_name TEXT;
BEGIN
    SELECT c.company_name INTO customer_name
    FROM public.invoices i
    JOIN public.customers c ON i.customer_id = c.id
    WHERE i.id = NEW.invoice_id;
    
    FOR admin_user IN
        SELECT id, email FROM public.user_profiles
        WHERE role = 'admin' AND is_active = true
    LOOP
        INSERT INTO public.notification_queue (
            notification_type, recipient_id, recipient_email, channel, subject,
            message, related_entity_type, related_entity_id
        ) VALUES (
            'payment_received'::public.notification_type,
            admin_user.id,
            admin_user.email,
            'email'::public.notification_channel,
            'Paiement reçu',
            'Paiement de ' || NEW.amount::TEXT || ' reçu du client ' || COALESCE(customer_name, 'Inconnu') || '.',
            'payment',
            NEW.id
        );
    END LOOP;
    
    RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Numbering and financial consistency
-- ---------------------------------------------------------------------------

CREATE SEQUENCE IF NOT EXISTS public.order_number_seq START 1;
CREATE SEQUENCE IF NOT EXISTS public.invoice_number_seq START 1;
CREATE SEQUENCE IF NOT EXISTS public.purchase_number_seq START 1;

CREATE OR REPLACE FUNCTION public.generate_order_number(p_date TIMESTAMPTZ DEFAULT now())
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN 'ORD-' || to_char(p_date, 'YYYY') || '-' || lpad(nextval('public.order_number_seq')::TEXT, 5, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_invoice_number(p_date TIMESTAMPTZ DEFAULT now())
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN 'INV-' || to_char(p_date, 'YYYY') || '-' || lpad(nextval('public.invoice_number_seq')::TEXT, 5, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_purchase_number(p_date TIMESTAMPTZ DEFAULT now())
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN 'PO-' || to_char(p_date, 'YYYY') || '-' || lpad(nextval('public.purchase_number_seq')::TEXT, 5, '0');
END;
$$;

CREATE OR REPLACE FUNCTION public.set_sales_order_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
        NEW.order_number := public.generate_order_number(COALESCE(NEW.order_date, now()));
    END IF;
    NEW.subtotal := COALESCE(NEW.subtotal, 0);
    NEW.discount_amount := COALESCE(NEW.discount_amount, 0);
    NEW.tax_amount := COALESCE(NEW.tax_amount, 0);
    NEW.total_amount := COALESCE(NEW.total_amount, NEW.subtotal + NEW.tax_amount - NEW.discount_amount);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_set_sales_order_number ON public.sales_orders;
CREATE TRIGGER trigger_set_sales_order_number
    BEFORE INSERT ON public.sales_orders
    FOR EACH ROW
    EXECUTE FUNCTION public.set_sales_order_number();

CREATE OR REPLACE FUNCTION public.set_purchase_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF NEW.purchase_number IS NULL OR NEW.purchase_number = '' THEN
        NEW.purchase_number := public.generate_purchase_number(COALESCE(NEW.purchase_date, now()));
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_set_purchase_number ON public.purchases;
CREATE TRIGGER trigger_set_purchase_number
    BEFORE INSERT ON public.purchases
    FOR EACH ROW
    EXECUTE FUNCTION public.set_purchase_number();

CREATE OR REPLACE FUNCTION public.set_invoice_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
        NEW.invoice_number := public.generate_invoice_number(COALESCE(NEW.invoice_date, now()));
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_set_invoice_number ON public.invoices;
CREATE TRIGGER trigger_set_invoice_number
    BEFORE INSERT ON public.invoices
    FOR EACH ROW
    EXECUTE FUNCTION public.set_invoice_number();

CREATE OR REPLACE FUNCTION public.set_order_item_line_total()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.line_total :=
        COALESCE(NEW.quantity, 0) * COALESCE(NEW.unit_price, 0) *
        (1 - COALESCE(NEW.discount_percent, 0) / 100);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_set_order_item_line_total ON public.order_items;
CREATE TRIGGER trigger_set_order_item_line_total
    BEFORE INSERT OR UPDATE ON public.order_items
    FOR EACH ROW
    EXECUTE FUNCTION public.set_order_item_line_total();

CREATE OR REPLACE FUNCTION public.recalculate_sales_order_totals()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_order_id UUID;
    v_subtotal NUMERIC;
BEGIN
    v_order_id := COALESCE(NEW.order_id, OLD.order_id);

    SELECT COALESCE(SUM(line_total), 0)
    INTO v_subtotal
    FROM public.order_items
    WHERE order_id = v_order_id;

    UPDATE public.sales_orders
    SET subtotal = v_subtotal,
        total_amount = v_subtotal + COALESCE(tax_amount, 0) - COALESCE(discount_amount, 0),
        updated_at = now()
    WHERE id = v_order_id;

    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trigger_recalculate_sales_order_totals ON public.order_items;
CREATE TRIGGER trigger_recalculate_sales_order_totals
    AFTER INSERT OR UPDATE OR DELETE ON public.order_items
    FOR EACH ROW
    EXECUTE FUNCTION public.recalculate_sales_order_totals();

-- ---------------------------------------------------------------------------
-- Stock movement synchronization
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.sync_inventory_stock_from_movements()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_product_id UUID;
    v_warehouse_id UUID;
    v_quantity INTEGER;
BEGIN
    v_product_id := COALESCE(NEW.product_id, OLD.product_id);
    v_warehouse_id := COALESCE(NEW.warehouse_id, OLD.warehouse_id);

    SELECT COALESCE(SUM(
        CASE movement_type
            WHEN 'in' THEN quantity
            WHEN 'return' THEN quantity
            WHEN 'out' THEN -quantity
            WHEN 'adjustment' THEN quantity
            ELSE 0
        END
    ), 0)::INTEGER
    INTO v_quantity
    FROM public.stock_movements
    WHERE product_id = v_product_id
      AND warehouse_id = v_warehouse_id;

    INSERT INTO public.inventory_stock (product_id, warehouse_id, quantity, updated_at)
    VALUES (v_product_id, v_warehouse_id, v_quantity, now())
    ON CONFLICT (product_id, warehouse_id)
    DO UPDATE SET quantity = EXCLUDED.quantity, updated_at = now();

    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trigger_sync_inventory_stock_from_movements ON public.stock_movements;
CREATE TRIGGER trigger_sync_inventory_stock_from_movements
    AFTER INSERT OR UPDATE OR DELETE ON public.stock_movements
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_inventory_stock_from_movements();

-- ---------------------------------------------------------------------------
-- Customer support tickets
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    subject TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    assigned_to UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS idx_support_tickets_user ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_customer ON public.support_tickets(customer_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);

DROP POLICY IF EXISTS "support_tickets_admin_manage" ON public.support_tickets;
CREATE POLICY "support_tickets_admin_manage"
ON public.support_tickets
FOR ALL TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "support_tickets_user_manage_own" ON public.support_tickets;
CREATE POLICY "support_tickets_user_manage_own"
ON public.support_tickets
FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "support_tickets_sales_rep_view_assigned_customer" ON public.support_tickets;
CREATE POLICY "support_tickets_sales_rep_view_assigned_customer"
ON public.support_tickets
FOR SELECT TO authenticated
USING (
    public.is_sales_rep()
    AND customer_id IN (
        SELECT id FROM public.customers WHERE commercial_id = auth.uid()
    )
);
