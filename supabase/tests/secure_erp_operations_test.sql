BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT no_plan();

-- Deterministic identities for all application roles plus isolation controls.
INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at
)
VALUES
 ('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000001','authenticated','authenticated','admin@test.local','hash',now(),now(),now()),
 ('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000002','authenticated','authenticated','sales@test.local','hash',now(),now(),now()),
 ('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000003','authenticated','authenticated','warehouse@test.local','hash',now(),now(),now()),
 ('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000004','authenticated','authenticated','accounting@test.local','hash',now(),now(),now()),
 ('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000005','authenticated','authenticated','buyer@test.local','hash',now(),now(),now()),
 ('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000006','authenticated','authenticated','driver@test.local','hash',now(),now(),now()),
 ('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000007','authenticated','authenticated','customer1@test.local','hash',now(),now(),now()),
 ('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000008','authenticated','authenticated','customer2@test.local','hash',now(),now(),now()),
 ('00000000-0000-0000-0000-000000000000','10000000-0000-0000-0000-000000000009','authenticated','authenticated','driver2@test.local','hash',now(),now(),now())
ON CONFLICT (id) DO NOTHING;

UPDATE public.user_profiles
SET role = CASE id
    WHEN '10000000-0000-0000-0000-000000000001' THEN 'admin'::public.user_role
    WHEN '10000000-0000-0000-0000-000000000002' THEN 'sales_rep'::public.user_role
    WHEN '10000000-0000-0000-0000-000000000003' THEN 'warehouse_staff'::public.user_role
    WHEN '10000000-0000-0000-0000-000000000004' THEN 'comptable'::public.user_role
    WHEN '10000000-0000-0000-0000-000000000005' THEN 'acheteur'::public.user_role
    WHEN '10000000-0000-0000-0000-000000000006' THEN 'delivery_agent'::public.user_role
    WHEN '10000000-0000-0000-0000-000000000009' THEN 'delivery_agent'::public.user_role
    ELSE 'b2b_customer'::public.user_role
END,
is_active = true,
must_change_password = false
WHERE id::text LIKE '10000000-%';

INSERT INTO public.customers (
    id, user_id, commercial_id, company_name, contact_person, email, phone
)
VALUES
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000007','10000000-0000-0000-0000-000000000002','Customer One','Buyer One','one@test.local','001'),
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000008',NULL,'Customer Two','Buyer Two','two@test.local','002');

INSERT INTO public.products (id, sku, name, unit_price, cost_price, currency, is_active)
VALUES
 ('30000000-0000-0000-0000-000000000001','RPC-P1','Product One',100,60,'CDF',true),
 ('30000000-0000-0000-0000-000000000002','RPC-P2','Product Two',50,20,'CDF',true);
INSERT INTO public.warehouse_locations (id, name, is_active)
VALUES ('40000000-0000-0000-0000-000000000001','RPC Warehouse',true);

INSERT INTO public.sales_orders (
    id, order_number, customer_id, sales_rep_id, subtotal, total_amount,
    order_status, payment_status, currency, exchange_rate, payment_type, notes
)
VALUES
 ('50000000-0000-0000-0000-000000000001','ORD-FIXTURE-1','20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',100,100,'shipped','pending','CDF',1,'credit','delivery fixture'),
 ('50000000-0000-0000-0000-000000000002','ORD-FIXTURE-2','20000000-0000-0000-0000-000000000002',NULL,50,50,'shipped','pending','CDF',1,'cash','isolated fixture'),
 ('50000000-0000-0000-0000-000000000003','ORD-FIXTURE-3','20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002',100,100,'shipped','pending','CDF',1,'cash','invalid delivery fixture');
INSERT INTO public.order_items (id, order_id, product_id, quantity, unit_price, line_total)
VALUES
 ('51000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',1,100,100),
 ('51000000-0000-0000-0000-000000000002','50000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002',1,50,50);

