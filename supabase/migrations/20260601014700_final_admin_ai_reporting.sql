-- Final ERP layer: admin-created users, delivery agents, reporting, AI support,
-- currency preferences, cash/bank accounting, and role-specific RLS.

ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS display_currency TEXT NOT NULL DEFAULT 'CDF'
CHECK (display_currency IN ('CDF', 'USD'));

CREATE TABLE IF NOT EXISTS public.exchange_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    currency_pair TEXT NOT NULL UNIQUE CHECK (currency_pair = 'USD/CDF'),
    rate NUMERIC(18,6) NOT NULL CHECK (rate > 0),
    source TEXT DEFAULT 'manual',
    effective_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO public.exchange_rates (currency_pair, rate, source)
VALUES ('USD/CDF', 2750, 'seed')
ON CONFLICT (currency_pair) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.cash_registers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    currency TEXT NOT NULL DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD')),
    opening_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    current_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.cash_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cash_register_id UUID NOT NULL REFERENCES public.cash_registers(id) ON DELETE CASCADE,
    movement_type TEXT NOT NULL CHECK (movement_type IN ('in', 'out')),
    amount NUMERIC(18,2) NOT NULL CHECK (amount >= 0),
    currency TEXT NOT NULL DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD')),
    reason TEXT NOT NULL,
    related_entity_type TEXT,
    related_entity_id UUID,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_name TEXT NOT NULL,
    bank_name TEXT NOT NULL,
    account_number TEXT,
    currency TEXT NOT NULL DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD')),
    current_balance NUMERIC(18,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.bank_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_account_id UUID NOT NULL REFERENCES public.bank_accounts(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('credit', 'debit')),
    amount NUMERIC(18,2) NOT NULL CHECK (amount >= 0),
    currency TEXT NOT NULL DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD')),
    transaction_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reference TEXT,
    description TEXT,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.accounting_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    label TEXT NOT NULL,
    debit NUMERIC(18,2) NOT NULL DEFAULT 0,
    credit NUMERIC(18,2) NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD')),
    related_entity_type TEXT,
    related_entity_id UUID,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.ai_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    insight_type TEXT NOT NULL CHECK (insight_type IN ('sales_forecast', 'stock_alert', 'expense_trend')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
    payload JSONB DEFAULT '{}'::jsonb,
    generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.exchange_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_registers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounting_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_delivery_agent()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'delivery_agent' AND is_active = true
    );
$$;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT role::text FROM public.user_profiles
    WHERE id = auth.uid() AND is_active = true
$$;

CREATE OR REPLACE FUNCTION public.can_read_finance()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT public.is_admin() OR public.is_comptable()
$$;

DROP POLICY IF EXISTS "exchange_rates_read" ON public.exchange_rates;
CREATE POLICY "exchange_rates_read" ON public.exchange_rates
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "exchange_rates_admin_manage" ON public.exchange_rates;
CREATE POLICY "exchange_rates_admin_manage" ON public.exchange_rates
FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "cash_registers_finance_read" ON public.cash_registers;
CREATE POLICY "cash_registers_finance_read" ON public.cash_registers
FOR SELECT TO authenticated USING (public.can_read_finance());
DROP POLICY IF EXISTS "cash_registers_admin_comptable_manage" ON public.cash_registers;
CREATE POLICY "cash_registers_admin_comptable_manage" ON public.cash_registers
FOR ALL TO authenticated USING (public.can_read_finance()) WITH CHECK (public.can_read_finance());

DROP POLICY IF EXISTS "cash_movements_finance_read" ON public.cash_movements;
CREATE POLICY "cash_movements_finance_read" ON public.cash_movements
FOR SELECT TO authenticated USING (public.can_read_finance());
DROP POLICY IF EXISTS "cash_movements_admin_comptable_manage" ON public.cash_movements;
CREATE POLICY "cash_movements_admin_comptable_manage" ON public.cash_movements
FOR ALL TO authenticated USING (public.can_read_finance()) WITH CHECK (public.can_read_finance());

DROP POLICY IF EXISTS "bank_accounts_finance_read" ON public.bank_accounts;
CREATE POLICY "bank_accounts_finance_read" ON public.bank_accounts
FOR SELECT TO authenticated USING (public.can_read_finance());
DROP POLICY IF EXISTS "bank_accounts_admin_comptable_manage" ON public.bank_accounts;
CREATE POLICY "bank_accounts_admin_comptable_manage" ON public.bank_accounts
FOR ALL TO authenticated USING (public.can_read_finance()) WITH CHECK (public.can_read_finance());

DROP POLICY IF EXISTS "bank_transactions_finance_read" ON public.bank_transactions;
CREATE POLICY "bank_transactions_finance_read" ON public.bank_transactions
FOR SELECT TO authenticated USING (public.can_read_finance());
DROP POLICY IF EXISTS "bank_transactions_admin_comptable_manage" ON public.bank_transactions;
CREATE POLICY "bank_transactions_admin_comptable_manage" ON public.bank_transactions
FOR ALL TO authenticated USING (public.can_read_finance()) WITH CHECK (public.can_read_finance());

DROP POLICY IF EXISTS "accounting_entries_finance_manage" ON public.accounting_entries;
CREATE POLICY "accounting_entries_finance_manage" ON public.accounting_entries
FOR ALL TO authenticated USING (public.can_read_finance()) WITH CHECK (public.can_read_finance());

DROP POLICY IF EXISTS "ai_insights_admin_read" ON public.ai_insights;
CREATE POLICY "ai_insights_admin_read" ON public.ai_insights
FOR SELECT TO authenticated USING (public.is_admin() OR public.is_comptable());
DROP POLICY IF EXISTS "ai_insights_admin_manage" ON public.ai_insights;
CREATE POLICY "ai_insights_admin_manage" ON public.ai_insights
FOR ALL TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Tighten or extend existing role policies.
DROP POLICY IF EXISTS "comptable_read_all_orders" ON public.sales_orders;
CREATE POLICY "comptable_read_all_orders" ON public.sales_orders
FOR SELECT TO authenticated USING (public.is_comptable());

DROP POLICY IF EXISTS "comptable_read_all_order_items" ON public.order_items;
CREATE POLICY "comptable_read_all_order_items" ON public.order_items
FOR SELECT TO authenticated USING (public.is_comptable());

DROP POLICY IF EXISTS "comptable_read_all_invoices" ON public.invoices;
CREATE POLICY "comptable_read_all_invoices" ON public.invoices
FOR SELECT TO authenticated USING (public.is_comptable());

DROP POLICY IF EXISTS "comptable_read_all_payments" ON public.payments;
CREATE POLICY "comptable_read_all_payments" ON public.payments
FOR SELECT TO authenticated USING (public.is_comptable());

DROP POLICY IF EXISTS "acheteur_stock_entries" ON public.stock_movements;
CREATE POLICY "acheteur_stock_entries" ON public.stock_movements
FOR INSERT TO authenticated
WITH CHECK (public.is_acheteur() AND movement_type IN ('in', 'return'));

DROP POLICY IF EXISTS "acheteur_read_stock_movements" ON public.stock_movements;
CREATE POLICY "acheteur_read_stock_movements" ON public.stock_movements
FOR SELECT TO authenticated USING (public.is_acheteur());

DROP POLICY IF EXISTS "delivery_agent_read_routes" ON public.delivery_routes;
CREATE POLICY "delivery_agent_read_routes" ON public.delivery_routes
FOR SELECT TO authenticated USING (public.is_delivery_agent() AND driver_id = auth.uid());

DROP POLICY IF EXISTS "delivery_agent_read_assigned_deliveries" ON public.deliveries;
CREATE POLICY "delivery_agent_read_assigned_deliveries" ON public.deliveries
FOR SELECT TO authenticated
USING (
    public.is_delivery_agent()
    AND route_id IN (SELECT id FROM public.delivery_routes WHERE driver_id = auth.uid())
);

DROP POLICY IF EXISTS "delivery_agent_update_assigned_deliveries" ON public.deliveries;
CREATE POLICY "delivery_agent_update_assigned_deliveries" ON public.deliveries
FOR UPDATE TO authenticated
USING (
    public.is_delivery_agent()
    AND route_id IN (SELECT id FROM public.delivery_routes WHERE driver_id = auth.uid())
)
WITH CHECK (
    public.is_delivery_agent()
    AND route_id IN (SELECT id FROM public.delivery_routes WHERE driver_id = auth.uid())
);

-- User management must happen through service-role Edge Functions.
DROP POLICY IF EXISTS "admin_insert_profiles_from_edge" ON public.user_profiles;
CREATE POLICY "admin_insert_profiles_from_edge" ON public.user_profiles
FOR INSERT TO authenticated
WITH CHECK (public.is_admin());

CREATE OR REPLACE FUNCTION public.convert_to_cdf(p_amount NUMERIC, p_currency TEXT)
RETURNS NUMERIC
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT CASE
        WHEN p_currency = 'USD' THEN p_amount * COALESCE((SELECT rate FROM public.exchange_rates WHERE currency_pair = 'USD/CDF' ORDER BY effective_at DESC LIMIT 1), 2750)
        ELSE p_amount
    END
$$;

CREATE OR REPLACE FUNCTION public.get_admin_sales_report(p_start TIMESTAMPTZ, p_end TIMESTAMPTZ)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'admin only';
    END IF;

    SELECT jsonb_build_object(
        'revenue_cdf', COALESCE(SUM(public.convert_to_cdf(total_amount, currency)), 0),
        'orders_count', COUNT(*),
        'by_status', COALESCE((
            SELECT jsonb_object_agg(order_status, count)
            FROM (
                SELECT order_status::text, COUNT(*) AS count
                FROM public.sales_orders
                WHERE order_date >= p_start AND order_date <= p_end
                GROUP BY order_status
            ) s
        ), '{}'::jsonb),
        'daily', COALESCE((
            SELECT jsonb_agg(row_to_json(d))
            FROM (
                SELECT date_trunc('day', order_date)::date AS day,
                       SUM(public.convert_to_cdf(total_amount, currency)) AS revenue_cdf,
                       COUNT(*) AS orders
                FROM public.sales_orders
                WHERE order_date >= p_start AND order_date <= p_end
                GROUP BY 1
                ORDER BY 1
            ) d
        ), '[]'::jsonb),
        'top_products', COALESCE((
            SELECT jsonb_agg(row_to_json(t))
            FROM (
                SELECT p.name, p.sku, SUM(oi.quantity) AS quantity, SUM(oi.line_total) AS revenue
                FROM public.order_items oi
                JOIN public.products p ON p.id = oi.product_id
                JOIN public.sales_orders so ON so.id = oi.order_id
                WHERE so.order_date >= p_start AND so.order_date <= p_end
                GROUP BY p.id, p.name, p.sku
                ORDER BY revenue DESC
                LIMIT 10
            ) t
        ), '[]'::jsonb)
    )
    INTO result
    FROM public.sales_orders
    WHERE order_date >= p_start AND order_date <= p_end;

    RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_finance_report(p_start TIMESTAMPTZ, p_end TIMESTAMPTZ)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'admin only';
    END IF;

    SELECT jsonb_build_object(
        'sales_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(total_amount, currency)) FROM public.sales_orders WHERE order_date BETWEEN p_start AND p_end), 0),
        'purchase_cost_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(total_amount, currency)) FROM public.purchases WHERE purchase_date BETWEEN p_start AND p_end), 0),
        'expenses_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(amount, currency)) FROM public.expenses WHERE expense_date BETWEEN p_start::date AND p_end::date), 0),
        'net_profit_cdf',
            COALESCE((SELECT SUM(public.convert_to_cdf(total_amount, currency)) FROM public.sales_orders WHERE order_date BETWEEN p_start AND p_end), 0)
            - COALESCE((SELECT SUM(public.convert_to_cdf(total_amount, currency)) FROM public.purchases WHERE purchase_date BETWEEN p_start AND p_end), 0)
            - COALESCE((SELECT SUM(public.convert_to_cdf(amount, currency)) FROM public.expenses WHERE expense_date BETWEEN p_start::date AND p_end::date), 0),
        'expenses_by_category', COALESCE((
            SELECT jsonb_object_agg(category, total)
            FROM (
                SELECT category, SUM(public.convert_to_cdf(amount, currency)) AS total
                FROM public.expenses
                WHERE expense_date BETWEEN p_start::date AND p_end::date
                GROUP BY category
            ) e
        ), '{}'::jsonb),
        'purchases_by_supplier', COALESCE((
            SELECT jsonb_agg(row_to_json(s))
            FROM (
                SELECT COALESCE(s.company_name, 'Sans fournisseur') AS supplier,
                       SUM(public.convert_to_cdf(p.total_amount, p.currency)) AS total_cdf,
                       COUNT(*) AS purchases
                FROM public.purchases p
                LEFT JOIN public.suppliers s ON s.id = p.supplier_id
                WHERE p.purchase_date BETWEEN p_start AND p_end
                GROUP BY s.company_name
                ORDER BY total_cdf DESC
                LIMIT 10
            ) s
        ), '[]'::jsonb)
    )
    INTO result;

    RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_operations_report(p_start TIMESTAMPTZ, p_end TIMESTAMPTZ)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSONB;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'admin only';
    END IF;

    SELECT jsonb_build_object(
        'receivables_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(total_amount - amount_paid, currency)) FROM public.invoices WHERE payment_status != 'paid'), 0),
        'average_receivable_age_days', COALESCE((SELECT AVG(EXTRACT(DAY FROM now() - due_date)) FROM public.invoices WHERE payment_status != 'paid'), 0),
        'risky_customers', COALESCE((
            SELECT jsonb_agg(row_to_json(r))
            FROM (
                SELECT c.company_name, SUM(public.convert_to_cdf(i.total_amount - i.amount_paid, i.currency)) AS outstanding_cdf
                FROM public.invoices i
                JOIN public.customers c ON c.id = i.customer_id
                WHERE i.payment_status != 'paid'
                GROUP BY c.id, c.company_name
                ORDER BY outstanding_cdf DESC
                LIMIT 10
            ) r
        ), '[]'::jsonb),
        'stock_value_cdf', COALESCE((SELECT SUM(s.quantity * COALESCE(p.cost_price, p.unit_price)) FROM public.inventory_stock s JOIN public.products p ON p.id = s.product_id), 0),
        'low_stock', COALESCE((
            SELECT jsonb_agg(row_to_json(l))
            FROM (
                SELECT p.name, p.sku, s.quantity, s.reorder_level
                FROM public.inventory_stock s
                JOIN public.products p ON p.id = s.product_id
                WHERE s.quantity <= s.reorder_level
                ORDER BY s.quantity ASC
                LIMIT 20
            ) l
        ), '[]'::jsonb),
        'cash_balance_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(current_balance, currency)) FROM public.cash_registers WHERE is_active), 0),
        'cash_movements_today_cdf', COALESCE((SELECT SUM(CASE WHEN movement_type = 'in' THEN public.convert_to_cdf(amount, currency) ELSE -public.convert_to_cdf(amount, currency) END) FROM public.cash_movements WHERE created_at::date = CURRENT_DATE), 0),
        'bank_balance_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(current_balance, currency)) FROM public.bank_accounts WHERE is_active), 0),
        'bank_accounts', COALESCE((SELECT jsonb_agg(row_to_json(b)) FROM (SELECT account_name, bank_name, currency, current_balance FROM public.bank_accounts WHERE is_active ORDER BY bank_name) b), '[]'::jsonb)
    )
    INTO result;

    RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_total_report(p_start TIMESTAMPTZ, p_end TIMESTAMPTZ)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'admin only';
    END IF;

    RETURN jsonb_build_object(
        'period', jsonb_build_object('start', p_start, 'end', p_end),
        'sales', public.get_admin_sales_report(p_start, p_end),
        'finance', public.get_admin_finance_report(p_start, p_end),
        'operations', public.get_admin_operations_report(p_start, p_end)
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.generate_ai_insights()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.ai_insights (insight_type, title, description, severity, payload)
    SELECT 'stock_alert', 'Risque de rupture stock', 'Le produit ' || p.name || ' est sous son seuil de réapprovisionnement.', 'warning',
           jsonb_build_object('product_id', p.id, 'sku', p.sku, 'quantity', s.quantity, 'reorder_level', s.reorder_level)
    FROM public.inventory_stock s
    JOIN public.products p ON p.id = s.product_id
    WHERE s.quantity <= s.reorder_level
    ON CONFLICT DO NOTHING;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_admin_sales_report(TIMESTAMPTZ, TIMESTAMPTZ) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_admin_finance_report(TIMESTAMPTZ, TIMESTAMPTZ) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_admin_operations_report(TIMESTAMPTZ, TIMESTAMPTZ) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_admin_total_report(TIMESTAMPTZ, TIMESTAMPTZ) FROM anon;
REVOKE EXECUTE ON FUNCTION public.generate_ai_insights() FROM anon, authenticated;
