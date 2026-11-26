-- P1.a — exécuter après 015. Treize assertions doivent retourner passed = true.
BEGIN;
CREATE TEMP TABLE handover_results(scenario text PRIMARY KEY, passed boolean NOT NULL);
DO $verify$
DECLARE
    actor uuid := gen_random_uuid();
    customer uuid := gen_random_uuid();
    product uuid := gen_random_uuid();
    warehouse uuid := gen_random_uuid();
    cdf_order public.sales_orders%ROWTYPE;
    usd_order public.sales_orders%ROWTYPE;
    cdf_delivery uuid;
    usd_delivery uuid;
    items jsonb;
    result jsonb;
    denied boolean := false;
    cdf_item uuid;
    usd_item uuid;
    return_request uuid := gen_random_uuid();
    inspection public.customer_return_inspections%ROWTYPE;
    non_sellable_id uuid;
    cdf_invoice public.invoices%ROWTYPE;
    usd_invoice public.invoices%ROWTYPE;
    credit public.invoice_item_credits%ROWTYPE;
BEGIN
    INSERT INTO auth.users(id,email) VALUES (actor,actor::text || '@example.invalid');
    UPDATE public.user_profiles SET role = 'admin', is_active = true WHERE id = actor;
    PERFORM set_config('request.jwt.claim.sub',actor::text,true);
    INSERT INTO public.customers(id,company_name,contact_person,email,phone,is_active)
    VALUES (customer,'Fixture','Fixture',customer::text || '@example.invalid','000',true);
    INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
    VALUES (product,product::text,'Fixture',4000,'CDF',true);
    INSERT INTO public.warehouse_locations(id,name,is_active) VALUES (warehouse,warehouse::text,true);
    INSERT INTO public.exchange_rates(currency_pair,rate,source,effective_at)
    VALUES ('USD/CDF',2500,'fixture',now())
    ON CONFLICT (currency_pair) DO UPDATE SET rate = EXCLUDED.rate, effective_at = EXCLUDED.effective_at;
    PERFORM public.adjust_stock(product,warehouse,3,'Stock fixture');
    items := jsonb_build_array(jsonb_build_object('product_id',product,'quantity',2));
    cdf_order := public.create_order_with_items(customer,items,p_discount => 200);
    usd_order := public.create_order_with_items(customer,items,NULL,'USD',2500);
    SELECT id INTO STRICT cdf_item FROM public.order_items WHERE order_id = cdf_order.id;
    SELECT id INTO STRICT usd_item FROM public.order_items WHERE order_id = usd_order.id;
    BEGIN
        PERFORM public.inspect_customer_return(cdf_item,1,1,'Contrôle fixture',gen_random_uuid());
    EXCEPTION WHEN invalid_parameter_value THEN denied := true;
    END;
    INSERT INTO handover_results VALUES ('return_requires_actual_handover',denied);
    denied := false;
    PERFORM public.transition_order_status(cdf_order.id,'confirmed');
    PERFORM public.transition_order_status(cdf_order.id,'processing');
    PERFORM public.transition_order_status(cdf_order.id,'shipped');
    PERFORM public.transition_order_status(usd_order.id,'confirmed');
    PERFORM public.transition_order_status(usd_order.id,'processing');
    PERFORM public.transition_order_status(usd_order.id,'shipped');
    INSERT INTO public.deliveries(order_id,delivery_address,status)
    VALUES (cdf_order.id,'Fixture','pending') RETURNING id INTO cdf_delivery;
    INSERT INTO public.deliveries(order_id,delivery_address,status)
    VALUES (usd_order.id,'Fixture','pending') RETURNING id INTO usd_delivery;
    PERFORM public.assign_delivery_warehouse(cdf_delivery,warehouse);
    PERFORM public.assign_delivery_warehouse(usd_delivery,warehouse);
    INSERT INTO handover_results VALUES ('shipment_does_not_decrement',
        (SELECT quantity FROM public.inventory_stock WHERE product_id = product AND warehouse_id = warehouse) = 3);
    BEGIN
        PERFORM public.transition_order_status(cdf_order.id,'delivered');
    EXCEPTION WHEN invalid_parameter_value THEN denied := true;
    END;
    INSERT INTO handover_results VALUES ('status_requires_handover',denied);
    result := public.confirm_delivery(cdf_delivery);
    INSERT INTO handover_results VALUES ('handover_decrements_once',
        result->>'success' = 'true' AND public.confirm_delivery(cdf_delivery)->>'success' = 'true'
        AND (SELECT count(*) FROM public.stock_movements WHERE reference_id = cdf_delivery) = 1
        AND (SELECT quantity FROM public.inventory_stock WHERE product_id = product AND warehouse_id = warehouse) = 1
        AND (SELECT order_status FROM public.sales_orders WHERE id = cdf_order.id) = 'delivered');
    result := public.confirm_delivery(usd_delivery);
    INSERT INTO handover_results VALUES ('insufficient_stock_rolls_back',
        result->>'success' = 'false'
        AND NOT EXISTS (SELECT 1 FROM public.stock_handovers WHERE delivery_id = usd_delivery)
        AND (SELECT status FROM public.deliveries WHERE id = usd_delivery) = 'pending'
        AND (SELECT order_status FROM public.sales_orders WHERE id = usd_order.id) = 'shipped');
    PERFORM public.adjust_stock(product,warehouse,1,'Réapprovisionnement fixture');
    result := public.confirm_delivery(usd_delivery);
    INSERT INTO handover_results VALUES ('usd_handover_uses_same_stock_rule',
        result->>'success' = 'true' AND usd_order.total_amount = 3.20
        AND (SELECT quantity FROM public.inventory_stock WHERE product_id = product AND warehouse_id = warehouse) = 0);
    inspection := public.inspect_customer_return(cdf_item,2,1,'Un article revendable, un écarté',return_request);
    PERFORM public.inspect_customer_return(cdf_item,2,1,'Un article revendable, un écarté',return_request);
    INSERT INTO handover_results VALUES ('mixed_return_restocks_sellable_once',
        inspection.returned_quantity = 2 AND inspection.sellable_quantity = 1
        AND (SELECT quantity FROM public.inventory_stock WHERE product_id = product AND warehouse_id = warehouse) = 1
        AND (SELECT count(*) FROM public.stock_movements WHERE reference_id = return_request) = 1
        AND NOT EXISTS (SELECT 1 FROM public.get_customer_return_lines(cdf_order.order_number)));
    denied := false;
    BEGIN
        PERFORM public.inspect_customer_return(cdf_item,1,0,'Quantité excédentaire',gen_random_uuid());
    EXCEPTION WHEN SQLSTATE 'P4104' THEN denied := true;
    END;
    INSERT INTO handover_results VALUES ('return_quantity_ceiling',denied);
    inspection := public.inspect_customer_return(usd_item,2,0,'Deux articles non revendables',gen_random_uuid());
    non_sellable_id := inspection.id;
    INSERT INTO handover_results VALUES ('unsellable_return_keeps_stock_and_accounts',
        inspection.returned_quantity = 2 AND inspection.sellable_quantity = 0
        AND NOT EXISTS (SELECT 1 FROM public.stock_movements WHERE reference_id = inspection.id)
        AND (SELECT quantity FROM public.inventory_stock WHERE product_id = product AND warehouse_id = warehouse) = 1
        AND NOT EXISTS (SELECT 1 FROM public.invoice_delivery_fee_credits));
    UPDATE public.user_profiles SET role = 'admin' WHERE id = actor;
    cdf_invoice := public.issue_order_invoice(cdf_order.id,now()+interval '30 days',true,500);
    usd_invoice := public.issue_order_invoice(usd_order.id,now()+interval '30 days',false,0);
    denied := false;
    BEGIN
        PERFORM public.record_return_item_credit(non_sellable_id);
    EXCEPTION WHEN SQLSTATE 'P4101' THEN denied := true;
    END;
    INSERT INTO handover_results VALUES ('unsellable_units_never_credited',
        denied AND NOT EXISTS (SELECT 1 FROM public.invoice_item_credits WHERE return_id = non_sellable_id));
    credit := public.record_return_item_credit(return_request);
    INSERT INTO handover_results VALUES ('mixed_return_credit_once_at_invoiced_price',
        credit.quantity = 1 AND credit.amount = 3900
        AND (SELECT delivery_fee_credited FROM public.invoices WHERE id = cdf_invoice.id) = 0
        AND (SELECT outstanding_amount FROM public.invoice_open_balances WHERE invoice_id = cdf_invoice.id) = 4400);
    result := public.record_payment(cdf_invoice.id,4400,'CDF','cash');
    INSERT INTO handover_results VALUES ('cdf_cycle_reconciled',
        result->>'success' = 'true'
        AND NOT EXISTS (SELECT 1 FROM public.invoice_open_balances WHERE invoice_id = cdf_invoice.id));
    result := public.record_payment(usd_invoice.id,3.20,'USD','cash');
    INSERT INTO handover_results VALUES ('usd_cycle_reconciled',
        result->>'success' = 'true'
        AND NOT EXISTS (SELECT 1 FROM public.invoice_open_balances WHERE invoice_id = usd_invoice.id));
END;
$verify$;
SELECT scenario, passed FROM handover_results ORDER BY scenario;
ROLLBACK;