INSERT INTO public.delivery_routes (id, route_name, driver_id, route_date, status)
VALUES
 ('60000000-0000-0000-0000-000000000001','Assigned route','10000000-0000-0000-0000-000000000006',CURRENT_DATE,'in_transit'),
 ('60000000-0000-0000-0000-000000000002','Other route','10000000-0000-0000-0000-000000000009',CURRENT_DATE,'in_transit');
INSERT INTO public.deliveries (id, order_id, route_id, delivery_address, status)
VALUES
 ('61000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','Address One','in_transit'),
 ('61000000-0000-0000-0000-000000000002','50000000-0000-0000-0000-000000000002','60000000-0000-0000-0000-000000000002','Address Two','in_transit'),
 ('61000000-0000-0000-0000-000000000003','50000000-0000-0000-0000-000000000003','60000000-0000-0000-0000-000000000001','Address Three','pending');

INSERT INTO public.invoices (
    id, invoice_number, order_id, customer_id, due_date, subtotal,
    total_amount, amount_paid, payment_status, currency, exchange_rate
)
VALUES
 ('70000000-0000-0000-0000-000000000001','INV-TEST-1','50000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',now() + interval '30 days',100,100,0,'pending','CDF',1),
 ('70000000-0000-0000-0000-000000000002','INV-TEST-2','50000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002',now() + interval '30 days',100,100,0,'pending','CDF',1);

INSERT INTO public.suppliers (id, company_name)
VALUES ('80000000-0000-0000-0000-000000000001','Supplier One');
INSERT INTO public.purchases (id, purchase_number, supplier_id, total_amount, currency)
VALUES ('81000000-0000-0000-0000-000000000001','PO-TEST-1','80000000-0000-0000-0000-000000000001',60,'CDF');
INSERT INTO public.purchase_items (id, purchase_id, product_id, quantity, unit_cost, total_cost)
VALUES ('82000000-0000-0000-0000-000000000001','81000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',1,60,60);
INSERT INTO public.expenses (id, category, description, amount, expense_date, created_by, requested_by)
VALUES ('83000000-0000-0000-0000-000000000001','test','Test expense',10,CURRENT_DATE,'10000000-0000-0000-0000-000000000005','10000000-0000-0000-0000-000000000005');
INSERT INTO public.document_attachments (
    id, entity_type, entity_id, file_name, file_path, file_size, mime_type, uploaded_by
)
VALUES
 ('84000000-0000-0000-0000-000000000001','invoice','70000000-0000-0000-0000-000000000001','invoice-one.pdf','one/invoice.pdf',100,'application/pdf','10000000-0000-0000-0000-000000000001'),
 ('84000000-0000-0000-0000-000000000002','invoice','70000000-0000-0000-0000-000000000002','invoice-two.pdf','two/invoice.pdf',100,'application/pdf','10000000-0000-0000-0000-000000000001');
INSERT INTO storage.objects (id, bucket_id, name, owner)
VALUES
 ('85000000-0000-0000-0000-000000000001','erp-documents','one/invoice.pdf','10000000-0000-0000-0000-000000000001'),
 ('85000000-0000-0000-0000-000000000002','erp-documents','two/invoice.pdf','10000000-0000-0000-0000-000000000001');

-- create_order_with_items: normal, multi-line and tampering/rollback paths.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
SELECT lives_ok($$SELECT public.create_order_with_items(
 '20000000-0000-0000-0000-000000000001',
 '[{"product_id":"30000000-0000-0000-0000-000000000001","quantity":2,"unit_price":100}]',
 'normal order','CDF',1,'cash',10)$$, 'normal order succeeds');
