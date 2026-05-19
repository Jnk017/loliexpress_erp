-- ============================================================================
-- MIGRATION: Add RLS helpers for comptable/acheteur roles + tighten policies
-- ============================================================================

-- Helper functions for new roles
CREATE OR REPLACE FUNCTION public.is_comptable()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
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
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'acheteur' AND is_active = true
    );
$$;

-- Update expenses RLS: admin + comptable can see all, others see their own
DROP POLICY IF EXISTS "admin_manage_expenses" ON public.expenses;
DROP POLICY IF EXISTS "expenses_policy" ON public.expenses;

CREATE POLICY "expenses_admin_full" ON public.expenses
    FOR ALL TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

CREATE POLICY "expenses_comptable_manage" ON public.expenses
    FOR ALL TO authenticated
    USING (is_comptable())
    WITH CHECK (is_comptable());

CREATE POLICY "expenses_own_view" ON public.expenses
    FOR SELECT TO authenticated
    USING (requested_by = auth.uid());

CREATE POLICY "expenses_own_insert" ON public.expenses
    FOR INSERT TO authenticated
    WITH CHECK (requested_by = auth.uid() OR requested_by IS NULL);

-- Update purchases RLS: admin + acheteur full, others read-only
DROP POLICY IF EXISTS "suppliers_all" ON public.suppliers;
DROP POLICY IF EXISTS "purchases_all" ON public.purchases;
DROP POLICY IF EXISTS "purchase_items_all" ON public.purchase_items;

CREATE POLICY "suppliers_admin_acheteur_manage" ON public.suppliers
    FOR ALL TO authenticated
    USING (is_admin() OR is_acheteur())
    WITH CHECK (is_admin() OR is_acheteur());

CREATE POLICY "suppliers_read" ON public.suppliers
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "purchases_admin_acheteur_manage" ON public.purchases
    FOR ALL TO authenticated
    USING (is_admin() OR is_acheteur())
    WITH CHECK (is_admin() OR is_acheteur());

CREATE POLICY "purchases_read" ON public.purchases
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "purchase_items_admin_acheteur_manage" ON public.purchase_items
    FOR ALL TO authenticated
    USING (is_admin() OR is_acheteur())
    WITH CHECK (is_admin() OR is_acheteur());

CREATE POLICY "purchase_items_read" ON public.purchase_items
    FOR SELECT TO authenticated
    USING (true);

-- Expense approval history: admin + comptable full, others read own
DROP POLICY IF EXISTS "expense_history_all" ON public.expense_approval_history;

CREATE POLICY "expense_history_admin_comptable" ON public.expense_approval_history
    FOR ALL TO authenticated
    USING (is_admin() OR is_comptable())
    WITH CHECK (is_admin() OR is_comptable());

CREATE POLICY "expense_history_own_view" ON public.expense_approval_history
    FOR SELECT TO authenticated
    USING (performed_by = auth.uid());
