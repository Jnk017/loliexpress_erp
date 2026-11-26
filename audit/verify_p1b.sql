-- P1.b.2 — pile vierge après 017. Cinq résultats doivent être vrais.
BEGIN;
CREATE TEMP TABLE workspace_checks(scenario text PRIMARY KEY, passed boolean NOT NULL);
DO $verify$
DECLARE
    admin_id uuid := gen_random_uuid();
    sales_id uuid := gen_random_uuid();
    finance_id uuid := gen_random_uuid();
    buyer_id uuid := gen_random_uuid();
    client_id uuid := gen_random_uuid();
    customer_id uuid := gen_random_uuid();
    supplier_id uuid := gen_random_uuid();
    item_id uuid := gen_random_uuid();
    progress jsonb;
    refused boolean := false;
BEGIN
    INSERT INTO auth.users(id,email)
    SELECT id,id::text||'@example.invalid'
    FROM unnest(ARRAY[admin_id,sales_id,finance_id,buyer_id,client_id]) AS ids(id);
    UPDATE public.user_profiles SET role = 'admin',is_active = true WHERE id = admin_id;
    UPDATE public.user_profiles SET role = 'sales_rep',is_active = true WHERE id = sales_id;
    UPDATE public.user_profiles SET role = 'comptable',is_active = true WHERE id = finance_id;
    UPDATE public.user_profiles SET role = 'acheteur',is_active = true WHERE id = buyer_id;
    PERFORM set_config('request.jwt.claim.sub',sales_id::text,true);
    progress := public.get_workspace_setup_progress();
    INSERT INTO workspace_checks VALUES ('commercial_empty_state',
        progress = '{"assigned_customer":false,"first_order":false}'::jsonb);
    PERFORM set_config('request.jwt.claim.sub',admin_id::text,true);
    PERFORM public.update_company_settings('{"company_name":"Fixture UX","company_address":"Adresse fixture"}');
    INSERT INTO public.customers(id,company_name,contact_person,email,phone,commercial_id,is_active)
    VALUES (customer_id,'Fixture','Fixture',customer_id::text||'@example.invalid','000',sales_id,true);
    INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
    VALUES (item_id,item_id::text,'Fixture',4000,'CDF',true);
    INSERT INTO public.suppliers(id,company_name,is_active) VALUES (supplier_id,'Fixture',true);
    PERFORM set_config('request.jwt.claim.sub',sales_id::text,true);
    PERFORM public.create_order_with_items(customer_id,
        jsonb_build_array(jsonb_build_object('product_id',item_id,'quantity',1)));
    INSERT INTO workspace_checks VALUES ('commercial_progress_updates',
        public.get_workspace_setup_progress() = '{"assigned_customer":true,"first_order":true}'::jsonb);
    PERFORM set_config('request.jwt.claim.sub',finance_id::text,true);
    INSERT INTO workspace_checks VALUES ('comptable_progress_is_role_specific',
        public.get_workspace_setup_progress() = '{"company_profile":true,"first_invoice":false,"first_payment":false}'::jsonb);
    PERFORM set_config('request.jwt.claim.sub',buyer_id::text,true);
    PERFORM public.create_purchase_with_items(supplier_id,
        jsonb_build_array(jsonb_build_object('product_id',item_id,'quantity',1,'unit_cost',1000)),
        'CDF',1,NULL);
    INSERT INTO workspace_checks VALUES ('acheteur_progress_updates',
        public.get_workspace_setup_progress() = '{"first_supplier":true,"first_purchase":true}'::jsonb);
    PERFORM set_config('request.jwt.claim.sub',client_id::text,true);
    BEGIN
        PERFORM public.get_workspace_setup_progress();
    EXCEPTION WHEN insufficient_privilege THEN refused := true;
    END;
    INSERT INTO workspace_checks VALUES ('client_cannot_use_internal_progress',refused);
END;
$verify$;
SELECT scenario,passed FROM workspace_checks ORDER BY scenario;
ROLLBACK;
