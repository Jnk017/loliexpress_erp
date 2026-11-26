-- G11 — RA1 à RA5. Chaque fixture est annulée à la fin.
BEGIN;
CREATE TEMP TABLE ra_results(scenario text PRIMARY KEY, passed boolean NOT NULL);
DO $verify$
DECLARE
    actor uuid := gen_random_uuid();
    customer uuid := gen_random_uuid();
    product uuid := gen_random_uuid();
    warehouse uuid := gen_random_uuid();
    order_key uuid := gen_random_uuid();
    mixed_item uuid;
    rejected_item uuid;
    delivery uuid;
    mixed_return uuid := gen_random_uuid();
    rejected_return uuid := gen_random_uuid();
    fee_request uuid := gen_random_uuid();
    invoice_row public.invoices%ROWTYPE;
    item_credit public.invoice_item_credits%ROWTYPE;
    fee_credit public.invoice_delivery_fee_credits%ROWTYPE;
    denied boolean := false;
    duplicate_credit boolean := false;
    duplicate_return boolean := false;
    fee_was_separate boolean;
BEGIN
    INSERT INTO auth.users(id,email) VALUES (actor,actor::text || '@example.invalid');
    UPDATE public.user_profiles SET role = 'admin',is_active = true WHERE id = actor;
    PERFORM set_config('request.jwt.claim.sub',actor::text,true);
    INSERT INTO public.customers(id,company_name,contact_person,email,phone,is_active)
    VALUES (customer,'RA fixture','Fixture',customer::text || '@example.invalid','000',true);
    INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
    VALUES (product,product::text,'RA fixture',4000,'CDF',true);
    INSERT INTO public.warehouse_locations(id,name,is_active) VALUES (warehouse,warehouse::text,true);
    PERFORM public.adjust_stock(product,warehouse,6,'RA stock fixture');
    INSERT INTO public.sales_orders(id,customer_id,sales_rep_id,subtotal,tax_amount,discount_amount,
        total_amount,order_status,payment_status,currency,exchange_rate,payment_type)
    VALUES (order_key,customer,actor,28000,0,2800,25200,'shipped','pending','CDF',1,'credit');
    INSERT INTO public.order_items(order_id,product_id,quantity,unit_price,line_total)
    VALUES (order_key,product,5,4000,20000) RETURNING id INTO mixed_item;
    INSERT INTO public.order_items(order_id,product_id,quantity,unit_price,line_total)
    VALUES (order_key,product,1,8000,8000) RETURNING id INTO rejected_item;
    INSERT INTO public.deliveries(order_id,delivery_address,status) VALUES (order_key,'RA fixture','pending')
    RETURNING id INTO delivery;
    PERFORM public.assign_delivery_warehouse(delivery,warehouse);
    IF public.confirm_delivery(delivery)->>'success' IS DISTINCT FROM 'true' THEN
        RAISE EXCEPTION 'RA handover fixture failed';
    END IF;
    invoice_row := public.issue_order_invoice(order_key,now()+interval '30 days',true,500);
    PERFORM public.inspect_customer_return(rejected_item,1,0,'Non revendable',rejected_return);
    PERFORM public.inspect_customer_return(mixed_item,5,3,'Trois revendables, deux écartées',mixed_return);
    BEGIN
        PERFORM public.record_return_item_credit(rejected_return);
    EXCEPTION WHEN SQLSTATE 'P4101' THEN denied := true;
    END;
    INSERT INTO ra_results VALUES ('RA1_non_sellable_refused_P4101',
        denied AND NOT EXISTS (SELECT 1 FROM public.invoice_item_credits WHERE return_id = rejected_return));
    UPDATE public.products SET unit_price = 9999 WHERE id = product;
    item_credit := public.record_return_item_credit(mixed_return);
    INSERT INTO ra_results VALUES ('RA2_three_credited_two_traced',
        item_credit.quantity = 3 AND EXISTS (SELECT 1 FROM public.return_units_audit
            WHERE return_id = mixed_return AND rejected_quantity = 2 AND controlled_by = actor));
    INSERT INTO ra_results VALUES ('RA3_original_net_line',
        item_credit.amount = 10800 AND EXISTS (SELECT 1 FROM public.invoice_lines
            WHERE id = item_credit.invoice_line_id AND order_item_id = mixed_item AND net_unit_price = 3600));
    BEGIN
        PERFORM public.record_return_item_credit(mixed_return);
    EXCEPTION WHEN SQLSTATE 'P4104' THEN duplicate_credit := true;
    END;
    BEGIN
        PERFORM public.inspect_customer_return(mixed_item,1,1,'Quantité déjà retournée',gen_random_uuid());
    EXCEPTION WHEN SQLSTATE 'P4104' THEN duplicate_return := true;
    END;
    INSERT INTO ra_results VALUES ('RA4_repeat_refused_P4104',
        duplicate_credit AND duplicate_return AND
        (SELECT count(*) FROM public.invoice_item_credits WHERE return_id = mixed_return) = 1);
    fee_was_separate := NOT EXISTS (
        SELECT 1 FROM public.invoice_delivery_fee_credits WHERE invoice_id = invoice_row.id);
    fee_credit := public.record_delivery_fee_credit(invoice_row.id,200,'Décision RA5',fee_request);
    INSERT INTO ra_results VALUES ('RA5_only_explicit_admin_delivery_credit',
        fee_was_separate AND fee_credit.amount = 200 AND EXISTS (
            SELECT 1 FROM public.audit_logs WHERE record_id = fee_request
                AND user_id = actor AND new_values->>'operation' = 'admin_decision'
                AND new_values->>'reason' = 'Décision RA5'));
END;
$verify$;
SELECT scenario,passed FROM ra_results ORDER BY scenario;
ROLLBACK;
