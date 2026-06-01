-- Cleanup issues reported by Supabase security advisor.

DROP POLICY IF EXISTS "expense_history_all" ON public.expense_approval_history;

DROP POLICY IF EXISTS "failed_login_service_insert" ON public.failed_login_attempts;

CREATE OR REPLACE VIEW public.receivables_aging
WITH (security_invoker = true) AS
SELECT
    c.id AS customer_id,
    c.company_name,
    c.contact_person,
    c.email,
    c.phone,
    so.id AS order_id,
    so.order_number,
    so.total_amount,
    so.currency,
    so.payment_type,
    so.created_at AS order_date,
    so.due_date,
    so.payment_status,
    EXTRACT(DAY FROM (NOW() - so.created_at)) AS days_outstanding,
    CASE
        WHEN EXTRACT(DAY FROM (NOW() - so.created_at)) <= 30 THEN '0-30 jours'
        WHEN EXTRACT(DAY FROM (NOW() - so.created_at)) <= 60 THEN '31-60 jours'
        WHEN EXTRACT(DAY FROM (NOW() - so.created_at)) <= 90 THEN '61-90 jours'
        ELSE '90+ jours'
    END AS aging_bracket
FROM public.sales_orders so
JOIN public.customers c ON so.customer_id = c.id
WHERE so.payment_type = 'credit'
  AND so.payment_status != 'paid';
