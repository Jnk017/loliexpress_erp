-- P0.a — run after 000..004, with postgres on an isolated Supabase database.
-- All fixtures are rolled back. A successful run returns five passed = true rows.
BEGIN;
CREATE TEMP TABLE p0a_results (scenario text PRIMARY KEY, passed boolean NOT NULL);

SELECT set_config('request.jwt.claims', '{}', true);
DO $verify$
DECLARE
    admin_id uuid := gen_random_uuid();
    sales_id uuid := gen_random_uuid();
    customer_a uuid := gen_random_uuid();
    customer_b uuid := gen_random_uuid();
    customer_default uuid := gen_random_uuid();
    product_id uuid := gen_random_uuid();
    warehouse_id uuid := gen_random_uuid();
    sale public.sales_orders%ROWTYPE;
    stock public.inventory_stock%ROWTYPE;
    items jsonb;
    price_a numeric;
    price_b numeric;
    price_default numeric;
    denied_discount boolean := false;
    denied_price_write boolean := false;
    denied_stale_price boolean := false;
    denied_negative_stock boolean := false;
    denied_transition boolean := false;
    denied_password_setup boolean := false;
    product_sku text := 'p0a-' || product_id::text;
BEGIN
    INSERT INTO auth.users(id, email) VALUES
        (admin_id, admin_id::text || '@example.invalid'),
        (sales_id, sales_id::text || '@example.invalid');
    UPDATE public.user_profiles SET role = 'admin', is_active = true WHERE id = admin_id;
    UPDATE public.user_profiles SET role = 'sales_rep', is_active = true WHERE id = sales_id;
    PERFORM set_config('request.jwt.claim.sub', admin_id::text, true);
    INSERT INTO public.customers(id, company_name, contact_person, email, phone, commercial_id, is_active)
    VALUES
        (customer_a, 'A', 'Test', customer_a::text || '@example.invalid', '000000000', sales_id, true),
        (customer_b, 'B', 'Test', customer_b::text || '@example.invalid', '000000000', sales_id, true),
        (customer_default, 'C', 'Test', customer_default::text || '@example.invalid', '000000000', sales_id, true);
    INSERT INTO public.products(id, sku, name, unit_price, currency, is_active)
    VALUES (product_id, product_sku, 'Paquet d’eau', 4000, 'CDF', true);
    INSERT INTO public.warehouse_locations(id, name, is_active)
    VALUES (warehouse_id, warehouse_id::text, true);

    PERFORM public.set_customer_product_price(customer_a, product_id, 3850, 'CDF');
    PERFORM public.set_customer_product_price(customer_b, product_id, 3565, 'CDF');

    PERFORM set_config('request.jwt.claim.sub', sales_id::text, true);
    price_a := public.order_unit_price(customer_a, product_id, 'CDF');
    price_b := public.order_unit_price(customer_b, product_id, 'CDF');
    price_default := public.order_unit_price(customer_default, product_id, 'CDF');
    items := jsonb_build_array(jsonb_build_object('product_id', product_id, 'quantity', 2, 'unit_price', price_a));
    BEGIN
        PERFORM public.set_customer_product_price(customer_a, product_id, 1, 'CDF');
    EXCEPTION WHEN insufficient_privilege THEN denied_price_write := true;
    END;
    BEGIN
        PERFORM public.create_order_with_items(customer_a, items, NULL, 'CDF', 1, 'cash', 1);
    EXCEPTION WHEN insufficient_privilege THEN denied_discount := true;
    END;
    BEGIN
        PERFORM public.create_order_with_items(customer_default, items);
    EXCEPTION WHEN invalid_parameter_value THEN denied_stale_price := true;
    END;
    sale := public.create_order_with_items(customer_a, items);
    INSERT INTO p0a_results VALUES ('order_and_admin_pricing',
        price_a = 3850 AND price_b = 3565 AND price_default = 4000
        AND sale.total_amount = 7700 AND denied_discount AND denied_price_write AND denied_stale_price
        AND has_function_privilege('authenticated',
            'public.create_order_with_items(uuid,jsonb,text,text,numeric,text,numeric)', 'EXECUTE')
        AND NOT has_table_privilege('authenticated', 'public.sales_orders', 'INSERT')
        AND to_regprocedure('public.create_order_with_items(uuid,jsonb,text)') IS NULL);

    BEGIN
        PERFORM public.transition_order_status(sale.id, 'delivered');
    EXCEPTION WHEN invalid_parameter_value THEN denied_transition := true;
    END;
    sale := public.transition_order_status(sale.id, 'confirmed', 'Test validation');
    INSERT INTO p0a_results VALUES ('transition_and_audit',
        denied_transition AND sale.order_status = 'confirmed'
        AND EXISTS (SELECT 1 FROM public.audit_logs WHERE record_id = sale.id AND action_type = 'update')
        AND has_function_privilege('authenticated', 'public.transition_order_status(uuid,public.order_status,text)', 'EXECUTE'));

    PERFORM set_config('request.jwt.claim.sub', admin_id::text, true);
    stock := public.adjust_stock(product_id, warehouse_id, 10, 'Test stock');
    BEGIN
        PERFORM public.adjust_stock(product_id, warehouse_id, -11, 'Test refus');
    EXCEPTION WHEN numeric_value_out_of_range THEN denied_negative_stock := true;
    END;
    INSERT INTO p0a_results VALUES ('stock_and_rollback',
        denied_negative_stock AND stock.quantity = 10 AND
        (SELECT count(*) FROM public.stock_movements m WHERE m.product_id = stock.product_id
            AND m.warehouse_id = stock.warehouse_id) = 1
        AND has_function_privilege('authenticated', 'public.adjust_stock(uuid,uuid,integer,text,uuid,text)', 'EXECUTE')
        AND to_regprocedure('public.adjust_stock(uuid,uuid,integer,text)') IS NULL);

    UPDATE public.user_profiles SET must_change_password = true WHERE id = sales_id;
    PERFORM set_config('request.jwt.claim.sub', sales_id::text, true);
    BEGIN
        PERFORM public.complete_password_setup();
    EXCEPTION WHEN insufficient_privilege THEN denied_password_setup := true;
    END;
    UPDATE auth.users SET encrypted_password = 'p0a-fixture-password-hash' WHERE id = sales_id;
    INSERT INTO p0a_results VALUES ('password_setup',
        denied_password_setup AND public.complete_password_setup()
        AND has_function_privilege('authenticated', 'public.complete_password_setup()', 'EXECUTE'));
    INSERT INTO p0a_results VALUES ('password_flag_cleared',
        (SELECT NOT must_change_password FROM public.user_profiles WHERE id = sales_id));
END;
$verify$;

SELECT scenario, passed FROM p0a_results ORDER BY scenario;
ROLLBACK;
