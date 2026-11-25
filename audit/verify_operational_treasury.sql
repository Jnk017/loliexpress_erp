-- Fixtures are rolled back. Run on the isolated gate project after 020.
BEGIN;
DO $verify$
DECLARE
    actor uuid := gen_random_uuid();
    customer uuid := gen_random_uuid();
    supplier uuid := gen_random_uuid();
    product uuid := gen_random_uuid();
    warehouse uuid := gen_random_uuid();
    cash_id uuid := gen_random_uuid();
    bank_id uuid := gen_random_uuid();
    usd_id uuid := gen_random_uuid();
    expense_id uuid := gen_random_uuid();
    usd_expense_id uuid := gen_random_uuid();
    purchase_line uuid;
    delivery_id uuid;
    purchase public.purchases%ROWTYPE;
    bill public.supplier_bills%ROWTYPE;
    sale public.sales_orders%ROWTYPE;
    invoice public.invoices%ROWTYPE;
    request_id uuid := gen_random_uuid();
    receipt_id uuid := gen_random_uuid();
    payment_id uuid := gen_random_uuid();
    posting_id uuid;
BEGIN
    INSERT INTO auth.users(id,email) VALUES (actor, actor::text || '@example.invalid');
    UPDATE public.user_profiles SET role='admin',is_active=true WHERE id=actor;
    PERFORM set_config('request.jwt.claim.sub', actor::text, true);
    INSERT INTO public.customers(id,company_name,contact_person,email,phone,is_active)
      VALUES (customer,'QA','QA',customer::text || '@example.invalid','000',true);
    INSERT INTO public.suppliers(id,company_name,is_active) VALUES (supplier,'QA',true);
    INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
      VALUES (product,product::text,'QA',20,'CDF',true);
    INSERT INTO public.warehouse_locations(id,name,is_active) VALUES (warehouse,warehouse::text,true);
    INSERT INTO public.cash_registers(id,name,currency,opening_balance,current_balance)
      VALUES (cash_id,'QA','CDF',100,100),(usd_id,'QA USD','USD',10,10);
    INSERT INTO public.bank_accounts(id,account_name,bank_name,currency,current_balance)
      VALUES (bank_id,'QA','QA','CDF',200);
    PERFORM public.adjust_stock(product,warehouse,10,'QA initial stock');

    purchase := public.create_purchase_with_items(supplier,
      jsonb_build_array(jsonb_build_object('product_id',product,'quantity',8,'unit_cost',5)),
      'CDF',1,NULL);
    IF (SELECT quantity FROM public.inventory_stock WHERE product_id=product AND warehouse_id=warehouse) <> 10 THEN
      RAISE EXCEPTION 'Purchase order changed stock';
    END IF;
    SELECT id INTO STRICT purchase_line FROM public.purchase_items WHERE purchase_id=purchase.id;
    PERFORM public.receive_purchase_item(purchase_line,warehouse,8,receipt_id);
    PERFORM public.receive_purchase_item(purchase_line,warehouse,8,receipt_id);
    bill := public.register_supplier_bill(purchase.id,'QA-1',current_date+10,40);
    IF (SELECT current_balance FROM public.cash_registers WHERE id=cash_id) <> 100
      OR (SELECT current_balance FROM public.bank_accounts WHERE id=bank_id) <> 200 THEN
      RAISE EXCEPTION 'Receipt or bill changed treasury';
    END IF;
    BEGIN
      PERFORM public.pay_supplier_bill_from_account(bill.id,40,'CDF','QA wrong currency',
        gen_random_uuid(),'cash',usd_id);
      RAISE EXCEPTION 'Wrong account currency accepted';
    EXCEPTION WHEN invalid_parameter_value THEN NULL;
    END;
    IF EXISTS (SELECT FROM public.supplier_bill_payments WHERE bill_id=bill.id) THEN
      RAISE EXCEPTION 'Wrong account left a supplier payment';
    END IF;
    PERFORM public.pay_supplier_bill_from_account(bill.id,40,'CDF','QA supplier',request_id,'bank',bank_id);
    PERFORM public.pay_supplier_bill_from_account(bill.id,40,'CDF','QA supplier',request_id,'bank',bank_id);

    sale := public.create_order_with_items(customer,
      jsonb_build_array(jsonb_build_object('product_id',product,'quantity',3)));
    PERFORM public.transition_order_status(sale.id,'confirmed');
    PERFORM public.transition_order_status(sale.id,'processing');
    PERFORM public.transition_order_status(sale.id,'shipped');
    INSERT INTO public.deliveries(order_id,delivery_address,status)
      VALUES (sale.id,'QA','pending') RETURNING id INTO delivery_id;
    PERFORM public.assign_delivery_warehouse(delivery_id,warehouse);
    IF (SELECT quantity FROM public.inventory_stock WHERE product_id=product AND warehouse_id=warehouse) <> 18 THEN
      RAISE EXCEPTION 'Stock should change only at handover';
    END IF;
    IF public.confirm_delivery(delivery_id)->>'success' IS DISTINCT FROM 'true'
      OR public.confirm_delivery(delivery_id)->>'success' IS DISTINCT FROM 'true' THEN
      RAISE EXCEPTION 'Handover failed';
    END IF;
    invoice := public.issue_order_invoice(sale.id,now()+interval '10 days');
    IF (SELECT current_balance FROM public.cash_registers WHERE id=cash_id) <> 100 THEN
      RAISE EXCEPTION 'Invoice changed cash before payment';
    END IF;
    posting_id := public.receive_invoice_payment(invoice.id,25,'CDF','QA receipt','cash',cash_id,payment_id);
    IF posting_id IS DISTINCT FROM public.receive_invoice_payment(invoice.id,25,'CDF','QA receipt','cash',cash_id,payment_id) THEN
      RAISE EXCEPTION 'Receipt retry duplicated the payment';
    END IF;
    PERFORM public.receive_invoice_payment(invoice.id,35,'CDF','QA balance','bank',bank_id,gen_random_uuid());

    INSERT INTO public.expenses(id,category,description,amount,expense_date,currency,status,approved_by,created_by,requested_by)
      VALUES (expense_id,'QA','QA',15,current_date,'CDF','pending_payment',actor,actor,actor);
    PERFORM public.pay_expense_from_account(expense_id,'cash',cash_id);
    PERFORM public.pay_expense_from_account(expense_id,'cash',cash_id);

    INSERT INTO public.expenses(id,category,description,amount,expense_date,currency,status,approved_by,created_by,requested_by)
      VALUES (usd_expense_id,'QA','QA USD',2,current_date,'USD','pending_payment',actor,actor,actor);
    BEGIN
      PERFORM public.pay_expense_from_account(usd_expense_id,'bank',bank_id);
      RAISE EXCEPTION 'USD expense was paid in CDF';
    EXCEPTION WHEN invalid_parameter_value THEN NULL;
    END;
    PERFORM public.pay_expense_from_account(usd_expense_id,'cash',usd_id);

    IF (SELECT quantity FROM public.inventory_stock WHERE product_id=product AND warehouse_id=warehouse)
        IS DISTINCT FROM 10+8-3
      OR (SELECT sum(CASE WHEN movement_type='out' THEN -quantity ELSE quantity END)
          FROM public.stock_movements WHERE product_id=product AND warehouse_id=warehouse) IS DISTINCT FROM 15::bigint
      OR (SELECT current_balance FROM public.cash_registers WHERE id=cash_id) IS DISTINCT FROM 100+25-15
      OR (SELECT current_balance FROM public.bank_accounts WHERE id=bank_id) IS DISTINCT FROM 200-40+35
      OR (SELECT current_balance FROM public.cash_registers WHERE id=usd_id) IS DISTINCT FROM 8
      OR (SELECT sum(CASE WHEN movement_type='out' THEN -amount ELSE amount END) FROM public.cash_movements WHERE cash_register_id=cash_id) IS DISTINCT FROM 10
      OR (SELECT sum(CASE WHEN transaction_type='debit' THEN -amount ELSE amount END) FROM public.bank_transactions WHERE bank_account_id=bank_id) IS DISTINCT FROM -5
      OR (SELECT status FROM public.expenses WHERE id=expense_id) IS DISTINCT FROM 'paid'
      OR (SELECT payment_status::text FROM public.invoices WHERE id=invoice.id) IS DISTINCT FROM 'paid'
      OR (SELECT amount_paid FROM public.supplier_bills WHERE id=bill.id) IS DISTINCT FROM 40 THEN
      RAISE EXCEPTION 'Stock, payment states or treasury failed reconciliation';
    END IF;
END;
$verify$;
SELECT true AS reconciled, 15 AS closing_stock, 110 AS cash_cdf, 195 AS bank_cdf, 8 AS cash_usd;
ROLLBACK;
