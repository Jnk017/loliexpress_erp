-- Clean bootstrap 017: security-invoker receivables view and default privilege cleanup.
CREATE OR REPLACE VIEW public.receivables_aging WITH(security_invoker=true) AS SELECT c.id customer_id,c.company_name,so.id order_id,so.order_number,so.total_amount,so.currency,so.due_date,so.payment_status,extract(day from now()-so.order_date)::integer days_outstanding FROM public.sales_orders so JOIN public.customers c ON c.id=so.customer_id WHERE so.payment_type='credit' AND so.payment_status<>'paid';
REVOKE ALL ON public.receivables_aging FROM anon; GRANT SELECT ON public.receivables_aging TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
