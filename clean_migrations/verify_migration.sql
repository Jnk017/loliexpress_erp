\set ON_ERROR_STOP on
BEGIN;
DO $$
DECLARE missing text; role_count integer; business_rows bigint; wrong_rls text;
BEGIN
  SELECT string_agg(required,', ') INTO missing FROM unnest(ARRAY['current_user_role','create_order_with_items','adjust_stock','confirm_delivery','record_payment','update_user_role','update_user_status','update_exchange_rate','complete_password_setup','transition_order_status','get_admin_dashboard','get_daily_report','get_weekly_report','get_monthly_report','get_quarterly_report','get_annual_report','get_sales_by_category','get_user_productivity_metrics','get_all_users_summary','update_feature_usage_stats','detect_suspicious_transactions','detect_unauthorized_access','detect_inventory_anomalies','calculate_user_risk_scores','get_admin_sales_report','get_admin_finance_report','get_admin_operations_report','get_admin_total_report']) required WHERE NOT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname=required);
  IF missing IS NOT NULL THEN RAISE EXCEPTION 'Missing RPCs: %',missing; END IF;
  SELECT count(*) INTO role_count FROM public.roles WHERE name=ANY(ARRAY['admin','commercial_staff','warehouse_staff','delivery_agent','comptable','acheteur','client_b2b']) AND is_system;
  IF role_count<>7 THEN RAISE EXCEPTION 'Expected 7 system roles, found %',role_count; END IF;
  SELECT string_agg(tablename,', ') INTO wrong_rls FROM pg_tables WHERE schemaname='public' AND NOT rowsecurity;
  IF wrong_rls IS NOT NULL THEN RAISE EXCEPTION 'RLS disabled on public tables: %',wrong_rls; END IF;
  IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='exchange_rates' AND column_name IN('currency_pair','effective_at')) THEN RAISE EXCEPTION 'Legacy exchange_rates columns remain'; END IF;
  IF (SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='exchange_rates' AND column_name=ANY(ARRAY['base_currency','quote_currency','rate','valid_from','valid_until','is_active','created_by','created_at']))<>8 THEN RAISE EXCEPTION 'exchange_rates schema is incomplete'; END IF;
  IF (SELECT pg_get_function_result(p.oid) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname='current_user_role' LIMIT 1)<>'text' THEN RAISE EXCEPTION 'current_user_role must return text'; END IF;
  IF EXISTS(SELECT 1 FROM auth.users WHERE email=ANY(ARRAY['admin@loliexpress.com','sales@loliexpress.com','warehouse@loliexpress.com','customer@loliexpress.com'])) THEN RAISE EXCEPTION 'Demo auth accounts found'; END IF;
  SELECT (SELECT count(*) FROM public.customers)+(SELECT count(*) FROM public.sales_orders)+(SELECT count(*) FROM public.order_items)+(SELECT count(*) FROM public.invoices)+(SELECT count(*) FROM public.payments)+(SELECT count(*) FROM public.inventory_stock)+(SELECT count(*) FROM public.stock_movements) INTO business_rows;
  IF business_rows<>0 THEN RAISE EXCEPTION 'Expected an empty business database, found % rows',business_rows; END IF;
  IF (SELECT count(*) FROM pg_matviews WHERE schemaname='public' AND matviewname LIKE 'admin_%_report')<>5 THEN RAISE EXCEPTION 'Five admin materialized reports are required'; END IF;
  IF EXISTS(SELECT 1 FROM information_schema.role_column_grants WHERE table_schema='public' AND table_name='products' AND grantee='authenticated' AND column_name='cost_price') THEN RAISE EXCEPTION 'authenticated can read cost_price'; END IF;
END $$;
DO $$ DECLARE table_name text; BEGIN FOREACH table_name IN ARRAY ARRAY['roles','user_profiles','product_categories','products','warehouse_locations','customers','sales_orders','order_items','inventory_stock','stock_movements','invoices','payments','expenses','expense_approval_history','delivery_routes','deliveries','suppliers','purchases','purchase_order_items','document_attachments','notification_templates','workflow_transitions','exchange_rates','cash_registers','cash_movements','bank_accounts','bank_transactions','accounting_entries','support_tickets','system_configuration','user_permissions','security_thresholds','security_anomalies','automation_rules','rule_conditions','rule_actions','forensic_events','forensic_export_templates','forensic_export_history','investigations','investigation_tasks','investigation_evidence'] LOOP IF NOT EXISTS(SELECT 1 FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname=table_name AND t.tgname='audit_'||table_name AND NOT t.tgisinternal) THEN RAISE EXCEPTION 'Missing audit trigger on %',table_name; END IF; END LOOP; END $$;
-- Structural RLS test: every sector-sensitive table must have at least one policy.
DO $$ DECLARE table_name text; BEGIN FOREACH table_name IN ARRAY ARRAY['customers','sales_orders','order_items','inventory_stock','stock_movements','invoices','payments','expenses','deliveries','delivery_routes','suppliers','purchases','purchase_order_items','document_attachments'] LOOP IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename=table_name) THEN RAISE EXCEPTION 'No RLS policy on %',table_name; END IF; END LOOP; END $$;
-- Behavioral isolation smoke test with simulated authenticated JWTs; all fixtures roll back.
INSERT INTO auth.users(id,instance_id,aud,role,email,created_at,updated_at,raw_user_meta_data,raw_app_meta_data) VALUES
('10000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated','verify-admin@example.invalid',now(),now(),'{}','{"provider":"email","providers":["email"]}'),
('10000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated','verify-sales@example.invalid',now(),now(),'{}','{"provider":"email","providers":["email"]}'),
('10000000-0000-0000-0000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated','verify-client-a@example.invalid',now(),now(),'{}','{"provider":"email","providers":["email"]}'),
('10000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000000','authenticated','authenticated','verify-client-b@example.invalid',now(),now(),'{}','{"provider":"email","providers":["email"]}');
SELECT set_config('app.role_change_rpc','on',true);
UPDATE public.user_profiles p SET role_id=r.id,must_change_password=false FROM public.roles r WHERE p.id='10000000-0000-0000-0000-000000000001' AND r.name='admin';
UPDATE public.user_profiles p SET role_id=r.id,must_change_password=false FROM public.roles r WHERE p.id='10000000-0000-0000-0000-000000000002' AND r.name='commercial_staff';
UPDATE public.user_profiles p SET role_id=r.id,must_change_password=false FROM public.roles r WHERE p.id IN('10000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000004') AND r.name='client_b2b';
INSERT INTO public.customers(id,user_id,commercial_id,company_name,is_active) VALUES
('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000002','Tenant A',true),
('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000004',NULL,'Tenant B',true);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000003","role":"authenticated"}',true);
DO $$ BEGIN IF (SELECT count(*) FROM public.customers)<>1 THEN RAISE EXCEPTION 'client_b2b isolation failed'; END IF; END $$;
SELECT set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
DO $$ BEGIN IF (SELECT count(*) FROM public.customers)<>1 THEN RAISE EXCEPTION 'commercial_staff assignment isolation failed'; END IF; END $$;
SELECT set_config('request.jwt.claims','{"sub":"10000000-0000-0000-0000-000000000001","role":"authenticated"}',true);
DO $$ BEGIN IF (SELECT count(*) FROM public.customers)<>2 THEN RAISE EXCEPTION 'admin visibility failed'; END IF; END $$;
RESET ROLE;
ROLLBACK;
\echo 'Clean migration verification passed.'
