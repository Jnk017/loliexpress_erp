-- P1.a — exécuter sur une pile isolée après 014.
BEGIN;
CREATE TEMP TABLE p1a_results (scenario text PRIMARY KEY, passed boolean NOT NULL);
DO $verify$
DECLARE
    actor uuid := gen_random_uuid();
    customer uuid := gen_random_uuid();
    supplier uuid := gen_random_uuid();
    product uuid := gen_random_uuid();
    warehouse uuid := gen_random_uuid();
    purchase_line uuid;
    receipt_request uuid := gen_random_uuid();
    bill public.supplier_bills%ROWTYPE;
    payment_request uuid := gen_random_uuid();
    draft uuid;
    purchase public.purchases%ROWTYPE;
    lines jsonb;
    rejected boolean := false;
BEGIN
    INSERT INTO auth.users(id,email) VALUES (actor, actor::text || '@example.invalid');
    UPDATE public.user_profiles SET role = 'admin', is_active = true WHERE id = actor;
    PERFORM set_config('request.jwt.claim.sub', actor::text, true);
    INSERT INTO public.customers(id,company_name,contact_person,email,phone,is_active)
    VALUES (customer,'Fixture','Fixture',customer::text || '@example.invalid','000',true);
    INSERT INTO public.suppliers(id,company_name,is_active) VALUES (supplier,'Fixture',true);
    INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
    VALUES (product,product::text,'Fixture',4000,'CDF',true);
    INSERT INTO public.warehouse_locations(id,name,is_active)
    VALUES (warehouse,warehouse::text,true);
    lines := jsonb_build_array(jsonb_build_object('product_id',product,'quantity',2,'unit_cost',1500));
    draft := public.save_invoice_draft(NULL,customer,'CDF',jsonb_build_object('items',lines,'notes','original'));
    INSERT INTO p1a_results VALUES ('draft_persisted_and_updated',
        public.save_invoice_draft(draft,customer,'CDF',jsonb_build_object('items',lines,'notes','updated')) = draft);
    INSERT INTO p1a_results VALUES ('draft_without_receivable',
        EXISTS (SELECT 1 FROM public.invoice_drafts WHERE id = draft AND payload->>'notes' = 'updated')
        AND NOT EXISTS (SELECT 1 FROM public.invoices WHERE customer_id = customer));
    BEGIN
        PERFORM public.create_purchase_with_items(supplier,
            lines || jsonb_build_array(jsonb_build_object('product_id',gen_random_uuid(),'quantity',1,'unit_cost',1000)),
            'CDF',1,NULL);
    EXCEPTION WHEN foreign_key_violation THEN rejected := true;
    END;
    INSERT INTO p1a_results VALUES ('invalid_line_rolls_back_header',
        rejected AND NOT EXISTS (SELECT 1 FROM public.purchases WHERE supplier_id = supplier));
    purchase := public.create_purchase_with_items(supplier,lines,'CDF',1,NULL);
    INSERT INTO p1a_results VALUES ('atomic_purchase',
        purchase.total_amount = 3000 AND purchase.received_by IS NULL
        AND (SELECT count(*) FROM public.purchase_items WHERE purchase_id = purchase.id) = 1);
    SELECT id INTO STRICT purchase_line FROM public.purchase_items WHERE purchase_id = purchase.id;
    PERFORM public.receive_purchase_item(purchase_line,warehouse,1,receipt_request);
    PERFORM public.receive_purchase_item(purchase_line,warehouse,1,receipt_request);
    INSERT INTO p1a_results VALUES ('partial_receipt_and_idempotency',
        EXISTS (SELECT 1 FROM public.purchases p WHERE p.id = purchase.id
                AND p.status = 'partial' AND p.payment_status = 'pending')
        AND (SELECT received_quantity FROM public.purchase_items WHERE id = purchase_line) = 1
        AND (SELECT quantity FROM public.inventory_stock WHERE product_id = product AND warehouse_id = warehouse) = 1
        AND (SELECT count(*) FROM public.purchase_receipts WHERE purchase_item_id = purchase_line) = 1);
    bill := public.register_supplier_bill(purchase.id,'SUPPLIER-TEST',current_date+30,3000);
    INSERT INTO p1a_results VALUES ('supplier_bill_is_separate_from_receipt',
        bill.amount = 3000 AND bill.amount_paid = 0
        AND (public.register_supplier_bill(purchase.id,'SUPPLIER-TEST',current_date+30,3000)).id = bill.id
        AND (SELECT status FROM public.purchases WHERE id = purchase.id) = 'partial'
        AND (SELECT received_quantity FROM public.purchase_items WHERE id = purchase_line) = 1);
    PERFORM public.record_supplier_bill_payment(bill.id,1200,'CDF','Test partiel',payment_request);
    PERFORM public.record_supplier_bill_payment(bill.id,1200,'CDF','Test partiel',payment_request);
    INSERT INTO p1a_results VALUES ('supplier_partial_payment_and_idempotency',
        (SELECT amount - amount_paid FROM public.supplier_bills WHERE id = bill.id) = 1800
        AND (SELECT count(*) FROM public.supplier_bill_payments WHERE bill_id = bill.id) = 1
        AND (SELECT payment_status FROM public.purchases WHERE id = purchase.id) = 'partial');
    PERFORM public.record_supplier_bill_payment(bill.id,1800,'CDF','Test solde',gen_random_uuid());
    INSERT INTO p1a_results VALUES ('supplier_balance_settled_without_stock_change',
        (SELECT amount - amount_paid FROM public.supplier_bills WHERE id = bill.id) = 0
        AND (SELECT payment_status FROM public.purchases WHERE id = purchase.id) = 'paid'
        AND (SELECT received_quantity FROM public.purchase_items WHERE id = purchase_line) = 1);
END;
$verify$;
SELECT scenario, passed FROM p1a_results ORDER BY scenario;
ROLLBACK;