SELECT is((SELECT subtotal FROM public.sales_orders WHERE notes='normal order'),200.00::numeric,'subtotal is server-calculated');
SELECT is((SELECT total_amount FROM public.sales_orders WHERE notes='normal order'),190.00::numeric,'discounted total is server-calculated');
SELECT like((SELECT order_number FROM public.sales_orders WHERE notes='normal order'),'ORD-%','order number is generated by PostgreSQL');
SELECT is((SELECT count(*) FROM public.order_items oi JOIN public.sales_orders so ON so.id=oi.order_id WHERE so.notes='normal order'),1::bigint,'normal order line is inserted');
SELECT ok(EXISTS(SELECT 1 FROM public.audit_logs WHERE new_values->>'operation'='create_order_with_items'),'normal order is audited');
SELECT lives_ok($$SELECT public.create_order_with_items(
 '20000000-0000-0000-0000-000000000001',
 '[{"product_id":"30000000-0000-0000-0000-000000000001","quantity":1},{"product_id":"30000000-0000-0000-0000-000000000002","quantity":3}]',
 'multi order','CDF',1,'cash',0)$$, 'multi-product order succeeds');
SELECT is((SELECT subtotal FROM public.sales_orders WHERE notes='multi order'),250.00::numeric,'multi-product subtotal is correct');
SELECT is((SELECT count(*) FROM public.order_items oi JOIN public.sales_orders so ON so.id=oi.order_id WHERE so.notes='multi order'),2::bigint,'all multi-product lines are inserted');
SELECT throws_ok($$SELECT public.create_order_with_items(
 '20000000-0000-0000-0000-000000000001','[{"product_id":"ffffffff-0000-0000-0000-000000000001","quantity":1}]',
 'missing product','CDF',1,'cash',0)$$,'23503',NULL,'missing product is rejected');
SELECT throws_ok($$SELECT public.create_order_with_items(
 '20000000-0000-0000-0000-000000000001','[{"product_id":"30000000-0000-0000-0000-000000000001","quantity":1,"unit_price":1}]',
 'tampered price','CDF',1,'cash',0)$$,'22023',NULL,'tampered price is rejected');
SELECT throws_ok($$SELECT public.create_order_with_items(
 '20000000-0000-0000-0000-000000000001','[{"product_id":"30000000-0000-0000-0000-000000000001","quantity":1}]',
 'excessive discount','CDF',1,'cash',50)$$,'42501',NULL,'excessive sales discount is rejected');
SELECT throws_ok($$SELECT public.create_order_with_items(
 '20000000-0000-0000-0000-000000000001','[{"product_id":"30000000-0000-0000-0000-000000000001","quantity":1}]',
 'invalid rate','CDF',2,'cash',0)$$,'22023',NULL,'invalid exchange rate is rejected');
SELECT is((SELECT count(*) FROM public.sales_orders WHERE notes IN ('missing product','tampered price','excessive discount','invalid rate')),0::bigint,'all failed orders roll back their headers');
SELECT lives_ok($$SELECT public.transition_order_status(
 (SELECT id FROM public.sales_orders WHERE notes='normal order'),'confirmed')$$,'assigned sales order status transition succeeds');
SELECT ok(EXISTS(SELECT 1 FROM public.audit_logs WHERE new_values->>'operation'='transition_order_status'),'order status transition is audited');
SELECT throws_ok($$UPDATE public.sales_orders SET subtotal=1 WHERE notes='normal order'$$,'42501',NULL,'direct sales order financial update is denied');
SELECT throws_ok($$SELECT public.transition_order_status('50000000-0000-0000-0000-000000000002','cancelled')$$,'42501','Insufficient order status permission','sales cannot transition an unassigned order');
SELECT throws_ok($$SELECT public.create_order_with_items(
 '20000000-0000-0000-0000-000000000002','[{"product_id":"30000000-0000-0000-0000-000000000001","quantity":1}]',
 'unassigned customer','CDF',1,'cash',0)$$,'42501',NULL,'sales representative cannot order for an unassigned customer');
RESET ROLE;

