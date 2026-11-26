-- P1.a — fixture isolée, après 008. Les trois résultats doivent être true.
BEGIN;
CREATE TEMP TABLE invoice_results (scenario text PRIMARY KEY, passed boolean NOT NULL);
DO $verify$
DECLARE
    actor uuid := gen_random_uuid();
    customer uuid := gen_random_uuid();
    cdf_order uuid := gen_random_uuid();
    usd_order uuid := gen_random_uuid();
    cdf_invoice public.invoices%ROWTYPE;
    usd_invoice public.invoices%ROWTYPE;
    due_date timestamptz := now() + interval '30 days';
    rejected boolean := false;
BEGIN
    INSERT INTO auth.users(id,email) VALUES (actor, actor::text || '@example.invalid');
    UPDATE public.user_profiles SET role = 'admin', is_active = true WHERE id = actor;
    PERFORM set_config('request.jwt.claim.sub', actor::text, true);
    INSERT INTO public.customers(id,company_name,contact_person,email,phone,is_active)
    VALUES (customer,'Fixture','Fixture',customer::text || '@example.invalid','000',true);
    INSERT INTO public.sales_orders(id,customer_id,sales_rep_id,subtotal,tax_amount,discount_amount,
        total_amount,order_status,payment_status,currency,exchange_rate,payment_type)
    VALUES (cdf_order,customer,actor,3850,0,0,3850,'confirmed','pending','CDF',1,'credit'),
           (usd_order,customer,actor,10,0,0,10,'confirmed','pending','USD',2500,'credit');
    BEGIN
        PERFORM public.issue_order_invoice(cdf_order,due_date,false,500);
    EXCEPTION WHEN invalid_parameter_value THEN rejected := true;
    END;
    cdf_invoice := public.issue_order_invoice(cdf_order,due_date,true,500);
    usd_invoice := public.issue_order_invoice(usd_order,due_date,true,0);
    INSERT INTO invoice_results VALUES ('optional_delivery_and_zero_tax',
        rejected AND cdf_invoice.tax_amount = 0 AND cdf_invoice.delivery_fee = 500
        AND cdf_invoice.total_amount = 4350 AND usd_invoice.total_amount = 10
        AND usd_invoice.currency = 'USD' AND usd_invoice.tax_amount = 0);
    INSERT INTO invoice_results VALUES ('issue_retry_returns_same_invoice',
        (public.issue_order_invoice(cdf_order,due_date,true,500)).id = cdf_invoice.id);
    PERFORM public.record_payment(cdf_invoice.id,3850,'CDF','cash');
    SELECT * INTO STRICT cdf_invoice FROM public.invoices WHERE order_id = cdf_order;
    rejected := cdf_invoice.payment_status = 'partial'
        AND (SELECT outstanding_amount FROM public.invoice_open_balances WHERE invoice_id = cdf_invoice.id) = 500;
    PERFORM public.record_payment(cdf_invoice.id,500,'CDF','cash');
    SELECT * INTO STRICT cdf_invoice FROM public.invoices WHERE order_id = cdf_order;
    INSERT INTO invoice_results VALUES ('delivery_fee_in_outstanding_balance',
        rejected AND cdf_invoice.payment_status = 'paid'
        AND cdf_invoice.total_amount = cdf_invoice.amount_paid
        AND NOT EXISTS (SELECT 1 FROM public.invoice_open_balances WHERE invoice_id = cdf_invoice.id));
END;
$verify$;
SELECT scenario, passed FROM invoice_results ORDER BY scenario;
ROLLBACK;