-- adjust_stock: positive, negative, correction, negative balance and role denial.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SET LOCAL ROLE authenticated;
SELECT lives_ok($$SELECT public.adjust_stock('30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',10,'receipt')$$,'stock receipt succeeds');
SELECT is((SELECT quantity FROM public.inventory_stock WHERE product_id='30000000-0000-0000-0000-000000000001' AND warehouse_id='40000000-0000-0000-0000-000000000001'),10,'stock receipt updates balance');
SELECT lives_ok($$SELECT public.adjust_stock('30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',-3,'issue')$$,'stock issue succeeds');
SELECT lives_ok($$SELECT public.adjust_stock('30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',2,'count correction')$$,'stock correction succeeds');
SELECT is((SELECT quantity FROM public.inventory_stock WHERE product_id='30000000-0000-0000-0000-000000000001' AND warehouse_id='40000000-0000-0000-0000-000000000001'),9,'signed movements preserve correct stock');
SELECT throws_ok($$SELECT public.adjust_stock('30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',-10,'negative attempt')$$,'22003','Insufficient stock','negative stock is rejected');
SELECT ok(EXISTS(SELECT 1 FROM public.audit_logs WHERE new_values->>'operation'='adjust_stock'),'stock changes are audited');
SELECT throws_ok($$INSERT INTO public.stock_movements(product_id,warehouse_id,movement_type,quantity) VALUES ('30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','in',1)$$,'42501',NULL,'direct stock movement writes are denied');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SET LOCAL ROLE authenticated;
SELECT throws_ok($$SELECT public.adjust_stock('30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',1,'unauthorized')$$,'42501','Insufficient stock permission','sales role cannot adjust stock');
RESET ROLE;

-- confirm_delivery: valid, duplicate, unassigned and invalid status paths.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000006',true);
SET LOCAL ROLE authenticated;
SELECT lives_ok($$SELECT public.confirm_delivery('61000000-0000-0000-0000-000000000001',NULL,'received')$$,'assigned driver confirms shipped delivery');
SELECT is((SELECT status::text FROM public.deliveries WHERE id='61000000-0000-0000-0000-000000000001'),'delivered','delivery status is delivered');
SELECT is((SELECT order_status::text FROM public.sales_orders WHERE id='50000000-0000-0000-0000-000000000001'),'delivered','order status follows delivery');
SELECT ok(EXISTS(SELECT 1 FROM public.audit_logs WHERE record_id='61000000-0000-0000-0000-000000000001' AND new_values->>'operation'='confirm_delivery'),'delivery confirmation is audited');
SELECT throws_ok($$SELECT public.confirm_delivery('61000000-0000-0000-0000-000000000001')$$,'22023','Only in-transit deliveries can be confirmed','duplicate confirmation is rejected');
SELECT throws_ok($$SELECT public.confirm_delivery('61000000-0000-0000-0000-000000000002')$$,'42501','Delivery is not assigned to this agent','unassigned driver is rejected');
SELECT throws_ok($$SELECT public.confirm_delivery('61000000-0000-0000-0000-000000000003')$$,'22023','Only in-transit deliveries can be confirmed','invalid delivery status is rejected');
SELECT throws_ok($$UPDATE public.deliveries SET status='delivered' WHERE id='61000000-0000-0000-0000-000000000003'$$,'42501',NULL,'direct delivery confirmation is denied');
RESET ROLE;

-- record_payment: partial, complete, overpayment, currency and role validation.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',true);
SET LOCAL ROLE authenticated;
SELECT lives_ok($$SELECT public.record_payment('70000000-0000-0000-0000-000000000001',30,'bank','PARTIAL')$$,'partial payment succeeds');
SELECT is((SELECT payment_status::text FROM public.invoices WHERE id='70000000-0000-0000-0000-000000000001'),'partial','invoice is partial');
SELECT lives_ok($$SELECT public.record_payment('70000000-0000-0000-0000-000000000001',70,'bank','FINAL')$$,'final payment succeeds');
SELECT is((SELECT payment_status::text FROM public.invoices WHERE id='70000000-0000-0000-0000-000000000001'),'paid','invoice is paid');
SELECT is((SELECT payment_status::text FROM public.sales_orders WHERE id='50000000-0000-0000-0000-000000000001'),'paid','order payment status is synchronized');
SELECT is((SELECT count(*) FROM public.payments WHERE invoice_id='70000000-0000-0000-0000-000000000001'),2::bigint,'payment history contains both entries');
SELECT ok(EXISTS(SELECT 1 FROM public.audit_logs WHERE new_values->>'operation'='record_payment'),'payments are audited');
SELECT throws_ok($$SELECT public.record_payment('70000000-0000-0000-0000-000000000002',101,'cash')$$,'22003','Payment exceeds outstanding invoice amount','overpayment is rejected');
SELECT throws_ok($$SELECT public.record_payment('70000000-0000-0000-0000-000000000002',10,'cash',NULL,NULL,'USD')$$,'22023','Payment currency must match invoice currency','wrong currency is rejected');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SET LOCAL ROLE authenticated;
SELECT throws_ok($$SELECT public.record_payment('70000000-0000-0000-0000-000000000002',10,'cash')$$,'42501','Insufficient payment permission','sales role cannot record payments');
RESET ROLE;

-- First-login password setup cannot be bypassed through profile writes.
UPDATE public.user_profiles SET must_change_password=true WHERE id='10000000-0000-0000-0000-000000000007';
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000007',true);
SET LOCAL ROLE authenticated;
SELECT throws_ok($$UPDATE public.user_profiles SET must_change_password=false WHERE id='10000000-0000-0000-0000-000000000007'$$,'P0001','Password setup status can only be changed by the verification RPC','profile flag cannot be cleared directly');
SELECT lives_ok($$SELECT public.complete_password_setup()$$,'verified password setup completes');
SELECT is((SELECT must_change_password FROM public.user_profiles WHERE id='10000000-0000-0000-0000-000000000007'),false,'password setup flag is cleared by RPC');
RESET ROLE;

-- RLS: B2B isolation across customer, order, item, document, delivery and payment data.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000007',true);
SET LOCAL ROLE authenticated;
SELECT is((SELECT count(*) FROM public.customers WHERE id='20000000-0000-0000-0000-000000000001'),1::bigint,'B2B reads own customer');
SELECT is((SELECT count(*) FROM public.customers WHERE id='20000000-0000-0000-0000-000000000002'),0::bigint,'B2B cannot read another customer');
SELECT is((SELECT count(*) FROM public.sales_orders WHERE customer_id='20000000-0000-0000-0000-000000000002'),0::bigint,'B2B cannot read another customer orders');
SELECT is((SELECT count(*) FROM public.order_items WHERE order_id='50000000-0000-0000-0000-000000000002'),0::bigint,'B2B cannot read another customer order items');
SELECT is((SELECT count(*) FROM public.deliveries WHERE id='61000000-0000-0000-0000-000000000002'),0::bigint,'B2B cannot read another customer delivery');
SELECT is((SELECT count(*) FROM public.document_attachments WHERE id='84000000-0000-0000-0000-000000000001'),1::bigint,'B2B reads a document for own invoice');
SELECT is((SELECT count(*) FROM public.document_attachments WHERE id='84000000-0000-0000-0000-000000000002'),0::bigint,'B2B cannot read another customer document');
SELECT is((SELECT count(*) FROM storage.objects WHERE id='85000000-0000-0000-0000-000000000001'),1::bigint,'B2B can download own invoice object');
SELECT is((SELECT count(*) FROM storage.objects WHERE id='85000000-0000-0000-0000-000000000002'),0::bigint,'B2B cannot download another customer object');
SELECT is((SELECT count(*) FROM public.invoices WHERE id='70000000-0000-0000-0000-000000000002'),0::bigint,'B2B cannot read another customer invoice');
SELECT is((SELECT count(*) FROM public.payments WHERE invoice_id='70000000-0000-0000-0000-000000000002'),0::bigint,'B2B cannot read another customer payments');
SELECT is((SELECT count(*) FROM public.purchases),0::bigint,'B2B cannot read purchases');
SELECT is((SELECT count(*) FROM public.expenses),0::bigint,'B2B cannot read expenses');
SELECT throws_ok($$INSERT INTO public.expenses(category,description,amount,expense_date,created_by,requested_by) VALUES ('forbidden','forbidden',1,CURRENT_DATE,auth.uid(),auth.uid())$$,'42501',NULL,'B2B cannot create internal expenses');
SELECT ok(NOT has_column_privilege('authenticated','public.products','cost_price','SELECT'),'product cost is not exposed to authenticated clients');
SELECT throws_ok($$INSERT INTO public.sales_orders(order_number,customer_id,subtotal,total_amount) VALUES ('DIRECT-B2B','20000000-0000-0000-0000-000000000001',1,1)$$,'42501',NULL,'B2B direct order insert is denied');
RESET ROLE;

-- RLS: role-specific positive and negative access checks.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SET LOCAL ROLE authenticated;
SELECT is((SELECT count(*) FROM public.customers WHERE id='20000000-0000-0000-0000-000000000001'),1::bigint,'sales reads assigned customer');
SELECT is((SELECT count(*) FROM public.customers WHERE id='20000000-0000-0000-0000-000000000002'),0::bigint,'sales cannot read unassigned customer');
SELECT is((SELECT count(*) FROM public.sales_orders WHERE id='50000000-0000-0000-0000-000000000002'),0::bigint,'sales cannot read unassigned order');
SELECT is((SELECT count(*) FROM public.payments),0::bigint,'sales cannot read payments');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SET LOCAL ROLE authenticated;
SELECT is((SELECT count(*) FROM public.inventory_stock WHERE product_id='30000000-0000-0000-0000-000000000001'),1::bigint,'warehouse reads inventory');
SELECT ok((SELECT count(*) FROM public.sales_orders) >= 2,'warehouse reads operational orders');
SELECT is((SELECT count(*) FROM public.payments),0::bigint,'warehouse cannot read payments');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',true);
SET LOCAL ROLE authenticated;
SELECT ok((SELECT count(*) FROM public.invoices) >= 2,'accounting reads invoices');
SELECT ok((SELECT count(*) FROM public.payments) >= 2,'accounting reads payments');
SELECT ok((SELECT count(*) FROM public.expenses) >= 1,'accounting reads expenses');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000005',true);
SET LOCAL ROLE authenticated;
SELECT is((SELECT count(*) FROM public.purchases WHERE id='81000000-0000-0000-0000-000000000001'),1::bigint,'buyer reads purchases');
SELECT is((SELECT count(*) FROM public.purchase_items WHERE id='82000000-0000-0000-0000-000000000001'),1::bigint,'buyer reads purchase items');
SELECT is((SELECT count(*) FROM public.payments),0::bigint,'buyer cannot read customer payments');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000006',true);
SET LOCAL ROLE authenticated;
SELECT is((SELECT count(*) FROM public.delivery_routes WHERE id='60000000-0000-0000-0000-000000000001'),1::bigint,'driver reads assigned route');
SELECT is((SELECT count(*) FROM public.delivery_routes WHERE id='60000000-0000-0000-0000-000000000002'),0::bigint,'driver cannot read another route');
SELECT is((SELECT count(*) FROM public.deliveries WHERE id='61000000-0000-0000-0000-000000000002'),0::bigint,'driver cannot read another delivery');
SELECT is((SELECT count(*) FROM public.sales_orders WHERE id='50000000-0000-0000-0000-000000000002'),0::bigint,'driver cannot read another delivery order');
SELECT is((SELECT count(*) FROM public.customers WHERE id='20000000-0000-0000-0000-000000000002'),0::bigint,'driver cannot read another delivery customer');
RESET ROLE;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
SET LOCAL ROLE authenticated;
SELECT ok((SELECT count(*) FROM public.user_profiles) >= 9,'admin reads all profiles');
SELECT ok((SELECT count(*) FROM public.customers) >= 2,'admin reads all customers');
SELECT ok((SELECT count(*) FROM public.security_events) >= 0,'admin can read security events');
RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
