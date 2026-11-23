-- P0.a — capture du schéma applicatif actif lvzdlmojjoqrwxwluvih.

-- PostgreSQL 17 sur une pile Supabase vierge, exécution avec postgres.

-- Historique source : 117 versions recensées dans audit/p0a_active_catalog.json.

-- Auth, Storage et extensions internes sont provisionnés par Supabase.

-- Les tâches cron sortantes, secrets et données métier sont hors rejeu.

BEGIN;

SET LOCAL search_path = public, extensions, pg_catalog;

SET LOCAL check_function_bodies = off;

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA extensions;

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA extensions;

CREATE EXTENSION IF NOT EXISTS "pg_cron";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA vault;

-- Source 20260531233932 role_helper_functions

-- Source 20260531233940 profile_security_hardening

-- Source 20260531233950 restrict_procurement_and_config_rls

-- Source 20260531233957 notification_and_failed_login_rls

-- Source 20260531234009 repair_notification_functions

-- Source 20260531234026 numbering_totals_and_stock_sync

-- Source 20260531234034 support_tickets

-- Source 20260531235653 schedule_edge_functions

-- Source 20260601000117 security_advisor_cleanup

-- Source 20260601015021 add_delivery_agent_role

-- Source 20260601015047 final_base_tables_roles

-- Source 20260601015104 final_role_rls

-- Source 20260601015127 final_report_functions

-- Source 20260601015652 schedule_ai_insights

-- Source 20260601024105 update_initial_admin_email

-- Source 20260601034246 password_reset_otp

-- Source 20260601054612 drop_custom_password_reset_otps

-- Source 20260607031945 repair_main_migration_state_healthcheck

-- Source 20260607034051 prod_enable_rls_migration_repair_audit_20260607

-- Source 20260607034105 prod_index_sales_orders_customer_status_date_20260607

-- Source 20260607034109 prod_index_sales_orders_sales_rep_date_20260607

-- Source 20260607034117 prod_index_invoices_order_customer_20260607

-- Source 20260607034126 prod_index_inventory_stock_product_warehouse_20260607

-- Source 20260607034132 prod_index_deliveries_order_route_status_20260607

-- Source 20260607034137 prod_index_customers_user_commercial_20260607

-- Source 20260607034213 prod_policy_migration_audit_admin_read_20260607

-- Source 20260607034218 prod_policy_products_b2b_read_20260607

-- Source 20260607050810 prod_policy_expense_approval_admin_all_20260607

-- Source 20260607050815 prod_policy_expense_approval_comptable_select_20260607

-- Source 20260607050826 prod_policy_expense_approval_comptable_insert_20260607

-- Source 20260607050830 prod_policy_expense_approval_comptable_update_20260607

-- Source 20260607050849 prod_index_order_items_order_id_20260607

-- Source 20260607050854 prod_index_order_items_product_id_20260607

-- Source 20260607050903 prod_index_stock_movements_product_id_20260607

-- Source 20260607050913 prod_index_stock_movements_created_by_20260607

-- Source 20260607050918 prod_index_payments_invoice_id_20260607

-- Source 20260607050924 prod_index_invoices_customer_id_20260607

-- Source 20260607050929 prod_index_deliveries_order_id_20260607

-- Source 20260607050940 prod_index_delivery_routes_driver_id_20260607

-- Source 20260607050949 prod_index_sales_orders_customer_id_20260607

-- Source 20260607050958 prod_index_customers_user_id_20260607

-- Source 20260607051001 prod_index_customers_commercial_id_20260607

-- Source 20260607051012 prod_index_purchases_supplier_id_20260607

-- Source 20260607051018 prod_index_purchases_created_by_20260607

-- Source 20260607051025 prod_index_purchase_items_purchase_id_20260607

-- Source 20260607051030 prod_index_purchase_items_product_id_20260607

-- Source 20260607051038 prod_search_path_is_admin_20260607

-- Source 20260607051042 prod_search_path_is_sales_rep_20260607

-- Source 20260607051046 prod_search_path_is_warehouse_staff_20260607

-- Source 20260607051054 prod_search_path_is_comptable_20260607

-- Source 20260607051059 prod_search_path_is_acheteur_20260607

-- Source 20260607051108 prod_search_path_is_delivery_agent_20260607

-- Source 20260607051114 prod_search_path_is_b2b_customer_20260607

-- Source 20260607051121 prod_rpc_adjust_stock_20260607

-- Source 20260607051129 prod_rpc_confirm_delivery_20260607

-- Source 20260607051137 prod_rpc_record_payment_20260607

-- Source 20260607051201 prod_rpc_create_order_basic_20260607

-- Source 20260607052356 prod_sp_auto_unblock_expired_users_20260607

-- Source 20260607052401 prod_sp_calculate_user_risk_scores_20260607

-- Source 20260607052407 prod_sp_detect_inventory_anomalies_20260607

-- Source 20260607052415 prod_sp_detect_unauthorized_access_20260607

-- Source 20260607052420 prod_sp_has_module_permission_20260607

-- Source 20260607052425 prod_sp_is_admin_from_auth_20260607

-- Source 20260607052431 prod_sp_is_system_admin_20260607

-- Source 20260607052437 prod_sp_notify_new_order_20260607

-- Source 20260607052447 prod_sp_evaluate_rule_conditions_20260607

-- Source 20260607052453 prod_sp_execute_rule_actions_20260607

-- Source 20260607052459 prod_sp_process_automation_rules_20260607

-- Source 20260607052503 prod_sp_track_screen_navigation_20260607

-- Source 20260607052507 prod_sp_update_session_duration_20260607

-- Source 20260607052525 prod_sp_is_investigation_team_member_20260607

-- Source 20260607052529 prod_sp_log_audit_trail_20260607

-- Source 20260607052533 prod_sp_log_investigation_timeline_20260607

-- Source 20260607052538 prod_sp_get_user_productivity_metrics_20260607

-- Source 20260607052545 prod_sp_generate_investigation_summary_export_20260607

-- Source 20260607052610 prod_trigger_fn_updated_at_column_20260607

-- Source 20260607052615 prod_trigger_updated_at_sales_orders_20260607

-- Source 20260607052619 prod_trigger_updated_at_customers_20260607

-- Source 20260607052624 prod_trigger_updated_at_products_20260607

-- Source 20260607052628 prod_trigger_updated_at_inventory_stock_20260607

-- Source 20260607052633 prod_trigger_updated_at_deliveries_20260607

-- Source 20260607052638 prod_trigger_updated_at_purchases_20260607

-- Source 20260607052647 prod_trigger_updated_at_expenses_20260607

-- Source 20260607052653 prod_trigger_updated_at_suppliers_20260607

-- Source 20260607052658 prod_trigger_updated_at_user_profiles_20260607

-- Source 20260607052703 prod_trigger_updated_at_system_configuration_20260607

-- Source 20260607052715 prod_trigger_updated_at_support_tickets_20260607

-- Source 20260607052719 prod_trigger_updated_at_delivery_routes_20260607

-- Source 20260607052726 prod_trigger_updated_at_user_permissions_20260607

-- Source 20260607052733 prod_trigger_updated_at_user_risk_scores_20260607

-- Source 20260607052741 prod_index_expense_approval_expense_id_20260607

-- Source 20260607052747 prod_index_expense_approval_performed_by_20260607

-- Source 20260607052754 prod_index_expenses_requested_by_20260607

-- Source 20260607052800 prod_index_expenses_approved_by_20260607

-- Source 20260607052807 prod_index_expenses_paid_by_20260607

-- Source 20260607052813 prod_index_accounting_entries_created_by_20260607

-- Source 20260607052818 prod_index_bank_transactions_account_id_20260607

-- Source 20260607052822 prod_index_bank_transactions_created_by_20260607

-- Source 20260607052858 prod_trigger_updated_at_automation_rules_20260607

-- Source 20260607052902 prod_trigger_updated_at_bank_accounts_20260607

-- Source 20260607052907 prod_trigger_updated_at_cash_registers_20260607

-- Source 20260607052911 prod_trigger_updated_at_security_thresholds_20260607

-- Source 20260607052929 prod_trigger_updated_at_escalation_configurations_20260607

-- Source 20260607052934 prod_trigger_updated_at_feature_usage_stats_20260607

-- Source 20260607052938 prod_trigger_updated_at_notification_templates_20260607

-- Source 20260607052952 prod_index_forensic_event_audit_log_20260607

-- Source 20260607053000 prod_index_forensic_event_user_id_20260607

-- Source 20260607053006 prod_index_investigation_tasks_incident_id_20260607

-- Source 20260607054210 prod_sp_create_forensic_export_record_final_20260607

-- Source 20260607054216 prod_sp_generate_forensic_evidence_export_final_20260607

-- Source 20260607054222 prod_sp_generate_ip_correlation_export_final_20260607

-- Source 20260607054228 prod_sp_update_feature_usage_stats_final_20260607

-- Source 20260607054237 prod_sp_detect_suspicious_transactions_final_20260607

-- Source 20260607054246 prod_sp_notify_delivery_done_final_20260607

-- Source 20260607054257 prod_trigger_updated_at_forensic_templates_final_20260607

-- Source 20260607054301 prod_trigger_updated_at_forensic_reports_final_20260607

-- Source 20260607054307 prod_trigger_updated_at_investigation_messages_final_20260607

DO $baseline$ BEGIN CREATE TYPE public."alert_status" AS ENUM ('pending', 'reviewing', 'resolved', 'false_positive'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."anomaly_category" AS ENUM ('transaction', 'access', 'inventory', 'permission', 'system'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."anomaly_severity" AS ENUM ('low', 'medium', 'high', 'critical'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."attachment_entity_type" AS ENUM ('customer', 'expense', 'purchase_order', 'invoice', 'delivery'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."audit_action_type" AS ENUM ('insert', 'update', 'delete', 'login', 'logout', 'export', 'import'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."blocking_reason_type" AS ENUM ('failed_login_attempts', 'suspicious_transactions', 'unauthorized_access', 'repeated_violations', 'manual_block', 'automated_rule'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."blocking_status" AS ENUM ('active', 'expired', 'manually_removed'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."config_value_type" AS ENUM ('string', 'number', 'boolean', 'json', 'date'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."delivery_status" AS ENUM ('pending', 'in_transit', 'delivered', 'failed'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."escalation_level" AS ENUM ('low', 'medium', 'high', 'critical'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."evidence_category" AS ENUM ('log', 'screenshot', 'document', 'network_capture', 'forensic_artifact', 'other'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."export_format" AS ENUM ('pdf', 'csv', 'json', 'excel'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."export_status" AS ENUM ('pending', 'processing', 'completed', 'failed'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."export_template_type" AS ENUM ('forensic_evidence', 'ip_correlation', 'investigation_summary', 'regulatory_compliance', 'incident_report', 'audit_trail', 'timeline_analysis'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."investigation_role" AS ENUM ('lead_investigator', 'investigator', 'analyst', 'observer'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."investigation_task_status" AS ENUM ('assigned', 'in_progress', 'review', 'complete'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."notification_channel" AS ENUM ('email', 'push', 'both'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."notification_status" AS ENUM ('pending', 'sent', 'failed'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."notification_type" AS ENUM ('new_order', 'overdue_invoice', 'low_stock', 'payment_received', 'order_delivered'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."order_status" AS ENUM ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."payment_status" AS ENUM ('pending', 'paid', 'partial', 'failed', 'refunded'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."permission_type" AS ENUM ('module', 'feature', 'action'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."rule_action_type" AS ENUM ('send_notification', 'block_user_temporary', 'block_user_permanent', 'suspend_user', 'escalate_to_admin', 'escalate_to_support', 'generate_report', 'lock_module', 'enable_detailed_logging'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."rule_trigger_type" AS ENUM ('anomaly_detected', 'failed_login_threshold', 'risk_score_exceeded', 'repeated_violation', 'time_based'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."screen_category" AS ENUM ('dashboard', 'inventory', 'sales', 'customers', 'finances', 'reports', 'settings', 'other'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."session_status" AS ENUM ('active', 'idle', 'logged_out'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."stock_movement_type" AS ENUM ('in', 'out', 'adjustment', 'return'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."user_role" AS ENUM ('admin', 'sales_rep', 'warehouse_staff', 'b2b_customer', 'comptable', 'acheteur', 'delivery_agent'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."workflow_entity_type" AS ENUM ('sales_order', 'invoice', 'payment', 'delivery'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

DO $baseline$ BEGIN CREATE TYPE public."workflow_state_type" AS ENUM ('draft', 'pending_approval', 'approved', 'rejected', 'completed', 'cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $baseline$;

CREATE SEQUENCE IF NOT EXISTS public."invoice_number_seq" AS bigint INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS public."order_number_seq" AS bigint INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1 NO CYCLE;

CREATE SEQUENCE IF NOT EXISTS public."purchase_number_seq" AS bigint INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1 NO CYCLE;

CREATE TABLE IF NOT EXISTS public."accounting_entries" (
    "id" uuid NOT NULL,
    "entry_date" date NOT NULL,
    "label" text NOT NULL,
    "debit" numeric(18,2) NOT NULL,
    "credit" numeric(18,2) NOT NULL,
    "currency" text NOT NULL,
    "related_entity_type" text,
    "related_entity_id" uuid,
    "created_by" uuid,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."ai_insights" (
    "id" uuid NOT NULL,
    "insight_type" text NOT NULL,
    "title" text NOT NULL,
    "description" text NOT NULL,
    "severity" text NOT NULL,
    "payload" jsonb,
    "generated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."anomaly_correlation_patterns" (
    "id" uuid NOT NULL,
    "pattern_name" text NOT NULL,
    "pattern_type" text NOT NULL,
    "anomaly_ids" uuid[] NOT NULL,
    "user_id" uuid,
    "correlation_score" numeric(5,2) NOT NULL,
    "risk_level" text NOT NULL,
    "pattern_description" text,
    "detected_at" timestamp with time zone,
    "start_time" timestamp with time zone NOT NULL,
    "end_time" timestamp with time zone NOT NULL,
    "event_count" integer NOT NULL,
    "unique_ips" integer,
    "unique_devices" integer,
    "investigation_status" text,
    "investigation_notes" text,
    "investigated_by" uuid,
    "investigated_at" timestamp with time zone,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."audit_logs" (
    "id" uuid NOT NULL,
    "table_name" text NOT NULL,
    "record_id" uuid NOT NULL,
    "action_type" audit_action_type NOT NULL,
    "old_values" jsonb,
    "new_values" jsonb,
    "user_id" uuid NOT NULL,
    "ip_address" inet,
    "user_agent" text,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."automation_rules" (
    "id" uuid NOT NULL,
    "rule_name" text NOT NULL,
    "description" text,
    "trigger_type" rule_trigger_type NOT NULL,
    "is_active" boolean,
    "priority" integer,
    "created_by" uuid,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."bank_accounts" (
    "id" uuid NOT NULL,
    "account_name" text NOT NULL,
    "bank_name" text NOT NULL,
    "account_number" text,
    "currency" text NOT NULL,
    "current_balance" numeric(18,2) NOT NULL,
    "is_active" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."bank_transactions" (
    "id" uuid NOT NULL,
    "bank_account_id" uuid NOT NULL,
    "transaction_type" text NOT NULL,
    "amount" numeric(18,2) NOT NULL,
    "currency" text NOT NULL,
    "transaction_date" timestamp with time zone,
    "reference" text,
    "description" text,
    "created_by" uuid,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."barcode_scans" (
    "id" uuid NOT NULL,
    "product_id" uuid,
    "scanned_by" uuid,
    "scan_type" text,
    "quantity" integer,
    "location" text,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."cash_movements" (
    "id" uuid NOT NULL,
    "cash_register_id" uuid NOT NULL,
    "movement_type" text NOT NULL,
    "amount" numeric(18,2) NOT NULL,
    "currency" text NOT NULL,
    "reason" text NOT NULL,
    "related_entity_type" text,
    "related_entity_id" uuid,
    "created_by" uuid,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."cash_registers" (
    "id" uuid NOT NULL,
    "name" text NOT NULL,
    "currency" text NOT NULL,
    "opening_balance" numeric(18,2) NOT NULL,
    "current_balance" numeric(18,2) NOT NULL,
    "is_active" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."customers" (
    "id" uuid NOT NULL,
    "user_id" uuid,
    "company_name" text NOT NULL,
    "contact_person" text NOT NULL,
    "email" text NOT NULL,
    "phone" text NOT NULL,
    "address" text,
    "city" text,
    "postal_code" text,
    "credit_limit" numeric(12,2),
    "current_balance" numeric(12,2),
    "is_active" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "commercial_id" uuid
);

CREATE TABLE IF NOT EXISTS public."deliveries" (
    "id" uuid NOT NULL,
    "order_id" uuid,
    "route_id" uuid,
    "delivery_address" text NOT NULL,
    "latitude" numeric(10,8),
    "longitude" numeric(11,8),
    "estimated_time" timestamp with time zone,
    "actual_delivery_time" timestamp with time zone,
    "status" delivery_status,
    "signature_url" text,
    "notes" text,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."delivery_routes" (
    "id" uuid NOT NULL,
    "route_name" text NOT NULL,
    "driver_id" uuid,
    "route_date" date NOT NULL,
    "start_location" text,
    "end_location" text,
    "status" delivery_status,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."device_fingerprints" (
    "id" uuid NOT NULL,
    "fingerprint_hash" text NOT NULL,
    "user_agent" text NOT NULL,
    "device_type" text,
    "browser_name" text,
    "browser_version" text,
    "os_name" text,
    "os_version" text,
    "screen_resolution" text,
    "timezone" text,
    "language" text,
    "platform" text,
    "is_mobile" boolean,
    "first_seen" timestamp with time zone,
    "last_seen" timestamp with time zone,
    "total_sessions" integer,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."document_attachments" (
    "id" uuid NOT NULL,
    "entity_type" attachment_entity_type NOT NULL,
    "entity_id" uuid NOT NULL,
    "file_name" text NOT NULL,
    "file_path" text NOT NULL,
    "file_size" integer NOT NULL,
    "mime_type" text NOT NULL,
    "uploaded_by" uuid,
    "uploaded_at" timestamp with time zone,
    "description" text
);

CREATE TABLE IF NOT EXISTS public."escalation_configurations" (
    "id" uuid NOT NULL,
    "escalation_name" text NOT NULL,
    "severity_level" escalation_level NOT NULL,
    "escalation_delay_minutes" integer,
    "primary_admin_id" uuid,
    "secondary_admin_ids" uuid[],
    "external_support_email" text,
    "notification_channels" text[],
    "is_active" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."escalation_history" (
    "id" uuid NOT NULL,
    "escalation_config_id" uuid,
    "anomaly_id" uuid,
    "escalated_at" timestamp with time zone,
    "escalated_to" uuid,
    "response_received_at" timestamp with time zone,
    "response_action" text,
    "escalation_level_reached" integer
);

CREATE TABLE IF NOT EXISTS public."exchange_rates" (
    "id" uuid NOT NULL,
    "currency_pair" text NOT NULL,
    "rate" numeric(18,6) NOT NULL,
    "source" text,
    "effective_at" timestamp with time zone,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."expense_approval_history" (
    "id" uuid NOT NULL,
    "expense_id" uuid NOT NULL,
    "action" text NOT NULL,
    "performed_by" uuid,
    "comment" text,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."expenses" (
    "id" uuid NOT NULL,
    "category" text NOT NULL,
    "description" text NOT NULL,
    "amount" numeric(12,2) NOT NULL,
    "expense_date" date NOT NULL,
    "created_by" uuid,
    "created_at" timestamp with time zone,
    "currency" text,
    "status" text,
    "requested_by" uuid,
    "approved_by" uuid,
    "approved_at" timestamp with time zone,
    "paid_by" uuid,
    "paid_at" timestamp with time zone,
    "executed_at" timestamp with time zone,
    "rejection_reason" text,
    "receipt_url" text,
    "beneficiary" text,
    "urgency" text,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."failed_login_attempts" (
    "id" uuid NOT NULL,
    "email" text NOT NULL,
    "ip_address" inet,
    "user_agent" text,
    "attempt_time" timestamp with time zone,
    "failure_reason" text,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."feature_usage_stats" (
    "id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "feature_name" text NOT NULL,
    "module_name" text NOT NULL,
    "action_type" text NOT NULL,
    "usage_count" integer,
    "last_used_at" timestamp with time zone NOT NULL,
    "average_time_seconds" numeric(10,2),
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."forensic_event_timeline" (
    "id" uuid NOT NULL,
    "user_id" uuid,
    "session_id" uuid,
    "audit_log_id" uuid,
    "event_type" text NOT NULL,
    "event_category" text NOT NULL,
    "event_timestamp" timestamp with time zone NOT NULL,
    "ip_address" inet,
    "device_fingerprint_id" uuid,
    "event_data" jsonb,
    "sequence_number" integer NOT NULL,
    "time_delta_seconds" integer,
    "is_anomalous" boolean,
    "anomaly_score" numeric(5,2),
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."forensic_export_history" (
    "id" uuid NOT NULL,
    "export_name" text NOT NULL,
    "template_id" uuid,
    "format" export_format NOT NULL,
    "status" export_status,
    "filter_start_date" timestamp with time zone,
    "filter_end_date" timestamp with time zone,
    "filter_user_ids" uuid[],
    "filter_anomaly_types" text[],
    "filter_severity_levels" text[],
    "filter_ip_addresses" inet[],
    "file_path" text,
    "file_size_bytes" bigint,
    "record_count" integer,
    "exported_by" uuid,
    "exported_at" timestamp with time zone,
    "digital_signature" text,
    "watermark_applied" boolean,
    "error_message" text,
    "retry_count" integer,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."forensic_export_templates" (
    "id" uuid NOT NULL,
    "template_name" text NOT NULL,
    "template_type" export_template_type NOT NULL,
    "description" text,
    "format" export_format NOT NULL,
    "include_timeline" boolean,
    "include_ip_geolocation" boolean,
    "include_device_fingerprints" boolean,
    "include_anomaly_correlations" boolean,
    "include_audit_logs" boolean,
    "compliance_standard" text,
    "report_sections" jsonb,
    "watermark_text" text,
    "digital_signature_required" boolean,
    "created_by" uuid,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "is_active" boolean
);

CREATE TABLE IF NOT EXISTS public."forensic_investigation_reports" (
    "id" uuid NOT NULL,
    "report_title" text NOT NULL,
    "report_type" text NOT NULL,
    "user_id" uuid,
    "investigator_id" uuid,
    "time_range_start" timestamp with time zone NOT NULL,
    "time_range_end" timestamp with time zone NOT NULL,
    "summary" text,
    "findings" jsonb,
    "recommendations" jsonb,
    "evidence_audit_logs" uuid[],
    "evidence_sessions" uuid[],
    "evidence_anomalies" uuid[],
    "risk_assessment" text,
    "severity" text,
    "status" text,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "completed_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."inventory_stock" (
    "id" uuid NOT NULL,
    "product_id" uuid,
    "warehouse_id" uuid,
    "quantity" integer NOT NULL,
    "reorder_level" integer,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."investigation_evidence" (
    "id" uuid NOT NULL,
    "incident_id" uuid NOT NULL,
    "category" evidence_category NOT NULL,
    "title" text NOT NULL,
    "description" text,
    "file_path" text,
    "file_size" integer,
    "mime_type" text,
    "metadata" jsonb,
    "is_critical" boolean,
    "chain_of_custody" jsonb,
    "collected_by" uuid NOT NULL,
    "collected_at" timestamp with time zone,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."investigation_messages" (
    "id" uuid NOT NULL,
    "incident_id" uuid NOT NULL,
    "sender_id" uuid NOT NULL,
    "message" text NOT NULL,
    "mentions" jsonb,
    "attachments" jsonb,
    "is_decision" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."investigation_tasks" (
    "id" uuid NOT NULL,
    "incident_id" uuid NOT NULL,
    "title" text NOT NULL,
    "description" text,
    "status" investigation_task_status,
    "priority" integer,
    "assigned_to" uuid,
    "created_by" uuid NOT NULL,
    "due_date" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "sort_order" integer,
    "checklist_items" jsonb,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."investigation_team_members" (
    "id" uuid NOT NULL,
    "incident_id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "role" investigation_role,
    "assigned_at" timestamp with time zone,
    "assigned_by" uuid,
    "is_active" boolean
);

CREATE TABLE IF NOT EXISTS public."investigation_timeline" (
    "id" uuid NOT NULL,
    "incident_id" uuid NOT NULL,
    "event_type" text NOT NULL,
    "description" text NOT NULL,
    "actor_id" uuid,
    "metadata" jsonb,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."invoices" (
    "id" uuid NOT NULL,
    "invoice_number" text NOT NULL,
    "order_id" uuid,
    "customer_id" uuid,
    "invoice_date" timestamp with time zone,
    "due_date" timestamp with time zone NOT NULL,
    "subtotal" numeric(12,2) NOT NULL,
    "tax_amount" numeric(12,2),
    "total_amount" numeric(12,2) NOT NULL,
    "amount_paid" numeric(12,2),
    "payment_status" payment_status,
    "notes" text,
    "created_at" timestamp with time zone,
    "currency" text,
    "exchange_rate" numeric(10,4)
);

CREATE TABLE IF NOT EXISTS public."ip_geolocation_cache" (
    "id" uuid NOT NULL,
    "ip_address" inet NOT NULL,
    "country_code" character varying(2),
    "country_name" text,
    "region" text,
    "city" text,
    "latitude" numeric(10,8),
    "longitude" numeric(11,8),
    "timezone" text,
    "isp" text,
    "is_proxy" boolean,
    "is_vpn" boolean,
    "threat_level" text,
    "last_updated" timestamp with time zone,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."migration_repair_audit" (
    "id" uuid NOT NULL,
    "repair_name" text NOT NULL,
    "applied_at" timestamp with time zone NOT NULL,
    "details" jsonb NOT NULL
);

CREATE TABLE IF NOT EXISTS public."notification_queue" (
    "id" uuid NOT NULL,
    "notification_type" notification_type NOT NULL,
    "recipient_id" uuid,
    "recipient_email" text NOT NULL,
    "channel" notification_channel NOT NULL,
    "subject" text NOT NULL,
    "message" text NOT NULL,
    "status" notification_status,
    "related_entity_type" text,
    "related_entity_id" uuid,
    "scheduled_at" timestamp with time zone,
    "sent_at" timestamp with time zone,
    "error_message" text,
    "retry_count" integer,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."notification_templates" (
    "id" uuid NOT NULL,
    "notification_type" notification_type NOT NULL,
    "subject_template" text NOT NULL,
    "email_body_template" text NOT NULL,
    "push_body_template" text,
    "variables" jsonb,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."order_items" (
    "id" uuid NOT NULL,
    "order_id" uuid,
    "product_id" uuid,
    "quantity" integer NOT NULL,
    "unit_price" numeric(10,2) NOT NULL,
    "discount_percent" numeric(5,2),
    "line_total" numeric(12,2) NOT NULL,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."payments" (
    "id" uuid NOT NULL,
    "invoice_id" uuid,
    "payment_date" timestamp with time zone,
    "amount" numeric(12,2) NOT NULL,
    "payment_method" text,
    "reference_number" text,
    "notes" text,
    "created_at" timestamp with time zone,
    "currency" text
);

CREATE TABLE IF NOT EXISTS public."product_categories" (
    "id" uuid NOT NULL,
    "name" text NOT NULL,
    "description" text,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."products" (
    "id" uuid NOT NULL,
    "sku" text NOT NULL,
    "name" text NOT NULL,
    "description" text,
    "category_id" uuid,
    "unit_price" numeric(10,2) NOT NULL,
    "cost_price" numeric(10,2),
    "image_url" text,
    "barcode" text,
    "is_active" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "currency" text
);

CREATE TABLE IF NOT EXISTS public."purchase_items" (
    "id" uuid NOT NULL,
    "purchase_id" uuid NOT NULL,
    "product_id" uuid,
    "quantity" integer NOT NULL,
    "unit_cost" numeric(15,2) NOT NULL,
    "total_cost" numeric(15,2) NOT NULL,
    "received_quantity" integer,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."purchases" (
    "id" uuid NOT NULL,
    "purchase_number" text,
    "supplier_id" uuid,
    "purchase_date" timestamp with time zone,
    "total_amount" numeric(15,2) NOT NULL,
    "currency" text NOT NULL,
    "exchange_rate" numeric(10,4),
    "status" text,
    "payment_status" text,
    "notes" text,
    "received_by" uuid,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "created_by" uuid,
    "approved_by" uuid,
    "approved_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."rule_actions" (
    "id" uuid NOT NULL,
    "rule_id" uuid,
    "action_type" rule_action_type NOT NULL,
    "action_parameters" jsonb,
    "execution_order" integer,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."rule_conditions" (
    "id" uuid NOT NULL,
    "rule_id" uuid,
    "condition_field" text NOT NULL,
    "condition_operator" text NOT NULL,
    "condition_value" text NOT NULL,
    "logical_operator" text,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."rule_execution_history" (
    "id" uuid NOT NULL,
    "rule_id" uuid,
    "executed_at" timestamp with time zone,
    "trigger_data" jsonb,
    "actions_executed" jsonb,
    "execution_status" text,
    "error_message" text,
    "affected_user_id" uuid
);

CREATE TABLE IF NOT EXISTS public."sales_orders" (
    "id" uuid NOT NULL,
    "order_number" text NOT NULL,
    "customer_id" uuid,
    "sales_rep_id" uuid,
    "order_date" timestamp with time zone,
    "delivery_date" timestamp with time zone,
    "subtotal" numeric(12,2) NOT NULL,
    "tax_amount" numeric(12,2),
    "discount_amount" numeric(12,2),
    "total_amount" numeric(12,2) NOT NULL,
    "order_status" order_status,
    "payment_status" payment_status,
    "notes" text,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "currency" text,
    "exchange_rate" numeric(10,4),
    "payment_type" text,
    "due_date" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."screen_views" (
    "id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "session_id" uuid,
    "screen_name" text NOT NULL,
    "screen_category" screen_category,
    "view_timestamp" timestamp with time zone NOT NULL,
    "time_spent_seconds" integer,
    "previous_screen" text,
    "next_screen" text,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."security_anomalies" (
    "id" uuid NOT NULL,
    "user_id" uuid,
    "category" anomaly_category NOT NULL,
    "severity" anomaly_severity NOT NULL,
    "alert_status" alert_status,
    "title" text NOT NULL,
    "description" text NOT NULL,
    "metadata" jsonb,
    "risk_score" numeric,
    "detected_at" timestamp with time zone,
    "resolved_at" timestamp with time zone,
    "resolved_by" uuid,
    "resolution_notes" text,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."security_thresholds" (
    "id" uuid NOT NULL,
    "threshold_name" text NOT NULL,
    "category" anomaly_category NOT NULL,
    "threshold_value" numeric NOT NULL,
    "description" text,
    "is_active" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."stock_movements" (
    "id" uuid NOT NULL,
    "product_id" uuid,
    "warehouse_id" uuid,
    "movement_type" stock_movement_type NOT NULL,
    "quantity" integer NOT NULL,
    "reference_id" uuid,
    "reference_type" text,
    "notes" text,
    "created_by" uuid,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."suppliers" (
    "id" uuid NOT NULL,
    "company_name" text NOT NULL,
    "contact_person" text,
    "email" text,
    "phone" text,
    "address" text,
    "city" text,
    "country" text,
    "payment_terms_days" integer,
    "preferred_currency" text,
    "is_active" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."support_tickets" (
    "id" uuid NOT NULL,
    "customer_id" uuid,
    "user_id" uuid,
    "subject" text NOT NULL,
    "message" text NOT NULL,
    "status" text NOT NULL,
    "priority" text NOT NULL,
    "assigned_to" uuid,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."system_configuration" (
    "id" uuid NOT NULL,
    "config_key" text NOT NULL,
    "config_value" text NOT NULL,
    "config_type" config_value_type,
    "description" text,
    "is_editable" boolean,
    "company_id" uuid,
    "category" text,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."user_blocking_records" (
    "id" uuid NOT NULL,
    "user_id" uuid,
    "blocking_reason" blocking_reason_type NOT NULL,
    "blocking_status" blocking_status,
    "blocked_at" timestamp with time zone,
    "unblock_at" timestamp with time zone,
    "blocked_by" uuid,
    "unblocked_by" uuid,
    "unblocked_at" timestamp with time zone,
    "notes" text,
    "related_rule_id" uuid
);

CREATE TABLE IF NOT EXISTS public."user_permissions" (
    "id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "module_name" text NOT NULL,
    "permission_type" permission_type,
    "can_view" boolean,
    "can_create" boolean,
    "can_edit" boolean,
    "can_delete" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."user_profiles" (
    "id" uuid NOT NULL,
    "email" text NOT NULL,
    "full_name" text NOT NULL,
    "role" user_role,
    "phone" text,
    "company_name" text,
    "avatar_url" text,
    "is_active" boolean,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "display_currency" text NOT NULL
);

CREATE TABLE IF NOT EXISTS public."user_risk_scores" (
    "id" uuid NOT NULL,
    "user_id" uuid,
    "overall_score" numeric,
    "transaction_score" numeric,
    "access_score" numeric,
    "inventory_score" numeric,
    "last_calculated_at" timestamp with time zone,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."user_sessions" (
    "id" uuid NOT NULL,
    "user_id" uuid NOT NULL,
    "session_start" timestamp with time zone NOT NULL,
    "session_end" timestamp with time zone,
    "duration_minutes" integer,
    "ip_address" inet,
    "user_agent" text,
    "device_type" text,
    "status" session_status,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."warehouse_locations" (
    "id" uuid NOT NULL,
    "name" text NOT NULL,
    "address" text,
    "latitude" numeric(10,8),
    "longitude" numeric(11,8),
    "is_active" boolean,
    "created_at" timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public."workflow_states" (
    "id" uuid NOT NULL,
    "entity_type" workflow_entity_type NOT NULL,
    "entity_id" uuid NOT NULL,
    "current_state" workflow_state_type NOT NULL,
    "previous_state" workflow_state_type,
    "changed_by" uuid NOT NULL,
    "change_reason" text,
    "approved_by" uuid,
    "approved_at" timestamp with time zone,
    "created_at" timestamp with time zone
);

CREATE OR REPLACE FUNCTION public.adjust_stock(p_product_id uuid, p_warehouse_id uuid, p_adjustment_quantity integer, p_reason text DEFAULT 'manual_adjustment'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_user uuid := auth.uid(); v_stock_id uuid;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF NOT (public.is_admin() OR public.is_warehouse_staff()) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF p_product_id IS NULL OR p_adjustment_quantity IS NULL THEN RAISE EXCEPTION 'Invalid arguments'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = p_product_id) THEN RAISE EXCEPTION 'Product not found'; END IF;
  SELECT id INTO v_stock_id FROM public.inventory_stock WHERE product_id = p_product_id AND warehouse_id IS NOT DISTINCT FROM p_warehouse_id FOR UPDATE;
  IF v_stock_id IS NULL THEN
    INSERT INTO public.inventory_stock(product_id, warehouse_id, quantity, reorder_level, updated_at) VALUES (p_product_id, p_warehouse_id, 0, 10, now()) RETURNING id INTO v_stock_id;
  END IF;
  IF (SELECT quantity FROM public.inventory_stock WHERE id=v_stock_id) + p_adjustment_quantity < 0 THEN RAISE EXCEPTION 'Stock cannot be negative'; END IF;
  INSERT INTO public.stock_movements(product_id, warehouse_id, movement_type, quantity, reference_type, notes, created_by) VALUES (p_product_id, p_warehouse_id, 'adjustment'::public.stock_movement_type, p_adjustment_quantity, 'manual_adjustment', p_reason, v_user);
  UPDATE public.inventory_stock SET quantity = quantity + p_adjustment_quantity, updated_at = now() WHERE id = v_stock_id;
  INSERT INTO public.audit_logs(table_name, record_id, action_type, new_values, user_id) VALUES ('inventory_stock', v_stock_id, 'update'::public.audit_action_type, jsonb_build_object('rpc','adjust_stock','quantity',p_adjustment_quantity,'reason',p_reason), v_user);
  RETURN jsonb_build_object('success', true, 'stock_id', v_stock_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$function$;

CREATE OR REPLACE FUNCTION public.auto_unblock_expired_users()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    UPDATE public.user_blocking_records
    SET 
        blocking_status = 'expired'::public.blocking_status,
        unblocked_at = CURRENT_TIMESTAMP
    WHERE 
        blocking_status = 'active'::public.blocking_status
        AND unblock_at IS NOT NULL
        AND unblock_at <= CURRENT_TIMESTAMP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.build_forensic_timeline(user_id_input uuid, start_time_input timestamp with time zone, end_time_input timestamp with time zone)
 RETURNS TABLE(event_id uuid, event_timestamp timestamp with time zone, event_type text, event_category text, event_description text, ip_address inet, device_info jsonb, location_info jsonb, risk_indicator boolean)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        al.id AS event_id,
        al.created_at AS event_timestamp,
        al.action_type::TEXT AS event_type,
        al.table_name AS event_category,
        CASE
            WHEN al.action_type = 'insert' THEN 'Created ' || al.table_name || ' record'
            WHEN al.action_type = 'update' THEN 'Modified ' || al.table_name || ' record'
            WHEN al.action_type = 'delete' THEN 'Deleted ' || al.table_name || ' record'
            ELSE al.action_type::TEXT
        END AS event_description,
        al.ip_address,
        public.parse_user_agent(al.user_agent) AS device_info,
        (
            SELECT jsonb_build_object(
                'country', ig.country_name,
                'city', ig.city,
                'threat_level', ig.threat_level,
                'is_proxy', ig.is_proxy
            )
            FROM public.ip_geolocation_cache ig
            WHERE ig.ip_address = al.ip_address
        ) AS location_info,
        EXISTS(
            SELECT 1 FROM public.security_anomalies sa
            WHERE sa.user_id = al.user_id
            AND sa.detected_at BETWEEN al.created_at - INTERVAL '5 minutes'
                                   AND al.created_at + INTERVAL '5 minutes'
        ) AS risk_indicator
    FROM public.audit_logs al
    WHERE al.user_id = user_id_input
    AND al.created_at BETWEEN start_time_input AND end_time_input
    ORDER BY al.created_at ASC;
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_correlation_score(anomaly_ids_input uuid[])
 RETURNS numeric
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    score DECIMAL := 0;
    anomaly_count INTEGER;
    time_spread INTERVAL;
    severity_weight DECIMAL;
BEGIN
    -- Count anomalies
    anomaly_count := array_length(anomaly_ids_input, 1);
    IF anomaly_count IS NULL OR anomaly_count = 0 THEN
        RETURN 0;
    END IF;

    -- Base score from count (more anomalies = higher score)
    score := LEAST(anomaly_count * 10, 50);

    -- Time concentration factor (anomalies close together = higher score)
    SELECT MAX(detected_at) - MIN(detected_at) INTO time_spread
    FROM public.security_anomalies
    WHERE id = ANY(anomaly_ids_input);

    IF time_spread IS NOT NULL THEN
        IF EXTRACT(EPOCH FROM time_spread) < 3600 THEN
            score := score + 30; -- Within 1 hour
        ELSIF EXTRACT(EPOCH FROM time_spread) < 86400 THEN
            score := score + 20; -- Within 1 day
        ELSE
            score := score + 10; -- More spread out
        END IF;
    END IF;

    -- Severity weighting
    SELECT AVG(
        CASE severity
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            ELSE 1
        END
    ) INTO severity_weight
    FROM public.security_anomalies
    WHERE id = ANY(anomaly_ids_input);

    score := score + (severity_weight * 5);

    RETURN LEAST(score, 100);
END;
$function$;

CREATE OR REPLACE FUNCTION public.calculate_user_risk_scores()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_user_record RECORD;
    v_transaction_score NUMERIC;
    v_access_score NUMERIC;
    v_inventory_score NUMERIC;
    v_overall_score NUMERIC;
BEGIN
    FOR v_user_record IN
        SELECT DISTINCT user_id
        FROM public.security_anomalies
        WHERE detected_at >= NOW() - INTERVAL '30 days'
        AND user_id IS NOT NULL
    LOOP
        -- Calculate transaction risk score
        SELECT COALESCE(AVG(risk_score), 0) INTO v_transaction_score
        FROM public.security_anomalies
        WHERE user_id = v_user_record.user_id
        AND category = 'transaction'
        AND detected_at >= NOW() - INTERVAL '30 days';
        
        -- Calculate access risk score
        SELECT COALESCE(AVG(risk_score), 0) INTO v_access_score
        FROM public.security_anomalies
        WHERE user_id = v_user_record.user_id
        AND category = 'access'
        AND detected_at >= NOW() - INTERVAL '30 days';
        
        -- Calculate inventory risk score
        SELECT COALESCE(AVG(risk_score), 0) INTO v_inventory_score
        FROM public.security_anomalies
        WHERE user_id = v_user_record.user_id
        AND category = 'inventory'
        AND detected_at >= NOW() - INTERVAL '30 days';
        
        -- Calculate overall score
        v_overall_score := (v_transaction_score + v_access_score + v_inventory_score) / 3;
        
        -- Upsert risk score
        INSERT INTO public.user_risk_scores (
            user_id, overall_score, transaction_score, access_score, inventory_score
        ) VALUES (
            v_user_record.user_id, v_overall_score, v_transaction_score, v_access_score, v_inventory_score
        )
        ON CONFLICT (user_id)
        DO UPDATE SET
            overall_score = v_overall_score,
            transaction_score = v_transaction_score,
            access_score = v_access_score,
            inventory_score = v_inventory_score,
            last_calculated_at = NOW(),
            updated_at = NOW();
    END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.can_read_finance()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT public.is_admin() OR public.is_comptable() $function$;

CREATE OR REPLACE FUNCTION public.can_read_procurement()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    SELECT public.is_admin() OR public.is_acheteur() OR public.is_comptable()
$function$;

CREATE OR REPLACE FUNCTION public.check_low_stock()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    low_stock_item RECORD;
    warehouse_user RECORD;
BEGIN
    FOR low_stock_item IN
        SELECT p.id, p.name, MIN(s.reorder_level) AS reorder_level, COALESCE(SUM(s.quantity), 0) AS total_quantity
        FROM public.products p
        JOIN public.inventory_stock s ON p.id = s.product_id
        GROUP BY p.id, p.name
        HAVING COALESCE(SUM(s.quantity), 0) <= MIN(s.reorder_level)
        AND NOT EXISTS (
            SELECT 1 FROM public.notification_queue nq
            WHERE nq.related_entity_id = p.id
            AND nq.notification_type = 'low_stock'
            AND nq.created_at > CURRENT_DATE - INTERVAL '1 day'
        )
    LOOP
        FOR warehouse_user IN
            SELECT id, email FROM public.user_profiles
            WHERE role IN ('admin', 'warehouse_staff') AND is_active = true
        LOOP
            INSERT INTO public.notification_queue (notification_type, recipient_id, recipient_email, channel, subject, message, related_entity_type, related_entity_id)
            VALUES ('low_stock'::public.notification_type, warehouse_user.id, warehouse_user.email, 'both'::public.notification_channel, 'Alerte stock bas', 'Le produit ' || low_stock_item.name || ' est sous le seuil de réapprovisionnement (' || low_stock_item.total_quantity || '/' || low_stock_item.reorder_level || ').', 'product', low_stock_item.id);
        END LOOP;
    END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.check_overdue_invoices()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    overdue_invoice RECORD;
BEGIN
    FOR overdue_invoice IN
        SELECT i.id, i.customer_id, c.commercial_id, up.email, i.invoice_date, i.due_date, c.company_name AS customer_name
        FROM public.invoices i
        JOIN public.customers c ON i.customer_id = c.id
        JOIN public.user_profiles up ON c.commercial_id = up.id
        WHERE i.payment_status != 'paid'
        AND i.due_date < CURRENT_DATE
        AND NOT EXISTS (
            SELECT 1 FROM public.notification_queue nq
            WHERE nq.related_entity_id = i.id
            AND nq.notification_type = 'overdue_invoice'
            AND nq.created_at > CURRENT_DATE - INTERVAL '1 day'
        )
    LOOP
        INSERT INTO public.notification_queue (notification_type, recipient_id, recipient_email, channel, subject, message, related_entity_type, related_entity_id)
        VALUES ('overdue_invoice'::public.notification_type, overdue_invoice.commercial_id, overdue_invoice.email, 'email'::public.notification_channel, 'Alerte : Facture échue', 'Alerte : Facture #' || overdue_invoice.id::TEXT || ' du client ' || overdue_invoice.customer_name || ' est échue. Veuillez procéder au recouvrement.', 'invoice', overdue_invoice.id);
    END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.confirm_delivery(p_delivery_id uuid, p_signature_url text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_user uuid := auth.uid(); v_route_driver uuid; v_status public.delivery_status;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Forbidden'; END IF;
  SELECT d.status, r.driver_id INTO v_status, v_route_driver FROM public.deliveries d LEFT JOIN public.delivery_routes r ON r.id=d.route_id WHERE d.id=p_delivery_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Delivery not found'; END IF;
  IF NOT (public.is_admin() OR (public.is_delivery_agent() AND v_route_driver = v_user)) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF v_status NOT IN ('pending'::public.delivery_status, 'in_transit'::public.delivery_status) THEN RAISE EXCEPTION 'Invalid delivery status'; END IF;
  UPDATE public.deliveries SET status='delivered'::public.delivery_status, actual_delivery_time=now(), signature_url=COALESCE(p_signature_url, signature_url), notes=COALESCE(p_notes, notes), updated_at=now() WHERE id=p_delivery_id;
  INSERT INTO public.audit_logs(table_name, record_id, action_type, new_values, user_id) VALUES ('deliveries', p_delivery_id, 'update'::public.audit_action_type, jsonb_build_object('rpc','confirm_delivery','status','delivered'), v_user);
  RETURN jsonb_build_object('success', true, 'delivery_id', p_delivery_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$function$;

CREATE OR REPLACE FUNCTION public.convert_to_cdf(p_amount numeric, p_currency text)
 RETURNS numeric
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT CASE WHEN p_currency = 'USD' THEN p_amount * COALESCE((SELECT rate FROM public.exchange_rates WHERE currency_pair = 'USD/CDF' ORDER BY effective_at DESC LIMIT 1), 2750) ELSE p_amount END $function$;

CREATE OR REPLACE FUNCTION public.create_forensic_export_record(p_export_name text, p_template_id uuid, p_format export_format, p_filter_start_date timestamp with time zone, p_filter_end_date timestamp with time zone, p_filter_user_ids uuid[] DEFAULT NULL::uuid[], p_filter_anomaly_types text[] DEFAULT NULL::text[], p_filter_severity_levels text[] DEFAULT NULL::text[])
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_export_id UUID;
BEGIN
    INSERT INTO public.forensic_export_history (
        export_name,
        template_id,
        format,
        status,
        filter_start_date,
        filter_end_date,
        filter_user_ids,
        filter_anomaly_types,
        filter_severity_levels,
        exported_by
    ) VALUES (
        p_export_name,
        p_template_id,
        p_format,
        'pending'::public.export_status,
        p_filter_start_date,
        p_filter_end_date,
        p_filter_user_ids,
        p_filter_anomaly_types,
        p_filter_severity_levels,
        auth.uid()
    )
    RETURNING id INTO v_export_id;
    
    RETURN v_export_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_order_with_items(p_customer_id uuid, p_items jsonb, p_notes text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE u uuid := auth.uid(); oid uuid; sub numeric := 0; it jsonb; pid uuid; q int; price numeric; line numeric;
BEGIN
 IF u IS NULL OR NOT (public.is_admin() OR public.is_sales_rep()) THEN RAISE EXCEPTION 'Forbidden'; END IF;
 IF NOT EXISTS (SELECT 1 FROM public.customers WHERE id=p_customer_id) THEN RAISE EXCEPTION 'Invalid customer'; END IF;
 INSERT INTO public.sales_orders(order_number,customer_id,sales_rep_id,subtotal,total_amount,order_status,payment_status,notes) VALUES(public.generate_order_number(now()),p_customer_id,u,0,0,'pending','pending',p_notes) RETURNING id INTO oid;
 FOR it IN SELECT * FROM jsonb_array_elements(p_items) LOOP
   pid := (it->>'product_id')::uuid; q := (it->>'quantity')::int; price := (it->>'unit_price')::numeric;
   IF q <= 0 OR price < 0 THEN RAISE EXCEPTION 'Invalid item'; END IF;
   line := q * price; sub := sub + line;
   INSERT INTO public.order_items(order_id,product_id,quantity,unit_price,line_total) VALUES(oid,pid,q,price,line);
 END LOOP;
 UPDATE public.sales_orders SET subtotal=sub,total_amount=sub WHERE id=oid;
 INSERT INTO public.audit_logs(table_name,record_id,action_type,new_values,user_id) VALUES('sales_orders',oid,'insert',jsonb_build_object('rpc','create_order_with_items'),u);
 RETURN jsonb_build_object('success',true,'order_id',oid);
EXCEPTION WHEN OTHERS THEN RETURN jsonb_build_object('success',false,'error',SQLERRM);
END; $function$;

CREATE OR REPLACE FUNCTION public.current_user_role()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ SELECT role::text FROM public.user_profiles WHERE id = auth.uid() AND is_active = true $function$;

CREATE OR REPLACE FUNCTION public.detect_correlation_patterns(user_id_input uuid, time_window_hours integer DEFAULT 24)
 RETURNS TABLE(pattern_id uuid, pattern_type text, correlated_anomalies uuid[], correlation_score numeric, risk_level text, description text)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    anomaly_record RECORD;
    pattern_uuid UUID;
    anomalies_array UUID[];
    score_val DECIMAL;
BEGIN
    -- Find anomalies within time window
    FOR anomaly_record IN
        SELECT
            array_agg(sa.id) AS ids,
            COUNT(*) AS count,
            MAX(sa.risk_score) AS max_risk
        FROM public.security_anomalies sa
        WHERE sa.user_id = user_id_input
        AND sa.detected_at >= NOW() - (time_window_hours || ' hours')::INTERVAL
        AND sa.alert_status != 'false_positive'
        GROUP BY sa.category
        HAVING COUNT(*) >= 2
    LOOP
        anomalies_array := anomaly_record.ids;
        score_val := public.calculate_correlation_score(anomalies_array);
        pattern_uuid := gen_random_uuid();

        RETURN QUERY
        SELECT
            pattern_uuid,
            'temporal_clustering'::TEXT,
            anomalies_array,
            score_val,
            CASE
                WHEN score_val >= 80 THEN 'critical'::TEXT
                WHEN score_val >= 60 THEN 'high'::TEXT
                WHEN score_val >= 40 THEN 'medium'::TEXT
                ELSE 'low'::TEXT
            END,
            format('%s related security events detected in %s hour window',
                   array_length(anomalies_array, 1),
                   time_window_hours)::TEXT;
    END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.detect_inventory_anomalies()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_threshold NUMERIC;
    v_product_record RECORD;
BEGIN
    -- Get inventory variance threshold
    SELECT threshold_value INTO v_threshold
    FROM public.security_thresholds
    WHERE category = 'inventory' AND threshold_name = 'variance_threshold' AND is_active = true
    LIMIT 1;
    
    IF v_threshold IS NULL THEN
        v_threshold := 20; -- Default 20% variance threshold
    END IF;
    
    -- Detect large inventory adjustments
    FOR v_product_record IN
        SELECT 
            sm.created_by,
            sm.product_id,
            p.name as product_name,
            SUM(CASE WHEN sm.movement_type = 'adjustment' THEN sm.quantity ELSE 0 END) as adjustment_qty,
            i_stock.quantity as current_qty
        FROM public.stock_movements sm
        JOIN public.products p ON sm.product_id = p.id
        LEFT JOIN public.inventory_stock i_stock ON sm.product_id = i_stock.product_id
        WHERE sm.created_at >= NOW() - INTERVAL '24 hours'
            AND sm.movement_type = 'adjustment'
        GROUP BY sm.created_by, sm.product_id, p.name, i_stock.quantity
        HAVING ABS(SUM(sm.quantity)) >= (COALESCE(i_stock.quantity, 0) * v_threshold / 100)
    LOOP
        INSERT INTO public.security_anomalies (
            user_id, category, severity, title, description, risk_score, metadata
        ) VALUES (
            v_product_record.created_by,
            'inventory',
            'high',
            'Large Inventory Adjustment Detected',
            'Significant inventory adjustment exceeding normal variance',
            70,
            jsonb_build_object(
                'product_name', v_product_record.product_name,
                'adjustment_quantity', v_product_record.adjustment_qty,
                'current_quantity', v_product_record.current_qty,
                'threshold_percentage', v_threshold,
                'detection_time', NOW()
            )
        );
    END LOOP;
    
    -- Detect stock movements without valid references
    INSERT INTO public.security_anomalies (
        user_id, category, severity, title, description, risk_score, metadata
    )
    SELECT 
        sm.created_by,
        'inventory',
        'medium',
        'Stock Movement Without Valid Reference',
        'Stock movement created without proper sales order or receipt documentation',
        65,
        jsonb_build_object(
            'movement_type', sm.movement_type,
            'quantity', sm.quantity,
            'product_id', sm.product_id::TEXT,
            'created_at', sm.created_at
        )
    FROM public.stock_movements sm
    WHERE sm.created_at >= NOW() - INTERVAL '24 hours'
        AND sm.reference_id IS NULL
        AND sm.movement_type IN ('out', 'in')
        AND NOT EXISTS (
            SELECT 1 FROM public.security_anomalies sa
            WHERE sa.user_id = sm.created_by
            AND sa.category = 'inventory'
            AND sa.title = 'Stock Movement Without Valid Reference'
            AND sa.detected_at >= NOW() - INTERVAL '24 hours'
        );
END;
$function$;

CREATE OR REPLACE FUNCTION public.detect_suspicious_transactions()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_threshold NUMERIC;
    v_user_record RECORD;
BEGIN
    -- Get high transaction amount threshold
    SELECT threshold_value INTO v_threshold
    FROM public.security_thresholds
    WHERE category = 'transaction' AND threshold_name = 'high_amount_threshold' AND is_active = true
    LIMIT 1;
    
    IF v_threshold IS NULL THEN
        v_threshold := 10000; -- Default threshold
    END IF;
    
    -- Detect unusually high transactions
    FOR v_user_record IN
        SELECT so.sales_rep_id, COUNT(*) as tx_count, SUM(so.total_amount) as total_amt
        FROM public.sales_orders so
        WHERE so.created_at >= NOW() - INTERVAL '24 hours'
        GROUP BY so.sales_rep_id
        HAVING SUM(so.total_amount) > v_threshold
    LOOP
        INSERT INTO public.security_anomalies (
            user_id, category, severity, title, description, risk_score, metadata
        ) VALUES (
            v_user_record.sales_rep_id,
            'transaction',
            'high',
            'Unusually High Transaction Volume',
            'User processed transactions exceeding normal threshold in 24 hours',
            75,
            jsonb_build_object(
                'transaction_count', v_user_record.tx_count,
                'total_amount', v_user_record.total_amt,
                'threshold', v_threshold,
                'detection_time', NOW()
            )
        );
    END LOOP;
    
    -- Detect after-hours transactions
    INSERT INTO public.security_anomalies (
        user_id, category, severity, title, description, risk_score, metadata
    )
    SELECT 
        so.sales_rep_id,
        'transaction',
        'medium',
        'After-Hours Transaction Activity',
        'Transaction created outside business hours (9 AM - 6 PM)',
        50,
        jsonb_build_object(
            'order_number', so.order_number,
            'created_time', so.created_at,
            'total_amount', so.total_amount
        )
    FROM public.sales_orders so
    WHERE so.created_at >= NOW() - INTERVAL '24 hours'
        AND (EXTRACT(HOUR FROM so.created_at) < 9 OR EXTRACT(HOUR FROM so.created_at) > 18)
        AND NOT EXISTS (
            SELECT 1 FROM public.security_anomalies sa
            WHERE sa.user_id = so.sales_rep_id 
            AND sa.category = 'transaction'
            AND sa.title = 'After-Hours Transaction Activity'
            AND sa.detected_at >= NOW() - INTERVAL '24 hours'
        );
END;
$function$;

CREATE OR REPLACE FUNCTION public.detect_unauthorized_access()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_threshold INTEGER;
    v_user_record RECORD;
BEGIN
    -- Get failed login threshold
    SELECT threshold_value INTO v_threshold
    FROM public.security_thresholds
    WHERE category = 'access' AND threshold_name = 'failed_login_threshold' AND is_active = true
    LIMIT 1;
    
    IF v_threshold IS NULL THEN
        v_threshold := 5; -- Default threshold
    END IF;
    
    -- Detect multiple failed login attempts
    FOR v_user_record IN
        SELECT fla.email, COUNT(*) as attempt_count, MAX(fla.ip_address) as last_ip
        FROM public.failed_login_attempts fla
        WHERE fla.attempt_time >= NOW() - INTERVAL '1 hour'
        GROUP BY fla.email
        HAVING COUNT(*) >= v_threshold
    LOOP
        -- Find user_id from email if exists
        DECLARE
            v_user_id UUID;
        BEGIN
            SELECT id INTO v_user_id
            FROM public.user_profiles
            WHERE email = v_user_record.email
            LIMIT 1;
            
            INSERT INTO public.security_anomalies (
                user_id, category, severity, title, description, risk_score, metadata
            ) VALUES (
                v_user_id,
                'access',
                'high',
                'Multiple Failed Login Attempts',
                'Detected multiple failed login attempts within 1 hour',
                80,
                jsonb_build_object(
                    'email', v_user_record.email,
                    'attempt_count', v_user_record.attempt_count,
                    'last_ip', v_user_record.last_ip::TEXT,
                    'detection_time', NOW()
                )
            );
        END;
    END LOOP;
    
    -- Detect access from unusual IP addresses
    INSERT INTO public.security_anomalies (
        user_id, category, severity, title, description, risk_score, metadata
    )
    SELECT 
        us.user_id,
        'access',
        'medium',
        'Access from Unusual Location',
        'User session initiated from new or unusual IP address',
        60,
        jsonb_build_object(
            'ip_address', us.ip_address::TEXT,
            'device_type', us.device_type,
            'session_start', us.session_start
        )
    FROM public.user_sessions us
    WHERE us.created_at >= NOW() - INTERVAL '24 hours'
        AND NOT EXISTS (
            SELECT 1 FROM public.user_sessions prev
            WHERE prev.user_id = us.user_id
            AND prev.ip_address = us.ip_address
            AND prev.created_at < us.created_at - INTERVAL '7 days'
        )
        AND NOT EXISTS (
            SELECT 1 FROM public.security_anomalies sa
            WHERE sa.user_id = us.user_id
            AND sa.category = 'access'
            AND sa.title = 'Access from Unusual Location'
            AND sa.detected_at >= NOW() - INTERVAL '24 hours'
        );
END;
$function$;

CREATE OR REPLACE FUNCTION public.edge_function_auth_headers()
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'vault'
AS $function$
    SELECT jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(
            (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key' LIMIT 1),
            ''
        )
    )
$function$;

CREATE OR REPLACE FUNCTION public.evaluate_rule_conditions(p_rule_id uuid, p_trigger_data jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_condition RECORD;
    v_result BOOLEAN := true;
    v_field_value TEXT;
    v_condition_met BOOLEAN;
BEGIN
    FOR v_condition IN 
        SELECT * FROM public.rule_conditions 
        WHERE rule_id = p_rule_id 
        ORDER BY created_at
    LOOP
        v_field_value := p_trigger_data->>v_condition.condition_field;
        
        CASE v_condition.condition_operator
            WHEN 'equals' THEN
                v_condition_met := (v_field_value = v_condition.condition_value);
            WHEN 'greater_than' THEN
                v_condition_met := (v_field_value::NUMERIC > v_condition.condition_value::NUMERIC);
            WHEN 'less_than' THEN
                v_condition_met := (v_field_value::NUMERIC < v_condition.condition_value::NUMERIC);
            WHEN 'contains' THEN
                v_condition_met := (v_field_value ILIKE '%' || v_condition.condition_value || '%');
            ELSE
                v_condition_met := false;
        END CASE;
        
        IF v_condition.logical_operator = 'AND' THEN
            v_result := v_result AND v_condition_met;
        ELSIF v_condition.logical_operator = 'OR' THEN
            v_result := v_result OR v_condition_met;
        END IF;
    END LOOP;
    
    RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.execute_rule_actions(p_rule_id uuid, p_trigger_data jsonb, p_affected_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_action RECORD;
    v_actions_executed JSONB := '[]'::JSONB;
BEGIN
    FOR v_action IN 
        SELECT * FROM public.rule_actions 
        WHERE rule_id = p_rule_id 
        ORDER BY execution_order
    LOOP
        CASE v_action.action_type
            WHEN 'send_notification' THEN
                INSERT INTO public.notification_queue (
                    recipient_id, 
                    recipient_email,
                    subject, 
                    message, 
                    notification_type,
                    channel
                )
                SELECT 
                    p_affected_user_id,
                    up.email,
                    COALESCE(v_action.action_parameters->>'subject', 'Security Alert'),
                    COALESCE(v_action.action_parameters->>'message', 'Automated security rule triggered'),
                    'new_order'::public.notification_type,
                    COALESCE((v_action.action_parameters->>'channel')::public.notification_channel, 'email'::public.notification_channel)
                FROM public.user_profiles up
                WHERE up.id = p_affected_user_id;
                
            WHEN 'block_user_temporary' THEN
                INSERT INTO public.user_blocking_records (
                    user_id,
                    blocking_reason,
                    unblock_at,
                    related_rule_id,
                    notes
                )
                VALUES (
                    p_affected_user_id,
                    'automated_rule'::public.blocking_reason_type,
                    CURRENT_TIMESTAMP + (COALESCE(v_action.action_parameters->>'duration_minutes', '60')::INTEGER || ' minutes')::INTERVAL,
                    p_rule_id,
                    'Automatically blocked by rule'
                );
                
            WHEN 'escalate_to_admin' THEN
                INSERT INTO public.escalation_history (
                    escalation_config_id,
                    anomaly_id,
                    escalated_to
                )
                SELECT 
                    ec.id,
                    (p_trigger_data->>'anomaly_id')::UUID,
                    ec.primary_admin_id
                FROM public.escalation_configurations ec
                WHERE ec.severity_level = (p_trigger_data->>'severity')::public.escalation_level
                AND ec.is_active = true
                LIMIT 1;
        END CASE;
        
        v_actions_executed := v_actions_executed || jsonb_build_object(
            'action_type', v_action.action_type,
            'executed_at', CURRENT_TIMESTAMP
        );
    END LOOP;
    
    INSERT INTO public.rule_execution_history (
        rule_id,
        trigger_data,
        actions_executed,
        affected_user_id
    ) VALUES (
        p_rule_id,
        p_trigger_data,
        v_actions_executed,
        p_affected_user_id
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_ai_insights()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ BEGIN INSERT INTO public.ai_insights (insight_type, title, description, severity, payload) SELECT 'stock_alert', 'Risque de rupture stock', 'Le produit ' || p.name || ' est sous son seuil de réapprovisionnement.', 'warning', jsonb_build_object('product_id', p.id, 'sku', p.sku, 'quantity', s.quantity, 'reorder_level', s.reorder_level) FROM public.inventory_stock s JOIN public.products p ON p.id = s.product_id WHERE s.quantity <= s.reorder_level; END; $function$;

CREATE OR REPLACE FUNCTION public.generate_device_fingerprint(user_agent_val text, ip_addr inet)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    RETURN md5(COALESCE(user_agent_val, '') || '|' || COALESCE(host(ip_addr), ''));
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_forensic_evidence_export(p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_user_ids uuid[] DEFAULT NULL::uuid[], p_anomaly_types text[] DEFAULT NULL::text[], p_severity_levels text[] DEFAULT NULL::text[], p_ip_addresses inet[] DEFAULT NULL::inet[])
 RETURNS TABLE(evidence_type text, event_timestamp timestamp with time zone, user_email text, ip_address inet, location_info text, device_info text, anomaly_description text, risk_score numeric, evidence_details jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        'forensic_event'::TEXT AS evidence_type,
        fet.event_timestamp,
        up.email AS user_email,
        fet.ip_address,
        CONCAT(igc.city, ', ', igc.country_name) AS location_info,
        CONCAT(df.device_type, ' - ', df.os_name, ' ', df.os_version) AS device_info,
        fet.event_type AS anomaly_description,
        fet.anomaly_score AS risk_score,
        jsonb_build_object(
            'event_category', fet.event_category,
            'event_data', fet.event_data,
            'session_id', fet.session_id,
            'is_anomalous', fet.is_anomalous
        ) AS evidence_details
    FROM public.forensic_event_timeline fet
    LEFT JOIN public.user_profiles up ON fet.user_id = up.id
    LEFT JOIN public.ip_geolocation_cache igc ON fet.ip_address = igc.ip_address
    LEFT JOIN public.device_fingerprints df ON fet.device_fingerprint_id = df.id
    WHERE fet.event_timestamp BETWEEN p_start_date AND p_end_date
        AND (p_user_ids IS NULL OR fet.user_id = ANY(p_user_ids))
        AND (p_ip_addresses IS NULL OR fet.ip_address = ANY(p_ip_addresses))
    
    UNION ALL
    
    SELECT
        'security_anomaly'::TEXT AS evidence_type,
        sa.detected_at AS event_timestamp,
        up.email AS user_email,
        NULL::INET AS ip_address,
        NULL AS location_info,
        NULL AS device_info,
        sa.description AS anomaly_description,
        sa.risk_score,
        jsonb_build_object(
            'title', sa.title,
            'category', sa.category::TEXT,
            'severity', sa.severity::TEXT,
            'metadata', sa.metadata,
            'alert_status', sa.alert_status::TEXT
        ) AS evidence_details
    FROM public.security_anomalies sa
    LEFT JOIN public.user_profiles up ON sa.user_id = up.id
    WHERE sa.detected_at BETWEEN p_start_date AND p_end_date
        AND (p_user_ids IS NULL OR sa.user_id = ANY(p_user_ids))
        AND (p_anomaly_types IS NULL OR sa.category::TEXT = ANY(p_anomaly_types))
        AND (p_severity_levels IS NULL OR sa.severity::TEXT = ANY(p_severity_levels))
    
    ORDER BY event_timestamp DESC;
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_investigation_summary_export(p_investigation_report_id uuid)
 RETURNS TABLE(report_title text, report_type text, severity text, status text, investigator_name text, time_range_start timestamp with time zone, time_range_end timestamp with time zone, summary text, findings jsonb, risk_assessment text, recommendations jsonb, evidence_count integer, correlation_patterns jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        fir.report_title,
        fir.report_type,
        fir.severity,
        fir.status,
        up.full_name AS investigator_name,
        fir.time_range_start,
        fir.time_range_end,
        fir.summary,
        fir.findings,
        fir.risk_assessment,
        fir.recommendations,
        (array_length(fir.evidence_audit_logs, 1) + 
         array_length(fir.evidence_anomalies, 1) + 
         array_length(fir.evidence_sessions, 1)) AS evidence_count,
        jsonb_agg(jsonb_build_object(
            'pattern_name', acp.pattern_name,
            'pattern_type', acp.pattern_type,
            'risk_level', acp.risk_level,
            'correlation_score', acp.correlation_score,
            'event_count', acp.event_count
        )) AS correlation_patterns
    FROM public.forensic_investigation_reports fir
    LEFT JOIN public.user_profiles up ON fir.investigator_id = up.id
    LEFT JOIN public.anomaly_correlation_patterns acp 
        ON acp.user_id = fir.user_id 
        AND acp.detected_at BETWEEN fir.time_range_start AND fir.time_range_end
    WHERE fir.id = p_investigation_report_id
    GROUP BY fir.id, fir.report_title, fir.report_type, fir.severity, fir.status,
             up.full_name, fir.time_range_start, fir.time_range_end, fir.summary,
             fir.findings, fir.risk_assessment, fir.recommendations,
             fir.evidence_audit_logs, fir.evidence_anomalies, fir.evidence_sessions;
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_invoice_number(p_date timestamp with time zone DEFAULT now())
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN 'INV-' || to_char(p_date, 'YYYY') || '-' || lpad(nextval('public.invoice_number_seq')::TEXT, 5, '0');
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_ip_correlation_export(p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_threat_levels text[] DEFAULT NULL::text[])
 RETURNS TABLE(ip_address inet, country text, city text, isp text, threat_level text, is_proxy boolean, is_vpn boolean, connection_count bigint, unique_users bigint, first_seen timestamp with time zone, last_seen timestamp with time zone, suspicious_activities jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        igc.ip_address,
        igc.country_name AS country,
        igc.city,
        igc.isp,
        igc.threat_level,
        igc.is_proxy,
        igc.is_vpn,
        COUNT(DISTINCT fet.id) AS connection_count,
        COUNT(DISTINCT fet.user_id) AS unique_users,
        MIN(fet.event_timestamp) AS first_seen,
        MAX(fet.event_timestamp) AS last_seen,
        jsonb_agg(DISTINCT jsonb_build_object(
            'event_type', fet.event_type,
            'anomaly_score', fet.anomaly_score,
            'is_anomalous', fet.is_anomalous
        )) FILTER (WHERE fet.is_anomalous = true) AS suspicious_activities
    FROM public.ip_geolocation_cache igc
    LEFT JOIN public.forensic_event_timeline fet ON igc.ip_address = fet.ip_address
    WHERE fet.event_timestamp BETWEEN p_start_date AND p_end_date
        AND (p_threat_levels IS NULL OR igc.threat_level = ANY(p_threat_levels))
    GROUP BY igc.id, igc.ip_address, igc.country_name, igc.city, 
             igc.isp, igc.threat_level, igc.is_proxy, igc.is_vpn
    ORDER BY connection_count DESC;
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_order_number(p_date timestamp with time zone DEFAULT now())
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN 'ORD-' || to_char(p_date, 'YYYY') || '-' || lpad(nextval('public.order_number_seq')::TEXT, 5, '0');
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_purchase_number(p_date timestamp with time zone DEFAULT now())
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN 'PO-' || to_char(p_date, 'YYYY') || '-' || lpad(nextval('public.purchase_number_seq')::TEXT, 5, '0');
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_admin_finance_report(p_start timestamp with time zone, p_end timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ DECLARE result JSONB; BEGIN IF NOT public.is_admin() THEN RAISE EXCEPTION 'admin only'; END IF; SELECT jsonb_build_object('sales_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(total_amount, currency)) FROM public.sales_orders WHERE order_date BETWEEN p_start AND p_end), 0), 'purchase_cost_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(total_amount, currency)) FROM public.purchases WHERE purchase_date BETWEEN p_start AND p_end), 0), 'expenses_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(amount, currency)) FROM public.expenses WHERE expense_date BETWEEN p_start::date AND p_end::date), 0), 'net_profit_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(total_amount, currency)) FROM public.sales_orders WHERE order_date BETWEEN p_start AND p_end), 0) - COALESCE((SELECT SUM(public.convert_to_cdf(total_amount, currency)) FROM public.purchases WHERE purchase_date BETWEEN p_start AND p_end), 0) - COALESCE((SELECT SUM(public.convert_to_cdf(amount, currency)) FROM public.expenses WHERE expense_date BETWEEN p_start::date AND p_end::date), 0), 'expenses_by_category', COALESCE((SELECT jsonb_object_agg(category, total) FROM (SELECT category, SUM(public.convert_to_cdf(amount, currency)) AS total FROM public.expenses WHERE expense_date BETWEEN p_start::date AND p_end::date GROUP BY category) e), '{}'::jsonb), 'purchases_by_supplier', COALESCE((SELECT jsonb_agg(row_to_json(s)) FROM (SELECT COALESCE(s.company_name, 'Sans fournisseur') AS supplier, SUM(public.convert_to_cdf(p.total_amount, p.currency)) AS total_cdf, COUNT(*) AS purchases FROM public.purchases p LEFT JOIN public.suppliers s ON s.id = p.supplier_id WHERE p.purchase_date BETWEEN p_start AND p_end GROUP BY s.company_name ORDER BY total_cdf DESC LIMIT 10) s), '[]'::jsonb)) INTO result; RETURN result; END; $function$;

CREATE OR REPLACE FUNCTION public.get_admin_operations_report(p_start timestamp with time zone, p_end timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ DECLARE result JSONB; BEGIN IF NOT public.is_admin() THEN RAISE EXCEPTION 'admin only'; END IF; SELECT jsonb_build_object('receivables_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(total_amount - amount_paid, currency)) FROM public.invoices WHERE payment_status != 'paid'), 0), 'average_receivable_age_days', COALESCE((SELECT AVG(EXTRACT(DAY FROM now() - due_date)) FROM public.invoices WHERE payment_status != 'paid'), 0), 'risky_customers', COALESCE((SELECT jsonb_agg(row_to_json(r)) FROM (SELECT c.company_name, SUM(public.convert_to_cdf(i.total_amount - i.amount_paid, i.currency)) AS outstanding_cdf FROM public.invoices i JOIN public.customers c ON c.id = i.customer_id WHERE i.payment_status != 'paid' GROUP BY c.id, c.company_name ORDER BY outstanding_cdf DESC LIMIT 10) r), '[]'::jsonb), 'stock_value_cdf', COALESCE((SELECT SUM(s.quantity * COALESCE(p.cost_price, p.unit_price)) FROM public.inventory_stock s JOIN public.products p ON p.id = s.product_id), 0), 'low_stock', COALESCE((SELECT jsonb_agg(row_to_json(l)) FROM (SELECT p.name, p.sku, s.quantity, s.reorder_level FROM public.inventory_stock s JOIN public.products p ON p.id = s.product_id WHERE s.quantity <= s.reorder_level ORDER BY s.quantity ASC LIMIT 20) l), '[]'::jsonb), 'cash_balance_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(current_balance, currency)) FROM public.cash_registers WHERE is_active), 0), 'cash_movements_today_cdf', COALESCE((SELECT SUM(CASE WHEN movement_type = 'in' THEN public.convert_to_cdf(amount, currency) ELSE -public.convert_to_cdf(amount, currency) END) FROM public.cash_movements WHERE created_at::date = CURRENT_DATE), 0), 'bank_balance_cdf', COALESCE((SELECT SUM(public.convert_to_cdf(current_balance, currency)) FROM public.bank_accounts WHERE is_active), 0), 'bank_accounts', COALESCE((SELECT jsonb_agg(row_to_json(b)) FROM (SELECT account_name, bank_name, currency, current_balance FROM public.bank_accounts WHERE is_active ORDER BY bank_name) b), '[]'::jsonb)) INTO result; RETURN result; END; $function$;

CREATE OR REPLACE FUNCTION public.get_admin_sales_report(p_start timestamp with time zone, p_end timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ DECLARE result JSONB; BEGIN IF NOT public.is_admin() THEN RAISE EXCEPTION 'admin only'; END IF; SELECT jsonb_build_object('revenue_cdf', COALESCE(SUM(public.convert_to_cdf(total_amount, currency)), 0), 'orders_count', COUNT(*), 'by_status', COALESCE((SELECT jsonb_object_agg(order_status, count) FROM (SELECT order_status::text, COUNT(*) AS count FROM public.sales_orders WHERE order_date >= p_start AND order_date <= p_end GROUP BY order_status) s), '{}'::jsonb), 'daily', COALESCE((SELECT jsonb_agg(row_to_json(d)) FROM (SELECT date_trunc('day', order_date)::date AS day, SUM(public.convert_to_cdf(total_amount, currency)) AS revenue_cdf, COUNT(*) AS orders FROM public.sales_orders WHERE order_date >= p_start AND order_date <= p_end GROUP BY 1 ORDER BY 1) d), '[]'::jsonb), 'top_products', COALESCE((SELECT jsonb_agg(row_to_json(t)) FROM (SELECT p.name, p.sku, SUM(oi.quantity) AS quantity, SUM(oi.line_total) AS revenue FROM public.order_items oi JOIN public.products p ON p.id = oi.product_id JOIN public.sales_orders so ON so.id = oi.order_id WHERE so.order_date >= p_start AND so.order_date <= p_end GROUP BY p.id, p.name, p.sku ORDER BY revenue DESC LIMIT 10) t), '[]'::jsonb)) INTO result FROM public.sales_orders WHERE order_date >= p_start AND order_date <= p_end; RETURN result; END; $function$;

CREATE OR REPLACE FUNCTION public.get_admin_total_report(p_start timestamp with time zone, p_end timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ BEGIN IF NOT public.is_admin() THEN RAISE EXCEPTION 'admin only'; END IF; RETURN jsonb_build_object('period', jsonb_build_object('start', p_start, 'end', p_end), 'sales', public.get_admin_sales_report(p_start, p_end), 'finance', public.get_admin_finance_report(p_start, p_end), 'operations', public.get_admin_operations_report(p_start, p_end)); END; $function$;

CREATE OR REPLACE FUNCTION public.get_user_productivity_metrics(p_user_id uuid, p_start_date timestamp with time zone, p_end_date timestamp with time zone)
 RETURNS TABLE(total_sessions integer, total_session_time_minutes numeric, avg_session_duration_minutes numeric, total_screens_visited integer, unique_screens_count integer, most_used_feature text, most_visited_screen text, productivity_score numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    RETURN QUERY
    WITH session_stats AS (
        SELECT 
            COUNT(*) as session_count,
            SUM(duration_minutes) as total_duration,
            AVG(duration_minutes) as avg_duration
        FROM public.user_sessions
        WHERE user_id = p_user_id
            AND session_start BETWEEN p_start_date AND p_end_date
    ),
    screen_stats AS (
        SELECT 
            COUNT(*) as total_views,
            COUNT(DISTINCT screen_name) as unique_screens,
            (SELECT screen_name 
             FROM public.screen_views 
             WHERE user_id = p_user_id
                AND view_timestamp BETWEEN p_start_date AND p_end_date
             GROUP BY screen_name 
             ORDER BY COUNT(*) DESC 
             LIMIT 1) as top_screen
        FROM public.screen_views
        WHERE user_id = p_user_id
            AND view_timestamp BETWEEN p_start_date AND p_end_date
    ),
    feature_stats AS (
        SELECT feature_name as top_feature
        FROM public.feature_usage_stats
        WHERE user_id = p_user_id
            AND last_used_at BETWEEN p_start_date AND p_end_date
        ORDER BY usage_count DESC
        LIMIT 1
    )
    SELECT 
        COALESCE(ss.session_count::INTEGER, 0),
        COALESCE(ss.total_duration, 0),
        COALESCE(ss.avg_duration, 0),
        COALESCE(scr.total_views::INTEGER, 0),
        COALESCE(scr.unique_screens::INTEGER, 0),
        COALESCE(fs.top_feature, 'N/A'::TEXT),
        COALESCE(scr.top_screen, 'N/A'::TEXT),
        -- Productivity score calculation (0-100)
        LEAST(100, 
            (COALESCE(ss.session_count, 0) * 5) +
            (COALESCE(scr.unique_screens, 0) * 10) +
            (COALESCE(scr.total_views, 0) * 0.5)
        )::NUMERIC(5,2)
    FROM session_stats ss
    CROSS JOIN screen_stats scr
    LEFT JOIN feature_stats fs ON true;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role, phone, company_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        'b2b_customer'::public.user_role,
        NEW.raw_user_meta_data->>'phone',
        NEW.raw_user_meta_data->>'company_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.has_module_permission(module text, permission text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
SELECT EXISTS (
    SELECT 1 FROM public.user_permissions perm
    WHERE perm.user_id = auth.uid()
    AND perm.module_name = module
    AND (
        (permission = 'view' AND perm.can_view = true) OR
        (permission = 'create' AND perm.can_create = true) OR
        (permission = 'edit' AND perm.can_edit = true) OR
        (permission = 'delete' AND perm.can_delete = true)
    )
)
$function$;

CREATE OR REPLACE FUNCTION public.invoke_send_email_notification()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    IF NEW.status = 'pending' AND NEW.channel IN ('email', 'both') THEN
        PERFORM net.http_post(
            url := 'https://lvzdlmojjoqrwxwluvih.supabase.co/functions/v1/send-email-notification',
            headers := public.edge_function_auth_headers(),
            body := jsonb_build_object('notification_id', NEW.id)
        );
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.is_acheteur()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'acheteur' AND is_active = true
    );
$function$;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND up.role = 'admin'::public.user_role
    AND up.is_active = true
)
$function$;

CREATE OR REPLACE FUNCTION public.is_admin_from_auth()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid() 
    AND (au.raw_user_meta_data->>'role' = 'admin' 
         OR au.raw_app_meta_data->>'role' = 'admin')
)
$function$;

CREATE OR REPLACE FUNCTION public.is_b2b_customer()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND up.role = 'b2b_customer'::public.user_role
    AND up.is_active = true
)
$function$;

CREATE OR REPLACE FUNCTION public.is_comptable()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'comptable' AND is_active = true
    );
$function$;

CREATE OR REPLACE FUNCTION public.is_delivery_agent()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$ SELECT EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'delivery_agent' AND is_active = true) $function$;

CREATE OR REPLACE FUNCTION public.is_investigation_team_member(incident_uuid uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
SELECT EXISTS (
    SELECT 1 FROM public.investigation_team_members itm
    WHERE itm.incident_id = incident_uuid
    AND itm.user_id = auth.uid()
    AND itm.is_active = true
)
$function$;

CREATE OR REPLACE FUNCTION public.is_sales_rep()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND up.role = 'sales_rep'::public.user_role
    AND up.is_active = true
)
$function$;

CREATE OR REPLACE FUNCTION public.is_system_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND up.role = 'admin'::public.user_role
)
$function$;

CREATE OR REPLACE FUNCTION public.is_warehouse_staff()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND up.role = 'warehouse_staff'::public.user_role
    AND up.is_active = true
)
$function$;

CREATE OR REPLACE FUNCTION public.log_audit_trail()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO public.audit_logs (
            table_name,
            record_id,
            action_type,
            old_values,
            user_id
        ) VALUES (
            TG_TABLE_NAME,
            OLD.id,
            'delete'::public.audit_action_type,
            to_jsonb(OLD),
            auth.uid()
        );
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO public.audit_logs (
            table_name,
            record_id,
            action_type,
            old_values,
            new_values,
            user_id
        ) VALUES (
            TG_TABLE_NAME,
            NEW.id,
            'update'::public.audit_action_type,
            to_jsonb(OLD),
            to_jsonb(NEW),
            auth.uid()
        );
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO public.audit_logs (
            table_name,
            record_id,
            action_type,
            new_values,
            user_id
        ) VALUES (
            TG_TABLE_NAME,
            NEW.id,
            'insert'::public.audit_action_type,
            to_jsonb(NEW),
            auth.uid()
        );
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.log_investigation_timeline()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.investigation_timeline (
            incident_id,
            event_type,
            description,
            actor_id,
            metadata
        ) VALUES (
            NEW.incident_id,
            TG_TABLE_NAME || '_added',
            'New ' || TG_TABLE_NAME || ' added',
            auth.uid(),
            jsonb_build_object('id', NEW.id)
        );
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.investigation_timeline (
            incident_id,
            event_type,
            description,
            actor_id,
            metadata
        ) VALUES (
            NEW.incident_id,
            TG_TABLE_NAME || '_updated',
            TG_TABLE_NAME || ' updated',
            auth.uid(),
            jsonb_build_object('id', NEW.id)
        );
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_new_order()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    depot_users UUID[];
    depot_user UUID;
BEGIN
    -- Get all depot/warehouse staff users
    SELECT ARRAY_AGG(id) INTO depot_users
    FROM public.user_profiles
    WHERE role = 'warehouse_staff';
    
    -- Create notification for each depot user
    FOREACH depot_user IN ARRAY depot_users
    LOOP
        INSERT INTO public.notification_queue (
            notification_type,
            recipient_id,
            recipient_email,
            channel,
            subject,
            message,
            related_entity_type,
            related_entity_id
        )
        SELECT
            'new_order'::public.notification_type,
            depot_user,
            up.email,
            'both'::public.notification_channel,
            'Nouvelle commande à préparer',
            'Nouvelle commande #' || NEW.id::TEXT || ' reçue. À préparer.',
            'sales_order',
            NEW.id
        FROM public.user_profiles up
        WHERE up.id = depot_user;
    END LOOP;
    
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_order_delivered()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    customer_email TEXT;
    customer_user_id UUID;
BEGIN
    IF NEW.status = 'delivered' AND (OLD.status IS NULL OR OLD.status != 'delivered') THEN
        -- Get customer email
        SELECT c.user_id, up.email INTO customer_user_id, customer_email
        FROM public.sales_orders so
        JOIN public.customers c ON so.customer_id = c.id
        LEFT JOIN public.user_profiles up ON c.user_id = up.id
        WHERE so.id = NEW.order_id;
        
        IF customer_email IS NOT NULL THEN
            INSERT INTO public.notification_queue (
                notification_type,
                recipient_id,
                recipient_email,
                channel,
                subject,
                message,
                related_entity_type,
                related_entity_id
            ) VALUES (
                'order_delivered'::public.notification_type,
                customer_user_id,
                customer_email,
                'email'::public.notification_channel,
                'Commande livrée',
                'Votre commande #' || NEW.order_id::TEXT || ' a été livrée et complétée.',
                'delivery',
                NEW.id
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.notify_payment_received()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    admin_user RECORD;
    customer_name TEXT;
BEGIN
    SELECT c.company_name INTO customer_name
    FROM public.invoices i
    JOIN public.customers c ON i.customer_id = c.id
    WHERE i.id = NEW.invoice_id;
    
    FOR admin_user IN
        SELECT id, email FROM public.user_profiles
        WHERE role = 'admin' AND is_active = true
    LOOP
        INSERT INTO public.notification_queue (notification_type, recipient_id, recipient_email, channel, subject, message, related_entity_type, related_entity_id)
        VALUES ('payment_received'::public.notification_type, admin_user.id, admin_user.email, 'email'::public.notification_channel, 'Paiement reçu', 'Paiement de ' || NEW.amount::TEXT || ' reçu du client ' || COALESCE(customer_name, 'Inconnu') || '.', 'payment', NEW.id);
    END LOOP;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.parse_user_agent(user_agent_text text)
 RETURNS jsonb
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    result JSONB := '{}'::JSONB;
    is_mobile_device BOOLEAN := false;
    browser_name_val TEXT;
    os_name_val TEXT;
BEGIN
    IF user_agent_text IS NULL OR user_agent_text = '' THEN
        RETURN result;
    END IF;

    -- Detect mobile
    is_mobile_device := user_agent_text ~* '(Mobile|Android|iPhone|iPad|iPod)';

    -- Detect browser
    browser_name_val := CASE
        WHEN user_agent_text ~* 'Edg/' THEN 'Edge'
        WHEN user_agent_text ~* 'Chrome/' THEN 'Chrome'
        WHEN user_agent_text ~* 'Safari/' AND user_agent_text !~* 'Chrome' THEN 'Safari'
        WHEN user_agent_text ~* 'Firefox/' THEN 'Firefox'
        WHEN user_agent_text ~* 'MSIE|Trident/' THEN 'Internet Explorer'
        ELSE 'Unknown'
    END;

    -- Detect OS
    os_name_val := CASE
        WHEN user_agent_text ~* 'Windows NT' THEN 'Windows'
        WHEN user_agent_text ~* 'Mac OS X' THEN 'macOS'
        WHEN user_agent_text ~* 'Linux' THEN 'Linux'
        WHEN user_agent_text ~* 'Android' THEN 'Android'
        WHEN user_agent_text ~* 'iPhone|iPad|iPod' THEN 'iOS'
        ELSE 'Unknown'
    END;

    result := jsonb_build_object(
        'is_mobile', is_mobile_device,
        'browser_name', browser_name_val,
        'os_name', os_name_val
    );

    RETURN result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.prevent_profile_privilege_escalation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    IF auth.uid() = OLD.id AND NOT public.is_admin() THEN
        IF NEW.role IS DISTINCT FROM OLD.role THEN
            RAISE EXCEPTION 'Users cannot modify their own role';
        END IF;
        IF NEW.is_active IS DISTINCT FROM OLD.is_active THEN
            RAISE EXCEPTION 'Users cannot modify their own active status';
        END IF;
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.process_automation_rules(p_trigger_type rule_trigger_type, p_trigger_data jsonb, p_affected_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_rule RECORD;
    v_conditions_met BOOLEAN;
BEGIN
    FOR v_rule IN 
        SELECT * FROM public.automation_rules 
        WHERE trigger_type = p_trigger_type 
        AND is_active = true
        ORDER BY priority DESC
    LOOP
        v_conditions_met := public.evaluate_rule_conditions(v_rule.id, p_trigger_data);
        
        IF v_conditions_met THEN
            PERFORM public.execute_rule_actions(v_rule.id, p_trigger_data, p_affected_user_id);
        END IF;
    END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.recalculate_sales_order_totals()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_order_id UUID;
    v_subtotal NUMERIC;
BEGIN
    v_order_id := COALESCE(NEW.order_id, OLD.order_id);
    SELECT COALESCE(SUM(line_total), 0) INTO v_subtotal FROM public.order_items WHERE order_id = v_order_id;
    UPDATE public.sales_orders SET subtotal = v_subtotal, total_amount = v_subtotal + COALESCE(tax_amount, 0) - COALESCE(discount_amount, 0), updated_at = now() WHERE id = v_order_id;
    RETURN COALESCE(NEW, OLD);
END;
$function$;

CREATE OR REPLACE FUNCTION public.record_payment(p_invoice_id uuid, p_amount numeric, p_currency text DEFAULT 'CDF'::text, p_payment_method text DEFAULT NULL::text, p_reference_number text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE v_user uuid := auth.uid(); v_invoice public.invoices%rowtype; v_payment_id uuid; v_paid numeric;
BEGIN
  IF v_user IS NULL THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF NOT (public.is_admin() OR public.is_comptable()) THEN RAISE EXCEPTION 'Forbidden'; END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN RAISE EXCEPTION 'Invalid amount'; END IF;
  SELECT * INTO v_invoice FROM public.invoices WHERE id=p_invoice_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Invoice not found'; END IF;
  IF p_currency <> v_invoice.currency THEN RAISE EXCEPTION 'Currency mismatch'; END IF;
  v_paid := COALESCE(v_invoice.amount_paid,0) + p_amount;
  IF v_paid > v_invoice.total_amount + 0.01 THEN RAISE EXCEPTION 'Payment exceeds balance'; END IF;
  INSERT INTO public.payments(invoice_id, amount, payment_method, reference_number, notes, currency) VALUES (p_invoice_id, p_amount, p_payment_method, p_reference_number, p_notes, p_currency) RETURNING id INTO v_payment_id;
  UPDATE public.invoices SET amount_paid=v_paid, payment_status=CASE WHEN v_paid >= total_amount - 0.01 THEN 'paid'::public.payment_status ELSE 'partial'::public.payment_status END WHERE id=p_invoice_id;
  IF v_invoice.order_id IS NOT NULL THEN UPDATE public.sales_orders SET payment_status=CASE WHEN v_paid >= v_invoice.total_amount - 0.01 THEN 'paid'::public.payment_status ELSE 'partial'::public.payment_status END, updated_at=now() WHERE id=v_invoice.order_id; END IF;
  INSERT INTO public.audit_logs(table_name, record_id, action_type, new_values, user_id) VALUES ('payments', v_payment_id, 'insert'::public.audit_action_type, jsonb_build_object('rpc','record_payment','amount',p_amount), v_user);
  RETURN jsonb_build_object('success', true, 'payment_id', v_payment_id);
EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_invoice_number()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
    IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
        NEW.invoice_number := public.generate_invoice_number(COALESCE(NEW.invoice_date, now()));
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_order_item_line_total()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
    NEW.line_total := COALESCE(NEW.quantity, 0) * COALESCE(NEW.unit_price, 0) * (1 - COALESCE(NEW.discount_percent, 0) / 100);
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_purchase_number()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
    IF NEW.purchase_number IS NULL OR NEW.purchase_number = '' THEN
        NEW.purchase_number := public.generate_purchase_number(COALESCE(NEW.purchase_date, now()));
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_sales_order_number()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
    IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
        NEW.order_number := public.generate_order_number(COALESCE(NEW.order_date, now()));
    END IF;
    NEW.subtotal := COALESCE(NEW.subtotal, 0);
    NEW.discount_amount := COALESCE(NEW.discount_amount, 0);
    NEW.tax_amount := COALESCE(NEW.tax_amount, 0);
    NEW.total_amount := COALESCE(NEW.total_amount, NEW.subtotal + NEW.tax_amount - NEW.discount_amount);
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_inventory_stock_from_movements()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_product_id UUID;
    v_warehouse_id UUID;
    v_quantity INTEGER;
BEGIN
    v_product_id := COALESCE(NEW.product_id, OLD.product_id);
    v_warehouse_id := COALESCE(NEW.warehouse_id, OLD.warehouse_id);
    SELECT COALESCE(SUM(CASE movement_type WHEN 'in' THEN quantity WHEN 'return' THEN quantity WHEN 'out' THEN -quantity WHEN 'adjustment' THEN quantity ELSE 0 END), 0)::INTEGER INTO v_quantity
    FROM public.stock_movements WHERE product_id = v_product_id AND warehouse_id = v_warehouse_id;
    INSERT INTO public.inventory_stock (product_id, warehouse_id, quantity, updated_at) VALUES (v_product_id, v_warehouse_id, v_quantity, now())
    ON CONFLICT (product_id, warehouse_id) DO UPDATE SET quantity = EXCLUDED.quantity, updated_at = now();
    RETURN COALESCE(NEW, OLD);
END;
$function$;

CREATE OR REPLACE FUNCTION public.track_screen_navigation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    prev_screen_record RECORD;
BEGIN
    -- Get the previous screen view for this user
    SELECT screen_name, id INTO prev_screen_record
    FROM public.screen_views
    WHERE user_id = NEW.user_id
        AND id != NEW.id
    ORDER BY view_timestamp DESC
    LIMIT 1;

    IF FOUND THEN
        -- Update previous screen's next_screen
        UPDATE public.screen_views
        SET next_screen = NEW.screen_name
        WHERE id = prev_screen_record.id;

        -- Set current screen's previous_screen
        NEW.previous_screen := prev_screen_record.screen_name;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_feature_usage_stats(p_user_id uuid, p_feature_name text, p_module_name text, p_action_type text, p_time_seconds integer DEFAULT NULL::integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    existing_record RECORD;
BEGIN
    -- Check if record exists
    SELECT * INTO existing_record
    FROM public.feature_usage_stats
    WHERE user_id = p_user_id
        AND feature_name = p_feature_name
        AND module_name = p_module_name
        AND action_type = p_action_type;

    IF FOUND THEN
        -- Update existing record
        UPDATE public.feature_usage_stats
        SET usage_count = usage_count + 1,
            last_used_at = CURRENT_TIMESTAMP,
            average_time_seconds = CASE
                WHEN p_time_seconds IS NOT NULL THEN
                    ((COALESCE(average_time_seconds, 0) * usage_count) + p_time_seconds) / (usage_count + 1)
                ELSE average_time_seconds
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = existing_record.id;
    ELSE
        -- Insert new record
        INSERT INTO public.feature_usage_stats (
            user_id, feature_name, module_name, action_type,
            usage_count, average_time_seconds
        ) VALUES (
            p_user_id, p_feature_name, p_module_name, p_action_type,
            1, p_time_seconds
        );
    END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_session_duration()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    IF NEW.session_end IS NOT NULL THEN
        NEW.duration_minutes := EXTRACT(EPOCH FROM (NEW.session_end - NEW.session_start)) / 60;
    END IF;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'extensions'
AS $function$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $function$;

ALTER TABLE public."accounting_entries" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."accounting_entries" ALTER COLUMN "entry_date" SET DEFAULT CURRENT_DATE;

ALTER TABLE public."accounting_entries" ALTER COLUMN "debit" SET DEFAULT 0;

ALTER TABLE public."accounting_entries" ALTER COLUMN "credit" SET DEFAULT 0;

ALTER TABLE public."accounting_entries" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."accounting_entries" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."ai_insights" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."ai_insights" ALTER COLUMN "severity" SET DEFAULT 'info'::text;

ALTER TABLE public."ai_insights" ALTER COLUMN "payload" SET DEFAULT '{}'::jsonb;

ALTER TABLE public."ai_insights" ALTER COLUMN "generated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."anomaly_correlation_patterns" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."anomaly_correlation_patterns" ALTER COLUMN "detected_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."anomaly_correlation_patterns" ALTER COLUMN "investigation_status" SET DEFAULT 'pending'::text;

ALTER TABLE public."anomaly_correlation_patterns" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."audit_logs" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."audit_logs" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."automation_rules" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."automation_rules" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."automation_rules" ALTER COLUMN "priority" SET DEFAULT 0;

ALTER TABLE public."automation_rules" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."automation_rules" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."bank_accounts" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."bank_accounts" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."bank_accounts" ALTER COLUMN "current_balance" SET DEFAULT 0;

ALTER TABLE public."bank_accounts" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."bank_accounts" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."bank_accounts" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."bank_transactions" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."bank_transactions" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."bank_transactions" ALTER COLUMN "transaction_date" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."bank_transactions" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."barcode_scans" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."barcode_scans" ALTER COLUMN "quantity" SET DEFAULT 1;

ALTER TABLE public."barcode_scans" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."cash_movements" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."cash_movements" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."cash_movements" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."cash_registers" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."cash_registers" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."cash_registers" ALTER COLUMN "opening_balance" SET DEFAULT 0;

ALTER TABLE public."cash_registers" ALTER COLUMN "current_balance" SET DEFAULT 0;

ALTER TABLE public."cash_registers" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."cash_registers" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."cash_registers" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."customers" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."customers" ALTER COLUMN "credit_limit" SET DEFAULT 0;

ALTER TABLE public."customers" ALTER COLUMN "current_balance" SET DEFAULT 0;

ALTER TABLE public."customers" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."customers" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."customers" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."deliveries" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."deliveries" ALTER COLUMN "status" SET DEFAULT 'pending'::delivery_status;

ALTER TABLE public."deliveries" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."deliveries" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."delivery_routes" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."delivery_routes" ALTER COLUMN "status" SET DEFAULT 'pending'::delivery_status;

ALTER TABLE public."delivery_routes" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."delivery_routes" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."device_fingerprints" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."device_fingerprints" ALTER COLUMN "is_mobile" SET DEFAULT false;

ALTER TABLE public."device_fingerprints" ALTER COLUMN "first_seen" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."device_fingerprints" ALTER COLUMN "last_seen" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."device_fingerprints" ALTER COLUMN "total_sessions" SET DEFAULT 1;

ALTER TABLE public."device_fingerprints" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."document_attachments" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."document_attachments" ALTER COLUMN "uploaded_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."escalation_configurations" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."escalation_configurations" ALTER COLUMN "escalation_delay_minutes" SET DEFAULT 30;

ALTER TABLE public."escalation_configurations" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."escalation_configurations" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."escalation_configurations" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."escalation_history" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."escalation_history" ALTER COLUMN "escalated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."escalation_history" ALTER COLUMN "escalation_level_reached" SET DEFAULT 1;

ALTER TABLE public."exchange_rates" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."exchange_rates" ALTER COLUMN "source" SET DEFAULT 'manual'::text;

ALTER TABLE public."exchange_rates" ALTER COLUMN "effective_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."exchange_rates" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."expense_approval_history" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."expense_approval_history" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."expenses" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."expenses" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."expenses" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."expenses" ALTER COLUMN "status" SET DEFAULT 'draft'::text;

ALTER TABLE public."expenses" ALTER COLUMN "urgency" SET DEFAULT 'normal'::text;

ALTER TABLE public."expenses" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."failed_login_attempts" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."failed_login_attempts" ALTER COLUMN "attempt_time" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."failed_login_attempts" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."feature_usage_stats" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."feature_usage_stats" ALTER COLUMN "usage_count" SET DEFAULT 1;

ALTER TABLE public."feature_usage_stats" ALTER COLUMN "last_used_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."feature_usage_stats" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."feature_usage_stats" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."forensic_event_timeline" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."forensic_event_timeline" ALTER COLUMN "is_anomalous" SET DEFAULT false;

ALTER TABLE public."forensic_event_timeline" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."forensic_export_history" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."forensic_export_history" ALTER COLUMN "status" SET DEFAULT 'pending'::export_status;

ALTER TABLE public."forensic_export_history" ALTER COLUMN "exported_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."forensic_export_history" ALTER COLUMN "watermark_applied" SET DEFAULT false;

ALTER TABLE public."forensic_export_history" ALTER COLUMN "retry_count" SET DEFAULT 0;

ALTER TABLE public."forensic_export_history" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."forensic_export_templates" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."forensic_export_templates" ALTER COLUMN "include_timeline" SET DEFAULT true;

ALTER TABLE public."forensic_export_templates" ALTER COLUMN "include_ip_geolocation" SET DEFAULT true;

ALTER TABLE public."forensic_export_templates" ALTER COLUMN "include_device_fingerprints" SET DEFAULT true;

ALTER TABLE public."forensic_export_templates" ALTER COLUMN "include_anomaly_correlations" SET DEFAULT true;

ALTER TABLE public."forensic_export_templates" ALTER COLUMN "include_audit_logs" SET DEFAULT true;

ALTER TABLE public."forensic_export_templates" ALTER COLUMN "digital_signature_required" SET DEFAULT false;

ALTER TABLE public."forensic_export_templates" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."forensic_export_templates" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."forensic_export_templates" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."forensic_investigation_reports" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."forensic_investigation_reports" ALTER COLUMN "status" SET DEFAULT 'draft'::text;

ALTER TABLE public."forensic_investigation_reports" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."forensic_investigation_reports" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."inventory_stock" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."inventory_stock" ALTER COLUMN "quantity" SET DEFAULT 0;

ALTER TABLE public."inventory_stock" ALTER COLUMN "reorder_level" SET DEFAULT 10;

ALTER TABLE public."inventory_stock" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."investigation_evidence" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."investigation_evidence" ALTER COLUMN "is_critical" SET DEFAULT false;

ALTER TABLE public."investigation_evidence" ALTER COLUMN "collected_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."investigation_evidence" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."investigation_messages" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."investigation_messages" ALTER COLUMN "is_decision" SET DEFAULT false;

ALTER TABLE public."investigation_messages" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."investigation_messages" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."investigation_tasks" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."investigation_tasks" ALTER COLUMN "status" SET DEFAULT 'assigned'::investigation_task_status;

ALTER TABLE public."investigation_tasks" ALTER COLUMN "priority" SET DEFAULT 0;

ALTER TABLE public."investigation_tasks" ALTER COLUMN "sort_order" SET DEFAULT 0;

ALTER TABLE public."investigation_tasks" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."investigation_tasks" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."investigation_team_members" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."investigation_team_members" ALTER COLUMN "role" SET DEFAULT 'investigator'::investigation_role;

ALTER TABLE public."investigation_team_members" ALTER COLUMN "assigned_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."investigation_team_members" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."investigation_timeline" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."investigation_timeline" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."invoices" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."invoices" ALTER COLUMN "invoice_date" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."invoices" ALTER COLUMN "tax_amount" SET DEFAULT 0;

ALTER TABLE public."invoices" ALTER COLUMN "amount_paid" SET DEFAULT 0;

ALTER TABLE public."invoices" ALTER COLUMN "payment_status" SET DEFAULT 'pending'::payment_status;

ALTER TABLE public."invoices" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."invoices" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."invoices" ALTER COLUMN "exchange_rate" SET DEFAULT 1;

ALTER TABLE public."ip_geolocation_cache" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."ip_geolocation_cache" ALTER COLUMN "is_proxy" SET DEFAULT false;

ALTER TABLE public."ip_geolocation_cache" ALTER COLUMN "is_vpn" SET DEFAULT false;

ALTER TABLE public."ip_geolocation_cache" ALTER COLUMN "last_updated" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."ip_geolocation_cache" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."migration_repair_audit" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."migration_repair_audit" ALTER COLUMN "applied_at" SET DEFAULT now();

ALTER TABLE public."migration_repair_audit" ALTER COLUMN "details" SET DEFAULT '{}'::jsonb;

ALTER TABLE public."notification_queue" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."notification_queue" ALTER COLUMN "status" SET DEFAULT 'pending'::notification_status;

ALTER TABLE public."notification_queue" ALTER COLUMN "scheduled_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."notification_queue" ALTER COLUMN "retry_count" SET DEFAULT 0;

ALTER TABLE public."notification_queue" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."notification_templates" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."notification_templates" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."notification_templates" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."order_items" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."order_items" ALTER COLUMN "discount_percent" SET DEFAULT 0;

ALTER TABLE public."order_items" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."payments" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."payments" ALTER COLUMN "payment_date" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."payments" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."payments" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."product_categories" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."product_categories" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."products" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."products" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."products" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."products" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."products" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."purchase_items" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."purchase_items" ALTER COLUMN "received_quantity" SET DEFAULT 0;

ALTER TABLE public."purchase_items" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."purchases" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."purchases" ALTER COLUMN "purchase_date" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."purchases" ALTER COLUMN "total_amount" SET DEFAULT 0;

ALTER TABLE public."purchases" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."purchases" ALTER COLUMN "exchange_rate" SET DEFAULT 1;

ALTER TABLE public."purchases" ALTER COLUMN "status" SET DEFAULT 'pending'::text;

ALTER TABLE public."purchases" ALTER COLUMN "payment_status" SET DEFAULT 'pending'::text;

ALTER TABLE public."purchases" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."purchases" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."rule_actions" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."rule_actions" ALTER COLUMN "execution_order" SET DEFAULT 0;

ALTER TABLE public."rule_actions" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."rule_conditions" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."rule_conditions" ALTER COLUMN "logical_operator" SET DEFAULT 'AND'::text;

ALTER TABLE public."rule_conditions" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."rule_execution_history" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."rule_execution_history" ALTER COLUMN "executed_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."rule_execution_history" ALTER COLUMN "execution_status" SET DEFAULT 'success'::text;

ALTER TABLE public."sales_orders" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."sales_orders" ALTER COLUMN "order_date" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."sales_orders" ALTER COLUMN "tax_amount" SET DEFAULT 0;

ALTER TABLE public."sales_orders" ALTER COLUMN "discount_amount" SET DEFAULT 0;

ALTER TABLE public."sales_orders" ALTER COLUMN "order_status" SET DEFAULT 'pending'::order_status;

ALTER TABLE public."sales_orders" ALTER COLUMN "payment_status" SET DEFAULT 'pending'::payment_status;

ALTER TABLE public."sales_orders" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."sales_orders" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."sales_orders" ALTER COLUMN "currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."sales_orders" ALTER COLUMN "exchange_rate" SET DEFAULT 1;

ALTER TABLE public."sales_orders" ALTER COLUMN "payment_type" SET DEFAULT 'cash'::text;

ALTER TABLE public."screen_views" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."screen_views" ALTER COLUMN "screen_category" SET DEFAULT 'other'::screen_category;

ALTER TABLE public."screen_views" ALTER COLUMN "view_timestamp" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."screen_views" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."security_anomalies" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."security_anomalies" ALTER COLUMN "alert_status" SET DEFAULT 'pending'::alert_status;

ALTER TABLE public."security_anomalies" ALTER COLUMN "risk_score" SET DEFAULT 0;

ALTER TABLE public."security_anomalies" ALTER COLUMN "detected_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."security_anomalies" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."security_thresholds" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."security_thresholds" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."security_thresholds" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."security_thresholds" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."stock_movements" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."stock_movements" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."suppliers" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."suppliers" ALTER COLUMN "country" SET DEFAULT 'RDC'::text;

ALTER TABLE public."suppliers" ALTER COLUMN "payment_terms_days" SET DEFAULT 30;

ALTER TABLE public."suppliers" ALTER COLUMN "preferred_currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."suppliers" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."suppliers" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."suppliers" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."support_tickets" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."support_tickets" ALTER COLUMN "status" SET DEFAULT 'open'::text;

ALTER TABLE public."support_tickets" ALTER COLUMN "priority" SET DEFAULT 'normal'::text;

ALTER TABLE public."support_tickets" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."support_tickets" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."system_configuration" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."system_configuration" ALTER COLUMN "config_type" SET DEFAULT 'string'::config_value_type;

ALTER TABLE public."system_configuration" ALTER COLUMN "is_editable" SET DEFAULT true;

ALTER TABLE public."system_configuration" ALTER COLUMN "category" SET DEFAULT 'general'::text;

ALTER TABLE public."system_configuration" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."system_configuration" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_blocking_records" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."user_blocking_records" ALTER COLUMN "blocking_status" SET DEFAULT 'active'::blocking_status;

ALTER TABLE public."user_blocking_records" ALTER COLUMN "blocked_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_permissions" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."user_permissions" ALTER COLUMN "permission_type" SET DEFAULT 'module'::permission_type;

ALTER TABLE public."user_permissions" ALTER COLUMN "can_view" SET DEFAULT false;

ALTER TABLE public."user_permissions" ALTER COLUMN "can_create" SET DEFAULT false;

ALTER TABLE public."user_permissions" ALTER COLUMN "can_edit" SET DEFAULT false;

ALTER TABLE public."user_permissions" ALTER COLUMN "can_delete" SET DEFAULT false;

ALTER TABLE public."user_permissions" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_permissions" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_profiles" ALTER COLUMN "role" SET DEFAULT 'b2b_customer'::user_role;

ALTER TABLE public."user_profiles" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."user_profiles" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_profiles" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_profiles" ALTER COLUMN "display_currency" SET DEFAULT 'CDF'::text;

ALTER TABLE public."user_risk_scores" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."user_risk_scores" ALTER COLUMN "overall_score" SET DEFAULT 0;

ALTER TABLE public."user_risk_scores" ALTER COLUMN "transaction_score" SET DEFAULT 0;

ALTER TABLE public."user_risk_scores" ALTER COLUMN "access_score" SET DEFAULT 0;

ALTER TABLE public."user_risk_scores" ALTER COLUMN "inventory_score" SET DEFAULT 0;

ALTER TABLE public."user_risk_scores" ALTER COLUMN "last_calculated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_risk_scores" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_risk_scores" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_sessions" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."user_sessions" ALTER COLUMN "session_start" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_sessions" ALTER COLUMN "status" SET DEFAULT 'active'::session_status;

ALTER TABLE public."user_sessions" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."user_sessions" ALTER COLUMN "updated_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."warehouse_locations" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."warehouse_locations" ALTER COLUMN "is_active" SET DEFAULT true;

ALTER TABLE public."warehouse_locations" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public."workflow_states" ALTER COLUMN "id" SET DEFAULT gen_random_uuid();

ALTER TABLE public."workflow_states" ALTER COLUMN "created_at" SET DEFAULT CURRENT_TIMESTAMP;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."accounting_entries"'::regclass AND conname = 'accounting_entries_currency_check') THEN ALTER TABLE public."accounting_entries" ADD CONSTRAINT "accounting_entries_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."accounting_entries"'::regclass AND conname = 'accounting_entries_pkey') THEN ALTER TABLE public."accounting_entries" ADD CONSTRAINT "accounting_entries_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ai_insights"'::regclass AND conname = 'ai_insights_insight_type_check') THEN ALTER TABLE public."ai_insights" ADD CONSTRAINT "ai_insights_insight_type_check" CHECK ((insight_type = ANY (ARRAY['sales_forecast'::text, 'stock_alert'::text, 'expense_trend'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ai_insights"'::regclass AND conname = 'ai_insights_pkey') THEN ALTER TABLE public."ai_insights" ADD CONSTRAINT "ai_insights_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ai_insights"'::regclass AND conname = 'ai_insights_severity_check') THEN ALTER TABLE public."ai_insights" ADD CONSTRAINT "ai_insights_severity_check" CHECK ((severity = ANY (ARRAY['info'::text, 'warning'::text, 'critical'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."anomaly_correlation_patterns"'::regclass AND conname = 'anomaly_correlation_patterns_investigation_status_check') THEN ALTER TABLE public."anomaly_correlation_patterns" ADD CONSTRAINT "anomaly_correlation_patterns_investigation_status_check" CHECK ((investigation_status = ANY (ARRAY['pending'::text, 'investigating'::text, 'resolved'::text, 'false_positive'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."anomaly_correlation_patterns"'::regclass AND conname = 'anomaly_correlation_patterns_pkey') THEN ALTER TABLE public."anomaly_correlation_patterns" ADD CONSTRAINT "anomaly_correlation_patterns_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."anomaly_correlation_patterns"'::regclass AND conname = 'anomaly_correlation_patterns_risk_level_check') THEN ALTER TABLE public."anomaly_correlation_patterns" ADD CONSTRAINT "anomaly_correlation_patterns_risk_level_check" CHECK ((risk_level = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'critical'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."audit_logs"'::regclass AND conname = 'audit_logs_pkey') THEN ALTER TABLE public."audit_logs" ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."automation_rules"'::regclass AND conname = 'automation_rules_pkey') THEN ALTER TABLE public."automation_rules" ADD CONSTRAINT "automation_rules_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."bank_accounts"'::regclass AND conname = 'bank_accounts_currency_check') THEN ALTER TABLE public."bank_accounts" ADD CONSTRAINT "bank_accounts_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."bank_accounts"'::regclass AND conname = 'bank_accounts_pkey') THEN ALTER TABLE public."bank_accounts" ADD CONSTRAINT "bank_accounts_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."bank_transactions"'::regclass AND conname = 'bank_transactions_amount_check') THEN ALTER TABLE public."bank_transactions" ADD CONSTRAINT "bank_transactions_amount_check" CHECK ((amount >= (0)::numeric)); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."bank_transactions"'::regclass AND conname = 'bank_transactions_currency_check') THEN ALTER TABLE public."bank_transactions" ADD CONSTRAINT "bank_transactions_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."bank_transactions"'::regclass AND conname = 'bank_transactions_pkey') THEN ALTER TABLE public."bank_transactions" ADD CONSTRAINT "bank_transactions_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."bank_transactions"'::regclass AND conname = 'bank_transactions_transaction_type_check') THEN ALTER TABLE public."bank_transactions" ADD CONSTRAINT "bank_transactions_transaction_type_check" CHECK ((transaction_type = ANY (ARRAY['credit'::text, 'debit'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."barcode_scans"'::regclass AND conname = 'barcode_scans_pkey') THEN ALTER TABLE public."barcode_scans" ADD CONSTRAINT "barcode_scans_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."cash_movements"'::regclass AND conname = 'cash_movements_amount_check') THEN ALTER TABLE public."cash_movements" ADD CONSTRAINT "cash_movements_amount_check" CHECK ((amount >= (0)::numeric)); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."cash_movements"'::regclass AND conname = 'cash_movements_currency_check') THEN ALTER TABLE public."cash_movements" ADD CONSTRAINT "cash_movements_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."cash_movements"'::regclass AND conname = 'cash_movements_movement_type_check') THEN ALTER TABLE public."cash_movements" ADD CONSTRAINT "cash_movements_movement_type_check" CHECK ((movement_type = ANY (ARRAY['in'::text, 'out'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."cash_movements"'::regclass AND conname = 'cash_movements_pkey') THEN ALTER TABLE public."cash_movements" ADD CONSTRAINT "cash_movements_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."cash_registers"'::regclass AND conname = 'cash_registers_currency_check') THEN ALTER TABLE public."cash_registers" ADD CONSTRAINT "cash_registers_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."cash_registers"'::regclass AND conname = 'cash_registers_pkey') THEN ALTER TABLE public."cash_registers" ADD CONSTRAINT "cash_registers_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."customers"'::regclass AND conname = 'customers_pkey') THEN ALTER TABLE public."customers" ADD CONSTRAINT "customers_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."deliveries"'::regclass AND conname = 'deliveries_pkey') THEN ALTER TABLE public."deliveries" ADD CONSTRAINT "deliveries_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."delivery_routes"'::regclass AND conname = 'delivery_routes_pkey') THEN ALTER TABLE public."delivery_routes" ADD CONSTRAINT "delivery_routes_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."device_fingerprints"'::regclass AND conname = 'device_fingerprints_fingerprint_hash_key') THEN ALTER TABLE public."device_fingerprints" ADD CONSTRAINT "device_fingerprints_fingerprint_hash_key" UNIQUE (fingerprint_hash); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."device_fingerprints"'::regclass AND conname = 'device_fingerprints_pkey') THEN ALTER TABLE public."device_fingerprints" ADD CONSTRAINT "device_fingerprints_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."document_attachments"'::regclass AND conname = 'check_file_size') THEN ALTER TABLE public."document_attachments" ADD CONSTRAINT "check_file_size" CHECK (((file_size > 0) AND (file_size <= 10485760))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."document_attachments"'::regclass AND conname = 'document_attachments_pkey') THEN ALTER TABLE public."document_attachments" ADD CONSTRAINT "document_attachments_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."escalation_configurations"'::regclass AND conname = 'escalation_configurations_pkey') THEN ALTER TABLE public."escalation_configurations" ADD CONSTRAINT "escalation_configurations_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."escalation_history"'::regclass AND conname = 'escalation_history_pkey') THEN ALTER TABLE public."escalation_history" ADD CONSTRAINT "escalation_history_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."exchange_rates"'::regclass AND conname = 'exchange_rates_currency_pair_check') THEN ALTER TABLE public."exchange_rates" ADD CONSTRAINT "exchange_rates_currency_pair_check" CHECK ((currency_pair = 'USD/CDF'::text)); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."exchange_rates"'::regclass AND conname = 'exchange_rates_currency_pair_key') THEN ALTER TABLE public."exchange_rates" ADD CONSTRAINT "exchange_rates_currency_pair_key" UNIQUE (currency_pair); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."exchange_rates"'::regclass AND conname = 'exchange_rates_pkey') THEN ALTER TABLE public."exchange_rates" ADD CONSTRAINT "exchange_rates_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."exchange_rates"'::regclass AND conname = 'exchange_rates_rate_check') THEN ALTER TABLE public."exchange_rates" ADD CONSTRAINT "exchange_rates_rate_check" CHECK ((rate > (0)::numeric)); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expense_approval_history"'::regclass AND conname = 'expense_approval_history_action_check') THEN ALTER TABLE public."expense_approval_history" ADD CONSTRAINT "expense_approval_history_action_check" CHECK ((action = ANY (ARRAY['submitted'::text, 'approved'::text, 'rejected'::text, 'paid'::text, 'executed'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expense_approval_history"'::regclass AND conname = 'expense_approval_history_pkey') THEN ALTER TABLE public."expense_approval_history" ADD CONSTRAINT "expense_approval_history_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expenses"'::regclass AND conname = 'expenses_currency_check') THEN ALTER TABLE public."expenses" ADD CONSTRAINT "expenses_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expenses"'::regclass AND conname = 'expenses_pkey') THEN ALTER TABLE public."expenses" ADD CONSTRAINT "expenses_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expenses"'::regclass AND conname = 'expenses_status_check') THEN ALTER TABLE public."expenses" ADD CONSTRAINT "expenses_status_check" CHECK ((status = ANY (ARRAY['draft'::text, 'pending_approval'::text, 'approved'::text, 'rejected'::text, 'pending_payment'::text, 'paid'::text, 'executed'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expenses"'::regclass AND conname = 'expenses_urgency_check') THEN ALTER TABLE public."expenses" ADD CONSTRAINT "expenses_urgency_check" CHECK ((urgency = ANY (ARRAY['low'::text, 'normal'::text, 'high'::text, 'urgent'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."failed_login_attempts"'::regclass AND conname = 'failed_login_attempts_pkey') THEN ALTER TABLE public."failed_login_attempts" ADD CONSTRAINT "failed_login_attempts_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."feature_usage_stats"'::regclass AND conname = 'feature_usage_stats_pkey') THEN ALTER TABLE public."feature_usage_stats" ADD CONSTRAINT "feature_usage_stats_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_event_timeline"'::regclass AND conname = 'forensic_event_timeline_pkey') THEN ALTER TABLE public."forensic_event_timeline" ADD CONSTRAINT "forensic_event_timeline_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_export_history"'::regclass AND conname = 'forensic_export_history_pkey') THEN ALTER TABLE public."forensic_export_history" ADD CONSTRAINT "forensic_export_history_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_export_templates"'::regclass AND conname = 'forensic_export_templates_pkey') THEN ALTER TABLE public."forensic_export_templates" ADD CONSTRAINT "forensic_export_templates_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_investigation_reports"'::regclass AND conname = 'forensic_investigation_reports_pkey') THEN ALTER TABLE public."forensic_investigation_reports" ADD CONSTRAINT "forensic_investigation_reports_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_investigation_reports"'::regclass AND conname = 'forensic_investigation_reports_report_type_check') THEN ALTER TABLE public."forensic_investigation_reports" ADD CONSTRAINT "forensic_investigation_reports_report_type_check" CHECK ((report_type = ANY (ARRAY['incident'::text, 'user_behavior'::text, 'threat_analysis'::text, 'compliance_audit'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_investigation_reports"'::regclass AND conname = 'forensic_investigation_reports_severity_check') THEN ALTER TABLE public."forensic_investigation_reports" ADD CONSTRAINT "forensic_investigation_reports_severity_check" CHECK ((severity = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'critical'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_investigation_reports"'::regclass AND conname = 'forensic_investigation_reports_status_check') THEN ALTER TABLE public."forensic_investigation_reports" ADD CONSTRAINT "forensic_investigation_reports_status_check" CHECK ((status = ANY (ARRAY['draft'::text, 'completed'::text, 'archived'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."inventory_stock"'::regclass AND conname = 'inventory_stock_pkey') THEN ALTER TABLE public."inventory_stock" ADD CONSTRAINT "inventory_stock_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."inventory_stock"'::regclass AND conname = 'inventory_stock_product_id_warehouse_id_key') THEN ALTER TABLE public."inventory_stock" ADD CONSTRAINT "inventory_stock_product_id_warehouse_id_key" UNIQUE (product_id, warehouse_id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_evidence"'::regclass AND conname = 'investigation_evidence_pkey') THEN ALTER TABLE public."investigation_evidence" ADD CONSTRAINT "investigation_evidence_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_messages"'::regclass AND conname = 'investigation_messages_pkey') THEN ALTER TABLE public."investigation_messages" ADD CONSTRAINT "investigation_messages_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_tasks"'::regclass AND conname = 'investigation_tasks_pkey') THEN ALTER TABLE public."investigation_tasks" ADD CONSTRAINT "investigation_tasks_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_team_members"'::regclass AND conname = 'investigation_team_members_incident_id_user_id_key') THEN ALTER TABLE public."investigation_team_members" ADD CONSTRAINT "investigation_team_members_incident_id_user_id_key" UNIQUE (incident_id, user_id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_team_members"'::regclass AND conname = 'investigation_team_members_pkey') THEN ALTER TABLE public."investigation_team_members" ADD CONSTRAINT "investigation_team_members_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_timeline"'::regclass AND conname = 'investigation_timeline_pkey') THEN ALTER TABLE public."investigation_timeline" ADD CONSTRAINT "investigation_timeline_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."invoices"'::regclass AND conname = 'invoices_currency_check') THEN ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."invoices"'::regclass AND conname = 'invoices_invoice_number_key') THEN ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_invoice_number_key" UNIQUE (invoice_number); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."invoices"'::regclass AND conname = 'invoices_pkey') THEN ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ip_geolocation_cache"'::regclass AND conname = 'ip_geolocation_cache_ip_address_key') THEN ALTER TABLE public."ip_geolocation_cache" ADD CONSTRAINT "ip_geolocation_cache_ip_address_key" UNIQUE (ip_address); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ip_geolocation_cache"'::regclass AND conname = 'ip_geolocation_cache_pkey') THEN ALTER TABLE public."ip_geolocation_cache" ADD CONSTRAINT "ip_geolocation_cache_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ip_geolocation_cache"'::regclass AND conname = 'ip_geolocation_cache_threat_level_check') THEN ALTER TABLE public."ip_geolocation_cache" ADD CONSTRAINT "ip_geolocation_cache_threat_level_check" CHECK ((threat_level = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."ip_geolocation_cache"'::regclass AND conname = 'valid_coordinates') THEN ALTER TABLE public."ip_geolocation_cache" ADD CONSTRAINT "valid_coordinates" CHECK ((((latitude IS NULL) AND (longitude IS NULL)) OR ((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric) AND (longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric)))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."migration_repair_audit"'::regclass AND conname = 'migration_repair_audit_pkey') THEN ALTER TABLE public."migration_repair_audit" ADD CONSTRAINT "migration_repair_audit_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."notification_queue"'::regclass AND conname = 'notification_queue_pkey') THEN ALTER TABLE public."notification_queue" ADD CONSTRAINT "notification_queue_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."notification_templates"'::regclass AND conname = 'notification_templates_notification_type_key') THEN ALTER TABLE public."notification_templates" ADD CONSTRAINT "notification_templates_notification_type_key" UNIQUE (notification_type); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."notification_templates"'::regclass AND conname = 'notification_templates_pkey') THEN ALTER TABLE public."notification_templates" ADD CONSTRAINT "notification_templates_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."order_items"'::regclass AND conname = 'order_items_pkey') THEN ALTER TABLE public."order_items" ADD CONSTRAINT "order_items_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."payments"'::regclass AND conname = 'payments_currency_check') THEN ALTER TABLE public."payments" ADD CONSTRAINT "payments_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."payments"'::regclass AND conname = 'payments_pkey') THEN ALTER TABLE public."payments" ADD CONSTRAINT "payments_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."product_categories"'::regclass AND conname = 'product_categories_pkey') THEN ALTER TABLE public."product_categories" ADD CONSTRAINT "product_categories_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."products"'::regclass AND conname = 'products_currency_check') THEN ALTER TABLE public."products" ADD CONSTRAINT "products_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."products"'::regclass AND conname = 'products_pkey') THEN ALTER TABLE public."products" ADD CONSTRAINT "products_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."products"'::regclass AND conname = 'products_sku_key') THEN ALTER TABLE public."products" ADD CONSTRAINT "products_sku_key" UNIQUE (sku); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchase_items"'::regclass AND conname = 'purchase_items_pkey') THEN ALTER TABLE public."purchase_items" ADD CONSTRAINT "purchase_items_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchases"'::regclass AND conname = 'purchases_currency_check') THEN ALTER TABLE public."purchases" ADD CONSTRAINT "purchases_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchases"'::regclass AND conname = 'purchases_payment_status_check') THEN ALTER TABLE public."purchases" ADD CONSTRAINT "purchases_payment_status_check" CHECK ((payment_status = ANY (ARRAY['pending'::text, 'paid'::text, 'partial'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchases"'::regclass AND conname = 'purchases_pkey') THEN ALTER TABLE public."purchases" ADD CONSTRAINT "purchases_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchases"'::regclass AND conname = 'purchases_purchase_number_key') THEN ALTER TABLE public."purchases" ADD CONSTRAINT "purchases_purchase_number_key" UNIQUE (purchase_number); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchases"'::regclass AND conname = 'purchases_status_check') THEN ALTER TABLE public."purchases" ADD CONSTRAINT "purchases_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'received'::text, 'partial'::text, 'cancelled'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rule_actions"'::regclass AND conname = 'rule_actions_pkey') THEN ALTER TABLE public."rule_actions" ADD CONSTRAINT "rule_actions_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rule_conditions"'::regclass AND conname = 'rule_conditions_pkey') THEN ALTER TABLE public."rule_conditions" ADD CONSTRAINT "rule_conditions_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rule_execution_history"'::regclass AND conname = 'rule_execution_history_pkey') THEN ALTER TABLE public."rule_execution_history" ADD CONSTRAINT "rule_execution_history_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."sales_orders"'::regclass AND conname = 'sales_orders_currency_check') THEN ALTER TABLE public."sales_orders" ADD CONSTRAINT "sales_orders_currency_check" CHECK ((currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."sales_orders"'::regclass AND conname = 'sales_orders_order_number_key') THEN ALTER TABLE public."sales_orders" ADD CONSTRAINT "sales_orders_order_number_key" UNIQUE (order_number); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."sales_orders"'::regclass AND conname = 'sales_orders_payment_type_check') THEN ALTER TABLE public."sales_orders" ADD CONSTRAINT "sales_orders_payment_type_check" CHECK ((payment_type = ANY (ARRAY['cash'::text, 'credit'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."sales_orders"'::regclass AND conname = 'sales_orders_pkey') THEN ALTER TABLE public."sales_orders" ADD CONSTRAINT "sales_orders_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."screen_views"'::regclass AND conname = 'screen_views_pkey') THEN ALTER TABLE public."screen_views" ADD CONSTRAINT "screen_views_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."security_anomalies"'::regclass AND conname = 'security_anomalies_pkey') THEN ALTER TABLE public."security_anomalies" ADD CONSTRAINT "security_anomalies_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."security_thresholds"'::regclass AND conname = 'security_thresholds_pkey') THEN ALTER TABLE public."security_thresholds" ADD CONSTRAINT "security_thresholds_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."stock_movements"'::regclass AND conname = 'stock_movements_pkey') THEN ALTER TABLE public."stock_movements" ADD CONSTRAINT "stock_movements_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."suppliers"'::regclass AND conname = 'suppliers_pkey') THEN ALTER TABLE public."suppliers" ADD CONSTRAINT "suppliers_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."suppliers"'::regclass AND conname = 'suppliers_preferred_currency_check') THEN ALTER TABLE public."suppliers" ADD CONSTRAINT "suppliers_preferred_currency_check" CHECK ((preferred_currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."support_tickets"'::regclass AND conname = 'support_tickets_pkey') THEN ALTER TABLE public."support_tickets" ADD CONSTRAINT "support_tickets_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."support_tickets"'::regclass AND conname = 'support_tickets_priority_check') THEN ALTER TABLE public."support_tickets" ADD CONSTRAINT "support_tickets_priority_check" CHECK ((priority = ANY (ARRAY['low'::text, 'normal'::text, 'high'::text, 'urgent'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."support_tickets"'::regclass AND conname = 'support_tickets_status_check') THEN ALTER TABLE public."support_tickets" ADD CONSTRAINT "support_tickets_status_check" CHECK ((status = ANY (ARRAY['open'::text, 'in_progress'::text, 'resolved'::text, 'closed'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."system_configuration"'::regclass AND conname = 'system_configuration_config_key_key') THEN ALTER TABLE public."system_configuration" ADD CONSTRAINT "system_configuration_config_key_key" UNIQUE (config_key); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."system_configuration"'::regclass AND conname = 'system_configuration_pkey') THEN ALTER TABLE public."system_configuration" ADD CONSTRAINT "system_configuration_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_blocking_records"'::regclass AND conname = 'user_blocking_records_pkey') THEN ALTER TABLE public."user_blocking_records" ADD CONSTRAINT "user_blocking_records_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_permissions"'::regclass AND conname = 'user_permissions_pkey') THEN ALTER TABLE public."user_permissions" ADD CONSTRAINT "user_permissions_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_permissions"'::regclass AND conname = 'user_permissions_user_id_module_name_permission_type_key') THEN ALTER TABLE public."user_permissions" ADD CONSTRAINT "user_permissions_user_id_module_name_permission_type_key" UNIQUE (user_id, module_name, permission_type); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_profiles"'::regclass AND conname = 'user_profiles_display_currency_check') THEN ALTER TABLE public."user_profiles" ADD CONSTRAINT "user_profiles_display_currency_check" CHECK ((display_currency = ANY (ARRAY['CDF'::text, 'USD'::text]))); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_profiles"'::regclass AND conname = 'user_profiles_email_key') THEN ALTER TABLE public."user_profiles" ADD CONSTRAINT "user_profiles_email_key" UNIQUE (email); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_profiles"'::regclass AND conname = 'user_profiles_pkey') THEN ALTER TABLE public."user_profiles" ADD CONSTRAINT "user_profiles_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_risk_scores"'::regclass AND conname = 'user_risk_scores_pkey') THEN ALTER TABLE public."user_risk_scores" ADD CONSTRAINT "user_risk_scores_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_risk_scores"'::regclass AND conname = 'user_risk_scores_user_id_key') THEN ALTER TABLE public."user_risk_scores" ADD CONSTRAINT "user_risk_scores_user_id_key" UNIQUE (user_id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_sessions"'::regclass AND conname = 'user_sessions_pkey') THEN ALTER TABLE public."user_sessions" ADD CONSTRAINT "user_sessions_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."warehouse_locations"'::regclass AND conname = 'warehouse_locations_pkey') THEN ALTER TABLE public."warehouse_locations" ADD CONSTRAINT "warehouse_locations_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."workflow_states"'::regclass AND conname = 'workflow_states_pkey') THEN ALTER TABLE public."workflow_states" ADD CONSTRAINT "workflow_states_pkey" PRIMARY KEY (id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."accounting_entries"'::regclass AND conname = 'accounting_entries_created_by_fkey') THEN ALTER TABLE public."accounting_entries" ADD CONSTRAINT "accounting_entries_created_by_fkey" FOREIGN KEY (created_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."anomaly_correlation_patterns"'::regclass AND conname = 'anomaly_correlation_patterns_investigated_by_fkey') THEN ALTER TABLE public."anomaly_correlation_patterns" ADD CONSTRAINT "anomaly_correlation_patterns_investigated_by_fkey" FOREIGN KEY (investigated_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."anomaly_correlation_patterns"'::regclass AND conname = 'anomaly_correlation_patterns_user_id_fkey') THEN ALTER TABLE public."anomaly_correlation_patterns" ADD CONSTRAINT "anomaly_correlation_patterns_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."audit_logs"'::regclass AND conname = 'audit_logs_user_id_fkey') THEN ALTER TABLE public."audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."automation_rules"'::regclass AND conname = 'automation_rules_created_by_fkey') THEN ALTER TABLE public."automation_rules" ADD CONSTRAINT "automation_rules_created_by_fkey" FOREIGN KEY (created_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."bank_transactions"'::regclass AND conname = 'bank_transactions_bank_account_id_fkey') THEN ALTER TABLE public."bank_transactions" ADD CONSTRAINT "bank_transactions_bank_account_id_fkey" FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."bank_transactions"'::regclass AND conname = 'bank_transactions_created_by_fkey') THEN ALTER TABLE public."bank_transactions" ADD CONSTRAINT "bank_transactions_created_by_fkey" FOREIGN KEY (created_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."barcode_scans"'::regclass AND conname = 'barcode_scans_product_id_fkey') THEN ALTER TABLE public."barcode_scans" ADD CONSTRAINT "barcode_scans_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."barcode_scans"'::regclass AND conname = 'barcode_scans_scanned_by_fkey') THEN ALTER TABLE public."barcode_scans" ADD CONSTRAINT "barcode_scans_scanned_by_fkey" FOREIGN KEY (scanned_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."cash_movements"'::regclass AND conname = 'cash_movements_cash_register_id_fkey') THEN ALTER TABLE public."cash_movements" ADD CONSTRAINT "cash_movements_cash_register_id_fkey" FOREIGN KEY (cash_register_id) REFERENCES cash_registers(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."cash_movements"'::regclass AND conname = 'cash_movements_created_by_fkey') THEN ALTER TABLE public."cash_movements" ADD CONSTRAINT "cash_movements_created_by_fkey" FOREIGN KEY (created_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."customers"'::regclass AND conname = 'customers_commercial_id_fkey') THEN ALTER TABLE public."customers" ADD CONSTRAINT "customers_commercial_id_fkey" FOREIGN KEY (commercial_id) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."customers"'::regclass AND conname = 'customers_user_id_fkey') THEN ALTER TABLE public."customers" ADD CONSTRAINT "customers_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."deliveries"'::regclass AND conname = 'deliveries_order_id_fkey') THEN ALTER TABLE public."deliveries" ADD CONSTRAINT "deliveries_order_id_fkey" FOREIGN KEY (order_id) REFERENCES sales_orders(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."deliveries"'::regclass AND conname = 'deliveries_route_id_fkey') THEN ALTER TABLE public."deliveries" ADD CONSTRAINT "deliveries_route_id_fkey" FOREIGN KEY (route_id) REFERENCES delivery_routes(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."delivery_routes"'::regclass AND conname = 'delivery_routes_driver_id_fkey') THEN ALTER TABLE public."delivery_routes" ADD CONSTRAINT "delivery_routes_driver_id_fkey" FOREIGN KEY (driver_id) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."document_attachments"'::regclass AND conname = 'document_attachments_uploaded_by_fkey') THEN ALTER TABLE public."document_attachments" ADD CONSTRAINT "document_attachments_uploaded_by_fkey" FOREIGN KEY (uploaded_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."escalation_configurations"'::regclass AND conname = 'escalation_configurations_primary_admin_id_fkey') THEN ALTER TABLE public."escalation_configurations" ADD CONSTRAINT "escalation_configurations_primary_admin_id_fkey" FOREIGN KEY (primary_admin_id) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."escalation_history"'::regclass AND conname = 'escalation_history_anomaly_id_fkey') THEN ALTER TABLE public."escalation_history" ADD CONSTRAINT "escalation_history_anomaly_id_fkey" FOREIGN KEY (anomaly_id) REFERENCES security_anomalies(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."escalation_history"'::regclass AND conname = 'escalation_history_escalated_to_fkey') THEN ALTER TABLE public."escalation_history" ADD CONSTRAINT "escalation_history_escalated_to_fkey" FOREIGN KEY (escalated_to) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."escalation_history"'::regclass AND conname = 'escalation_history_escalation_config_id_fkey') THEN ALTER TABLE public."escalation_history" ADD CONSTRAINT "escalation_history_escalation_config_id_fkey" FOREIGN KEY (escalation_config_id) REFERENCES escalation_configurations(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expense_approval_history"'::regclass AND conname = 'expense_approval_history_expense_id_fkey') THEN ALTER TABLE public."expense_approval_history" ADD CONSTRAINT "expense_approval_history_expense_id_fkey" FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expense_approval_history"'::regclass AND conname = 'expense_approval_history_performed_by_fkey') THEN ALTER TABLE public."expense_approval_history" ADD CONSTRAINT "expense_approval_history_performed_by_fkey" FOREIGN KEY (performed_by) REFERENCES auth.users(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expenses"'::regclass AND conname = 'expenses_approved_by_fkey') THEN ALTER TABLE public."expenses" ADD CONSTRAINT "expenses_approved_by_fkey" FOREIGN KEY (approved_by) REFERENCES auth.users(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expenses"'::regclass AND conname = 'expenses_created_by_fkey') THEN ALTER TABLE public."expenses" ADD CONSTRAINT "expenses_created_by_fkey" FOREIGN KEY (created_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expenses"'::regclass AND conname = 'expenses_paid_by_fkey') THEN ALTER TABLE public."expenses" ADD CONSTRAINT "expenses_paid_by_fkey" FOREIGN KEY (paid_by) REFERENCES auth.users(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."expenses"'::regclass AND conname = 'expenses_requested_by_fkey') THEN ALTER TABLE public."expenses" ADD CONSTRAINT "expenses_requested_by_fkey" FOREIGN KEY (requested_by) REFERENCES auth.users(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."feature_usage_stats"'::regclass AND conname = 'feature_usage_stats_user_id_fkey') THEN ALTER TABLE public."feature_usage_stats" ADD CONSTRAINT "feature_usage_stats_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_event_timeline"'::regclass AND conname = 'forensic_event_timeline_audit_log_id_fkey') THEN ALTER TABLE public."forensic_event_timeline" ADD CONSTRAINT "forensic_event_timeline_audit_log_id_fkey" FOREIGN KEY (audit_log_id) REFERENCES audit_logs(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_event_timeline"'::regclass AND conname = 'forensic_event_timeline_device_fingerprint_id_fkey') THEN ALTER TABLE public."forensic_event_timeline" ADD CONSTRAINT "forensic_event_timeline_device_fingerprint_id_fkey" FOREIGN KEY (device_fingerprint_id) REFERENCES device_fingerprints(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_event_timeline"'::regclass AND conname = 'forensic_event_timeline_session_id_fkey') THEN ALTER TABLE public."forensic_event_timeline" ADD CONSTRAINT "forensic_event_timeline_session_id_fkey" FOREIGN KEY (session_id) REFERENCES user_sessions(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_event_timeline"'::regclass AND conname = 'forensic_event_timeline_user_id_fkey') THEN ALTER TABLE public."forensic_event_timeline" ADD CONSTRAINT "forensic_event_timeline_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_export_history"'::regclass AND conname = 'forensic_export_history_exported_by_fkey') THEN ALTER TABLE public."forensic_export_history" ADD CONSTRAINT "forensic_export_history_exported_by_fkey" FOREIGN KEY (exported_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_export_history"'::regclass AND conname = 'forensic_export_history_template_id_fkey') THEN ALTER TABLE public."forensic_export_history" ADD CONSTRAINT "forensic_export_history_template_id_fkey" FOREIGN KEY (template_id) REFERENCES forensic_export_templates(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_export_templates"'::regclass AND conname = 'forensic_export_templates_created_by_fkey') THEN ALTER TABLE public."forensic_export_templates" ADD CONSTRAINT "forensic_export_templates_created_by_fkey" FOREIGN KEY (created_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_investigation_reports"'::regclass AND conname = 'forensic_investigation_reports_investigator_id_fkey') THEN ALTER TABLE public."forensic_investigation_reports" ADD CONSTRAINT "forensic_investigation_reports_investigator_id_fkey" FOREIGN KEY (investigator_id) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."forensic_investigation_reports"'::regclass AND conname = 'forensic_investigation_reports_user_id_fkey') THEN ALTER TABLE public."forensic_investigation_reports" ADD CONSTRAINT "forensic_investigation_reports_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."inventory_stock"'::regclass AND conname = 'inventory_stock_product_id_fkey') THEN ALTER TABLE public."inventory_stock" ADD CONSTRAINT "inventory_stock_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."inventory_stock"'::regclass AND conname = 'inventory_stock_warehouse_id_fkey') THEN ALTER TABLE public."inventory_stock" ADD CONSTRAINT "inventory_stock_warehouse_id_fkey" FOREIGN KEY (warehouse_id) REFERENCES warehouse_locations(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_evidence"'::regclass AND conname = 'investigation_evidence_collected_by_fkey') THEN ALTER TABLE public."investigation_evidence" ADD CONSTRAINT "investigation_evidence_collected_by_fkey" FOREIGN KEY (collected_by) REFERENCES user_profiles(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_evidence"'::regclass AND conname = 'investigation_evidence_incident_id_fkey') THEN ALTER TABLE public."investigation_evidence" ADD CONSTRAINT "investigation_evidence_incident_id_fkey" FOREIGN KEY (incident_id) REFERENCES security_anomalies(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_messages"'::regclass AND conname = 'investigation_messages_incident_id_fkey') THEN ALTER TABLE public."investigation_messages" ADD CONSTRAINT "investigation_messages_incident_id_fkey" FOREIGN KEY (incident_id) REFERENCES security_anomalies(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_messages"'::regclass AND conname = 'investigation_messages_sender_id_fkey') THEN ALTER TABLE public."investigation_messages" ADD CONSTRAINT "investigation_messages_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES user_profiles(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_tasks"'::regclass AND conname = 'investigation_tasks_assigned_to_fkey') THEN ALTER TABLE public."investigation_tasks" ADD CONSTRAINT "investigation_tasks_assigned_to_fkey" FOREIGN KEY (assigned_to) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_tasks"'::regclass AND conname = 'investigation_tasks_created_by_fkey') THEN ALTER TABLE public."investigation_tasks" ADD CONSTRAINT "investigation_tasks_created_by_fkey" FOREIGN KEY (created_by) REFERENCES user_profiles(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_tasks"'::regclass AND conname = 'investigation_tasks_incident_id_fkey') THEN ALTER TABLE public."investigation_tasks" ADD CONSTRAINT "investigation_tasks_incident_id_fkey" FOREIGN KEY (incident_id) REFERENCES security_anomalies(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_team_members"'::regclass AND conname = 'investigation_team_members_assigned_by_fkey') THEN ALTER TABLE public."investigation_team_members" ADD CONSTRAINT "investigation_team_members_assigned_by_fkey" FOREIGN KEY (assigned_by) REFERENCES user_profiles(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_team_members"'::regclass AND conname = 'investigation_team_members_incident_id_fkey') THEN ALTER TABLE public."investigation_team_members" ADD CONSTRAINT "investigation_team_members_incident_id_fkey" FOREIGN KEY (incident_id) REFERENCES security_anomalies(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_team_members"'::regclass AND conname = 'investigation_team_members_user_id_fkey') THEN ALTER TABLE public."investigation_team_members" ADD CONSTRAINT "investigation_team_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_timeline"'::regclass AND conname = 'investigation_timeline_actor_id_fkey') THEN ALTER TABLE public."investigation_timeline" ADD CONSTRAINT "investigation_timeline_actor_id_fkey" FOREIGN KEY (actor_id) REFERENCES user_profiles(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."investigation_timeline"'::regclass AND conname = 'investigation_timeline_incident_id_fkey') THEN ALTER TABLE public."investigation_timeline" ADD CONSTRAINT "investigation_timeline_incident_id_fkey" FOREIGN KEY (incident_id) REFERENCES security_anomalies(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."invoices"'::regclass AND conname = 'invoices_customer_id_fkey') THEN ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."invoices"'::regclass AND conname = 'invoices_order_id_fkey') THEN ALTER TABLE public."invoices" ADD CONSTRAINT "invoices_order_id_fkey" FOREIGN KEY (order_id) REFERENCES sales_orders(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."notification_queue"'::regclass AND conname = 'notification_queue_recipient_id_fkey') THEN ALTER TABLE public."notification_queue" ADD CONSTRAINT "notification_queue_recipient_id_fkey" FOREIGN KEY (recipient_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."order_items"'::regclass AND conname = 'order_items_order_id_fkey') THEN ALTER TABLE public."order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY (order_id) REFERENCES sales_orders(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."order_items"'::regclass AND conname = 'order_items_product_id_fkey') THEN ALTER TABLE public."order_items" ADD CONSTRAINT "order_items_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."payments"'::regclass AND conname = 'payments_invoice_id_fkey') THEN ALTER TABLE public."payments" ADD CONSTRAINT "payments_invoice_id_fkey" FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."products"'::regclass AND conname = 'products_category_id_fkey') THEN ALTER TABLE public."products" ADD CONSTRAINT "products_category_id_fkey" FOREIGN KEY (category_id) REFERENCES product_categories(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchase_items"'::regclass AND conname = 'purchase_items_product_id_fkey') THEN ALTER TABLE public."purchase_items" ADD CONSTRAINT "purchase_items_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchase_items"'::regclass AND conname = 'purchase_items_purchase_id_fkey') THEN ALTER TABLE public."purchase_items" ADD CONSTRAINT "purchase_items_purchase_id_fkey" FOREIGN KEY (purchase_id) REFERENCES purchases(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchases"'::regclass AND conname = 'purchases_approved_by_fkey') THEN ALTER TABLE public."purchases" ADD CONSTRAINT "purchases_approved_by_fkey" FOREIGN KEY (approved_by) REFERENCES auth.users(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchases"'::regclass AND conname = 'purchases_created_by_fkey') THEN ALTER TABLE public."purchases" ADD CONSTRAINT "purchases_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchases"'::regclass AND conname = 'purchases_received_by_fkey') THEN ALTER TABLE public."purchases" ADD CONSTRAINT "purchases_received_by_fkey" FOREIGN KEY (received_by) REFERENCES auth.users(id); END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."purchases"'::regclass AND conname = 'purchases_supplier_id_fkey') THEN ALTER TABLE public."purchases" ADD CONSTRAINT "purchases_supplier_id_fkey" FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rule_actions"'::regclass AND conname = 'rule_actions_rule_id_fkey') THEN ALTER TABLE public."rule_actions" ADD CONSTRAINT "rule_actions_rule_id_fkey" FOREIGN KEY (rule_id) REFERENCES automation_rules(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rule_conditions"'::regclass AND conname = 'rule_conditions_rule_id_fkey') THEN ALTER TABLE public."rule_conditions" ADD CONSTRAINT "rule_conditions_rule_id_fkey" FOREIGN KEY (rule_id) REFERENCES automation_rules(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rule_execution_history"'::regclass AND conname = 'rule_execution_history_affected_user_id_fkey') THEN ALTER TABLE public."rule_execution_history" ADD CONSTRAINT "rule_execution_history_affected_user_id_fkey" FOREIGN KEY (affected_user_id) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."rule_execution_history"'::regclass AND conname = 'rule_execution_history_rule_id_fkey') THEN ALTER TABLE public."rule_execution_history" ADD CONSTRAINT "rule_execution_history_rule_id_fkey" FOREIGN KEY (rule_id) REFERENCES automation_rules(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."sales_orders"'::regclass AND conname = 'sales_orders_customer_id_fkey') THEN ALTER TABLE public."sales_orders" ADD CONSTRAINT "sales_orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."sales_orders"'::regclass AND conname = 'sales_orders_sales_rep_id_fkey') THEN ALTER TABLE public."sales_orders" ADD CONSTRAINT "sales_orders_sales_rep_id_fkey" FOREIGN KEY (sales_rep_id) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."screen_views"'::regclass AND conname = 'screen_views_session_id_fkey') THEN ALTER TABLE public."screen_views" ADD CONSTRAINT "screen_views_session_id_fkey" FOREIGN KEY (session_id) REFERENCES user_sessions(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."screen_views"'::regclass AND conname = 'screen_views_user_id_fkey') THEN ALTER TABLE public."screen_views" ADD CONSTRAINT "screen_views_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."security_anomalies"'::regclass AND conname = 'security_anomalies_resolved_by_fkey') THEN ALTER TABLE public."security_anomalies" ADD CONSTRAINT "security_anomalies_resolved_by_fkey" FOREIGN KEY (resolved_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."security_anomalies"'::regclass AND conname = 'security_anomalies_user_id_fkey') THEN ALTER TABLE public."security_anomalies" ADD CONSTRAINT "security_anomalies_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."stock_movements"'::regclass AND conname = 'stock_movements_created_by_fkey') THEN ALTER TABLE public."stock_movements" ADD CONSTRAINT "stock_movements_created_by_fkey" FOREIGN KEY (created_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."stock_movements"'::regclass AND conname = 'stock_movements_product_id_fkey') THEN ALTER TABLE public."stock_movements" ADD CONSTRAINT "stock_movements_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."stock_movements"'::regclass AND conname = 'stock_movements_warehouse_id_fkey') THEN ALTER TABLE public."stock_movements" ADD CONSTRAINT "stock_movements_warehouse_id_fkey" FOREIGN KEY (warehouse_id) REFERENCES warehouse_locations(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."support_tickets"'::regclass AND conname = 'support_tickets_assigned_to_fkey') THEN ALTER TABLE public."support_tickets" ADD CONSTRAINT "support_tickets_assigned_to_fkey" FOREIGN KEY (assigned_to) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."support_tickets"'::regclass AND conname = 'support_tickets_customer_id_fkey') THEN ALTER TABLE public."support_tickets" ADD CONSTRAINT "support_tickets_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."support_tickets"'::regclass AND conname = 'support_tickets_user_id_fkey') THEN ALTER TABLE public."support_tickets" ADD CONSTRAINT "support_tickets_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_blocking_records"'::regclass AND conname = 'user_blocking_records_blocked_by_fkey') THEN ALTER TABLE public."user_blocking_records" ADD CONSTRAINT "user_blocking_records_blocked_by_fkey" FOREIGN KEY (blocked_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_blocking_records"'::regclass AND conname = 'user_blocking_records_related_rule_id_fkey') THEN ALTER TABLE public."user_blocking_records" ADD CONSTRAINT "user_blocking_records_related_rule_id_fkey" FOREIGN KEY (related_rule_id) REFERENCES automation_rules(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_blocking_records"'::regclass AND conname = 'user_blocking_records_unblocked_by_fkey') THEN ALTER TABLE public."user_blocking_records" ADD CONSTRAINT "user_blocking_records_unblocked_by_fkey" FOREIGN KEY (unblocked_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_blocking_records"'::regclass AND conname = 'user_blocking_records_user_id_fkey') THEN ALTER TABLE public."user_blocking_records" ADD CONSTRAINT "user_blocking_records_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_permissions"'::regclass AND conname = 'user_permissions_user_id_fkey') THEN ALTER TABLE public."user_permissions" ADD CONSTRAINT "user_permissions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_profiles"'::regclass AND conname = 'user_profiles_id_fkey') THEN ALTER TABLE public."user_profiles" ADD CONSTRAINT "user_profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_risk_scores"'::regclass AND conname = 'user_risk_scores_user_id_fkey') THEN ALTER TABLE public."user_risk_scores" ADD CONSTRAINT "user_risk_scores_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."user_sessions"'::regclass AND conname = 'user_sessions_user_id_fkey') THEN ALTER TABLE public."user_sessions" ADD CONSTRAINT "user_sessions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."workflow_states"'::regclass AND conname = 'workflow_states_approved_by_fkey') THEN ALTER TABLE public."workflow_states" ADD CONSTRAINT "workflow_states_approved_by_fkey" FOREIGN KEY (approved_by) REFERENCES user_profiles(id) ON DELETE SET NULL; END IF; END $baseline$;

DO $baseline$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public."workflow_states"'::regclass AND conname = 'workflow_states_changed_by_fkey') THEN ALTER TABLE public."workflow_states" ADD CONSTRAINT "workflow_states_changed_by_fkey" FOREIGN KEY (changed_by) REFERENCES user_profiles(id) ON DELETE CASCADE; END IF; END $baseline$;

CREATE INDEX IF NOT EXISTS idx_accounting_entries_created_by ON public.accounting_entries USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_anomaly_correlation_risk ON public.anomaly_correlation_patterns USING btree (risk_level, investigation_status);

CREATE INDEX IF NOT EXISTS idx_anomaly_correlation_time ON public.anomaly_correlation_patterns USING btree (start_time, end_time);

CREATE INDEX IF NOT EXISTS idx_anomaly_correlation_user ON public.anomaly_correlation_patterns USING btree (user_id, detected_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_action_type ON public.audit_logs USING btree (action_type);

CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs USING btree (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_audit_logs_record_id ON public.audit_logs USING btree (record_id);

CREATE INDEX IF NOT EXISTS idx_audit_logs_table_name ON public.audit_logs USING btree (table_name);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_automation_rules_active ON public.automation_rules USING btree (is_active);

CREATE INDEX IF NOT EXISTS idx_automation_rules_trigger_type ON public.automation_rules USING btree (trigger_type);

CREATE INDEX IF NOT EXISTS idx_bank_transactions_bank_account_id ON public.bank_transactions USING btree (bank_account_id);

CREATE INDEX IF NOT EXISTS idx_bank_transactions_created_by ON public.bank_transactions USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_barcode_scans_product ON public.barcode_scans USING btree (product_id);

CREATE INDEX IF NOT EXISTS idx_customers_commercial_id ON public.customers USING btree (commercial_id);

CREATE INDEX IF NOT EXISTS idx_customers_user_commercial ON public.customers USING btree (user_id, commercial_id);

CREATE INDEX IF NOT EXISTS idx_customers_user_id ON public.customers USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_deliveries_order ON public.deliveries USING btree (order_id);

CREATE INDEX IF NOT EXISTS idx_deliveries_order_id ON public.deliveries USING btree (order_id);

CREATE INDEX IF NOT EXISTS idx_deliveries_order_route_status ON public.deliveries USING btree (order_id, route_id, status);

CREATE INDEX IF NOT EXISTS idx_deliveries_route ON public.deliveries USING btree (route_id);

CREATE INDEX IF NOT EXISTS idx_delivery_routes_driver_id ON public.delivery_routes USING btree (driver_id);

CREATE INDEX IF NOT EXISTS idx_device_fingerprint_hash ON public.device_fingerprints USING btree (fingerprint_hash);

CREATE INDEX IF NOT EXISTS idx_device_fingerprint_last_seen ON public.device_fingerprints USING btree (last_seen DESC);

CREATE INDEX IF NOT EXISTS idx_document_attachments_entity ON public.document_attachments USING btree (entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_document_attachments_uploaded_by ON public.document_attachments USING btree (uploaded_by);

CREATE INDEX IF NOT EXISTS idx_escalation_configurations_severity ON public.escalation_configurations USING btree (severity_level);

CREATE INDEX IF NOT EXISTS idx_escalation_history_anomaly ON public.escalation_history USING btree (anomaly_id);

CREATE INDEX IF NOT EXISTS idx_expense_approval_history_expense_id ON public.expense_approval_history USING btree (expense_id);

CREATE INDEX IF NOT EXISTS idx_expense_approval_history_performed_by ON public.expense_approval_history USING btree (performed_by);

CREATE INDEX IF NOT EXISTS idx_expenses_approved_by ON public.expenses USING btree (approved_by);

CREATE INDEX IF NOT EXISTS idx_expenses_paid_by ON public.expenses USING btree (paid_by);

CREATE INDEX IF NOT EXISTS idx_expenses_requested_by ON public.expenses USING btree (requested_by);

CREATE INDEX IF NOT EXISTS idx_failed_login_attempts_email ON public.failed_login_attempts USING btree (email);

CREATE INDEX IF NOT EXISTS idx_failed_login_attempts_ip ON public.failed_login_attempts USING btree (ip_address);

CREATE INDEX IF NOT EXISTS idx_failed_login_attempts_time ON public.failed_login_attempts USING btree (attempt_time);

CREATE INDEX IF NOT EXISTS idx_feature_usage_feature_name ON public.feature_usage_stats USING btree (feature_name);

CREATE INDEX IF NOT EXISTS idx_feature_usage_last_used ON public.feature_usage_stats USING btree (last_used_at DESC);

CREATE INDEX IF NOT EXISTS idx_feature_usage_module_name ON public.feature_usage_stats USING btree (module_name);

CREATE INDEX IF NOT EXISTS idx_feature_usage_user_id ON public.feature_usage_stats USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_feature_usage_user_module ON public.feature_usage_stats USING btree (user_id, module_name, last_used_at DESC);

CREATE INDEX IF NOT EXISTS idx_forensic_event_timeline_audit_log_id ON public.forensic_event_timeline USING btree (audit_log_id);

CREATE INDEX IF NOT EXISTS idx_forensic_event_timeline_user_id ON public.forensic_event_timeline USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_forensic_timeline_anomalous ON public.forensic_event_timeline USING btree (is_anomalous) WHERE (is_anomalous = true);

CREATE INDEX IF NOT EXISTS idx_forensic_timeline_session ON public.forensic_event_timeline USING btree (session_id);

CREATE INDEX IF NOT EXISTS idx_forensic_timeline_timestamp ON public.forensic_event_timeline USING btree (event_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_forensic_timeline_user ON public.forensic_event_timeline USING btree (user_id, event_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_export_history_date_range ON public.forensic_export_history USING btree (filter_start_date, filter_end_date);

CREATE INDEX IF NOT EXISTS idx_export_history_exported_at ON public.forensic_export_history USING btree (exported_at);

CREATE INDEX IF NOT EXISTS idx_export_history_exported_by ON public.forensic_export_history USING btree (exported_by);

CREATE INDEX IF NOT EXISTS idx_export_history_status ON public.forensic_export_history USING btree (status);

CREATE INDEX IF NOT EXISTS idx_export_history_template_id ON public.forensic_export_history USING btree (template_id);

CREATE INDEX IF NOT EXISTS idx_export_templates_active ON public.forensic_export_templates USING btree (is_active);

CREATE INDEX IF NOT EXISTS idx_export_templates_created_by ON public.forensic_export_templates USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_export_templates_type ON public.forensic_export_templates USING btree (template_type);

CREATE INDEX IF NOT EXISTS idx_forensic_reports_investigator ON public.forensic_investigation_reports USING btree (investigator_id);

CREATE INDEX IF NOT EXISTS idx_forensic_reports_time ON public.forensic_investigation_reports USING btree (time_range_start, time_range_end);

CREATE INDEX IF NOT EXISTS idx_forensic_reports_user ON public.forensic_investigation_reports USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_inventory_stock_product ON public.inventory_stock USING btree (product_id);

CREATE INDEX IF NOT EXISTS idx_inventory_stock_product_warehouse ON public.inventory_stock USING btree (product_id, warehouse_id);

CREATE INDEX IF NOT EXISTS idx_inventory_stock_warehouse ON public.inventory_stock USING btree (warehouse_id);

CREATE INDEX IF NOT EXISTS idx_evidence_category ON public.investigation_evidence USING btree (category);

CREATE INDEX IF NOT EXISTS idx_evidence_collected_by ON public.investigation_evidence USING btree (collected_by);

CREATE INDEX IF NOT EXISTS idx_evidence_critical ON public.investigation_evidence USING btree (is_critical);

CREATE INDEX IF NOT EXISTS idx_evidence_incident ON public.investigation_evidence USING btree (incident_id);

CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.investigation_messages USING btree (created_at);

CREATE INDEX IF NOT EXISTS idx_messages_incident ON public.investigation_messages USING btree (incident_id);

CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.investigation_messages USING btree (sender_id);

CREATE INDEX IF NOT EXISTS idx_investigation_tasks_incident_id ON public.investigation_tasks USING btree (incident_id);

CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.investigation_tasks USING btree (assigned_to);

CREATE INDEX IF NOT EXISTS idx_tasks_incident ON public.investigation_tasks USING btree (incident_id);

CREATE INDEX IF NOT EXISTS idx_tasks_sort_order ON public.investigation_tasks USING btree (sort_order);

CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.investigation_tasks USING btree (status);

CREATE INDEX IF NOT EXISTS idx_team_members_incident ON public.investigation_team_members USING btree (incident_id);

CREATE INDEX IF NOT EXISTS idx_team_members_role ON public.investigation_team_members USING btree (role);

CREATE INDEX IF NOT EXISTS idx_team_members_user ON public.investigation_team_members USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_timeline_created_at ON public.investigation_timeline USING btree (created_at);

CREATE INDEX IF NOT EXISTS idx_timeline_incident ON public.investigation_timeline USING btree (incident_id);

CREATE INDEX IF NOT EXISTS idx_invoices_customer ON public.invoices USING btree (customer_id);

CREATE INDEX IF NOT EXISTS idx_invoices_customer_id ON public.invoices USING btree (customer_id);

CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON public.invoices USING btree (invoice_number);

CREATE INDEX IF NOT EXISTS idx_invoices_order ON public.invoices USING btree (order_id);

CREATE INDEX IF NOT EXISTS idx_invoices_order_customer ON public.invoices USING btree (order_id, customer_id);

CREATE INDEX IF NOT EXISTS idx_ip_geolocation_ip ON public.ip_geolocation_cache USING btree (ip_address);

CREATE INDEX IF NOT EXISTS idx_ip_geolocation_proxy ON public.ip_geolocation_cache USING btree (is_proxy, is_vpn) WHERE ((is_proxy = true) OR (is_vpn = true));

CREATE INDEX IF NOT EXISTS idx_ip_geolocation_threat ON public.ip_geolocation_cache USING btree (threat_level) WHERE (threat_level = ANY (ARRAY['high'::text, 'medium'::text]));

CREATE INDEX IF NOT EXISTS idx_notification_queue_recipient ON public.notification_queue USING btree (recipient_id);

CREATE INDEX IF NOT EXISTS idx_notification_queue_scheduled ON public.notification_queue USING btree (scheduled_at);

CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON public.notification_queue USING btree (status);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items USING btree (order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items USING btree (order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product ON public.order_items USING btree (product_id);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON public.order_items USING btree (product_id);

CREATE INDEX IF NOT EXISTS idx_payments_invoice ON public.payments USING btree (invoice_id);

CREATE INDEX IF NOT EXISTS idx_payments_invoice_id ON public.payments USING btree (invoice_id);

CREATE INDEX IF NOT EXISTS idx_products_barcode ON public.products USING btree (barcode);

CREATE INDEX IF NOT EXISTS idx_products_category ON public.products USING btree (category_id);

CREATE INDEX IF NOT EXISTS idx_products_sku ON public.products USING btree (sku);

CREATE INDEX IF NOT EXISTS idx_purchase_items_product_id ON public.purchase_items USING btree (product_id);

CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON public.purchase_items USING btree (purchase_id);

CREATE INDEX IF NOT EXISTS idx_purchases_created_by ON public.purchases USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_purchases_supplier_id ON public.purchases USING btree (supplier_id);

CREATE INDEX IF NOT EXISTS idx_rule_actions_rule_id ON public.rule_actions USING btree (rule_id);

CREATE INDEX IF NOT EXISTS idx_rule_conditions_rule_id ON public.rule_conditions USING btree (rule_id);

CREATE INDEX IF NOT EXISTS idx_rule_execution_history_rule_id ON public.rule_execution_history USING btree (rule_id);

CREATE INDEX IF NOT EXISTS idx_rule_execution_history_user ON public.rule_execution_history USING btree (affected_user_id);

CREATE INDEX IF NOT EXISTS idx_sales_orders_customer ON public.sales_orders USING btree (customer_id);

CREATE INDEX IF NOT EXISTS idx_sales_orders_customer_id ON public.sales_orders USING btree (customer_id);

CREATE INDEX IF NOT EXISTS idx_sales_orders_customer_status_date ON public.sales_orders USING btree (customer_id, order_status, order_date DESC);

CREATE INDEX IF NOT EXISTS idx_sales_orders_order_number ON public.sales_orders USING btree (order_number);

CREATE INDEX IF NOT EXISTS idx_sales_orders_sales_rep ON public.sales_orders USING btree (sales_rep_id);

CREATE INDEX IF NOT EXISTS idx_sales_orders_sales_rep_date ON public.sales_orders USING btree (sales_rep_id, order_date DESC);

CREATE INDEX IF NOT EXISTS idx_sales_orders_status ON public.sales_orders USING btree (order_status);

CREATE INDEX IF NOT EXISTS idx_screen_views_screen_category ON public.screen_views USING btree (screen_category);

CREATE INDEX IF NOT EXISTS idx_screen_views_screen_name ON public.screen_views USING btree (screen_name);

CREATE INDEX IF NOT EXISTS idx_screen_views_session_id ON public.screen_views USING btree (session_id);

CREATE INDEX IF NOT EXISTS idx_screen_views_timestamp ON public.screen_views USING btree (view_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_screen_views_user_id ON public.screen_views USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_screen_views_user_time ON public.screen_views USING btree (user_id, view_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_security_anomalies_category ON public.security_anomalies USING btree (category);

CREATE INDEX IF NOT EXISTS idx_security_anomalies_detected_at ON public.security_anomalies USING btree (detected_at);

CREATE INDEX IF NOT EXISTS idx_security_anomalies_severity ON public.security_anomalies USING btree (severity);

CREATE INDEX IF NOT EXISTS idx_security_anomalies_status ON public.security_anomalies USING btree (alert_status);

CREATE INDEX IF NOT EXISTS idx_security_anomalies_user_id ON public.security_anomalies USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_security_thresholds_category ON public.security_thresholds USING btree (category);

CREATE INDEX IF NOT EXISTS idx_stock_movements_created_by ON public.stock_movements USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON public.stock_movements USING btree (product_id);

CREATE INDEX IF NOT EXISTS idx_stock_movements_product_id ON public.stock_movements USING btree (product_id);

CREATE INDEX IF NOT EXISTS idx_support_tickets_customer ON public.support_tickets USING btree (customer_id);

CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets USING btree (status);

CREATE INDEX IF NOT EXISTS idx_support_tickets_user ON public.support_tickets USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_system_config_category ON public.system_configuration USING btree (category);

CREATE INDEX IF NOT EXISTS idx_system_config_company ON public.system_configuration USING btree (company_id);

CREATE INDEX IF NOT EXISTS idx_user_blocking_records_status ON public.user_blocking_records USING btree (blocking_status);

CREATE INDEX IF NOT EXISTS idx_user_blocking_records_user_id ON public.user_blocking_records USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_user_permissions_module ON public.user_permissions USING btree (module_name);

CREATE INDEX IF NOT EXISTS idx_user_permissions_user_id ON public.user_permissions USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles USING btree (email);

CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles USING btree (role);

CREATE INDEX IF NOT EXISTS idx_user_risk_scores_user_id ON public.user_risk_scores USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_user_sessions_created_at ON public.user_sessions USING btree (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_sessions_session_start ON public.user_sessions USING btree (session_start);

CREATE INDEX IF NOT EXISTS idx_user_sessions_status ON public.user_sessions USING btree (status);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_workflow_states_changed_by ON public.workflow_states USING btree (changed_by);

CREATE INDEX IF NOT EXISTS idx_workflow_states_current ON public.workflow_states USING btree (current_state);

CREATE INDEX IF NOT EXISTS idx_workflow_states_entity ON public.workflow_states USING btree (entity_type, entity_id);

CREATE OR REPLACE VIEW public."receivables_aging" AS SELECT c.id AS customer_id,
    c.company_name,
    c.contact_person,
    c.email,
    c.phone,
    so.id AS order_id,
    so.order_number,
    so.total_amount,
    so.currency,
    so.payment_type,
    so.created_at AS order_date,
    so.due_date,
    so.payment_status,
    EXTRACT(day FROM now() - so.created_at) AS days_outstanding,
        CASE
            WHEN EXTRACT(day FROM now() - so.created_at) <= 30::numeric THEN '0-30 jours'::text
            WHEN EXTRACT(day FROM now() - so.created_at) <= 60::numeric THEN '31-60 jours'::text
            WHEN EXTRACT(day FROM now() - so.created_at) <= 90::numeric THEN '61-90 jours'::text
            ELSE '90+ jours'::text
        END AS aging_bracket
   FROM sales_orders so
     JOIN customers c ON so.customer_id = c.id
  WHERE so.payment_type = 'credit'::text AND so.payment_status <> 'paid'::payment_status;

DROP POLICY IF EXISTS "accounting_entries_finance_manage" ON "public"."accounting_entries";

CREATE POLICY "accounting_entries_finance_manage" ON "public"."accounting_entries" AS PERMISSIVE FOR ALL TO "authenticated" USING (can_read_finance()) WITH CHECK (can_read_finance());

DROP POLICY IF EXISTS "ai_insights_admin_manage" ON "public"."ai_insights";

CREATE POLICY "ai_insights_admin_manage" ON "public"."ai_insights" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "ai_insights_admin_read" ON "public"."ai_insights";

CREATE POLICY "ai_insights_admin_read" ON "public"."ai_insights" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_admin() OR is_comptable()));

DROP POLICY IF EXISTS "admin_manage_correlations" ON "public"."anomaly_correlation_patterns";

CREATE POLICY "admin_manage_correlations" ON "public"."anomaly_correlation_patterns" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin_from_auth()) WITH CHECK (is_admin_from_auth());

DROP POLICY IF EXISTS "users_view_own_correlations" ON "public"."anomaly_correlation_patterns";

CREATE POLICY "users_view_own_correlations" ON "public"."anomaly_correlation_patterns" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_view_all_audit_logs" ON "public"."audit_logs";

CREATE POLICY "admin_view_all_audit_logs" ON "public"."audit_logs" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_system_admin());

DROP POLICY IF EXISTS "users_view_own_audit_logs" ON "public"."audit_logs";

CREATE POLICY "users_view_own_audit_logs" ON "public"."audit_logs" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_full_access_automation_rules" ON "public"."automation_rules";

CREATE POLICY "admin_full_access_automation_rules" ON "public"."automation_rules" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "bank_accounts_admin_comptable_manage" ON "public"."bank_accounts";

CREATE POLICY "bank_accounts_admin_comptable_manage" ON "public"."bank_accounts" AS PERMISSIVE FOR ALL TO "authenticated" USING (can_read_finance()) WITH CHECK (can_read_finance());

DROP POLICY IF EXISTS "bank_accounts_finance_read" ON "public"."bank_accounts";

CREATE POLICY "bank_accounts_finance_read" ON "public"."bank_accounts" AS PERMISSIVE FOR SELECT TO "authenticated" USING (can_read_finance());

DROP POLICY IF EXISTS "bank_transactions_admin_comptable_manage" ON "public"."bank_transactions";

CREATE POLICY "bank_transactions_admin_comptable_manage" ON "public"."bank_transactions" AS PERMISSIVE FOR ALL TO "authenticated" USING (can_read_finance()) WITH CHECK (can_read_finance());

DROP POLICY IF EXISTS "bank_transactions_finance_read" ON "public"."bank_transactions";

CREATE POLICY "bank_transactions_finance_read" ON "public"."bank_transactions" AS PERMISSIVE FOR SELECT TO "authenticated" USING (can_read_finance());

DROP POLICY IF EXISTS "warehouse_staff_manage_scans" ON "public"."barcode_scans";

CREATE POLICY "warehouse_staff_manage_scans" ON "public"."barcode_scans" AS PERMISSIVE FOR ALL TO "authenticated" USING ((is_warehouse_staff() OR is_admin())) WITH CHECK ((is_warehouse_staff() OR is_admin()));

DROP POLICY IF EXISTS "cash_movements_admin_comptable_manage" ON "public"."cash_movements";

CREATE POLICY "cash_movements_admin_comptable_manage" ON "public"."cash_movements" AS PERMISSIVE FOR ALL TO "authenticated" USING (can_read_finance()) WITH CHECK (can_read_finance());

DROP POLICY IF EXISTS "cash_movements_finance_read" ON "public"."cash_movements";

CREATE POLICY "cash_movements_finance_read" ON "public"."cash_movements" AS PERMISSIVE FOR SELECT TO "authenticated" USING (can_read_finance());

DROP POLICY IF EXISTS "cash_registers_admin_comptable_manage" ON "public"."cash_registers";

CREATE POLICY "cash_registers_admin_comptable_manage" ON "public"."cash_registers" AS PERMISSIVE FOR ALL TO "authenticated" USING (can_read_finance()) WITH CHECK (can_read_finance());

DROP POLICY IF EXISTS "cash_registers_finance_read" ON "public"."cash_registers";

CREATE POLICY "cash_registers_finance_read" ON "public"."cash_registers" AS PERMISSIVE FOR SELECT TO "authenticated" USING (can_read_finance());

DROP POLICY IF EXISTS "admin_full_access_customers" ON "public"."customers";

CREATE POLICY "admin_full_access_customers" ON "public"."customers" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "client_view_own_customer_record" ON "public"."customers";

CREATE POLICY "client_view_own_customer_record" ON "public"."customers" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_b2b_customer() AND (user_id = auth.uid())));

DROP POLICY IF EXISTS "commercial_access_assigned_customers" ON "public"."customers";

CREATE POLICY "commercial_access_assigned_customers" ON "public"."customers" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_sales_rep() AND (commercial_id = auth.uid())));

DROP POLICY IF EXISTS "commercial_insert_customers" ON "public"."customers";

CREATE POLICY "commercial_insert_customers" ON "public"."customers" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((is_sales_rep() AND (commercial_id = auth.uid())));

DROP POLICY IF EXISTS "commercial_update_assigned_customers" ON "public"."customers";

CREATE POLICY "commercial_update_assigned_customers" ON "public"."customers" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((is_sales_rep() AND (commercial_id = auth.uid()))) WITH CHECK ((is_sales_rep() AND (commercial_id = auth.uid())));

DROP POLICY IF EXISTS "admin_manage_deliveries" ON "public"."deliveries";

CREATE POLICY "admin_manage_deliveries" ON "public"."deliveries" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "delivery_agent_read_assigned_deliveries" ON "public"."deliveries";

CREATE POLICY "delivery_agent_read_assigned_deliveries" ON "public"."deliveries" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_delivery_agent() AND (route_id IN ( SELECT delivery_routes.id
   FROM delivery_routes
  WHERE (delivery_routes.driver_id = auth.uid())))));

DROP POLICY IF EXISTS "delivery_agent_update_assigned_deliveries" ON "public"."deliveries";

CREATE POLICY "delivery_agent_update_assigned_deliveries" ON "public"."deliveries" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((is_delivery_agent() AND (route_id IN ( SELECT delivery_routes.id
   FROM delivery_routes
  WHERE (delivery_routes.driver_id = auth.uid()))))) WITH CHECK ((is_delivery_agent() AND (route_id IN ( SELECT delivery_routes.id
   FROM delivery_routes
  WHERE (delivery_routes.driver_id = auth.uid())))));

DROP POLICY IF EXISTS "users_view_relevant_deliveries" ON "public"."deliveries";

CREATE POLICY "users_view_relevant_deliveries" ON "public"."deliveries" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((order_id IN ( SELECT sales_orders.id
   FROM sales_orders
  WHERE (sales_orders.customer_id IN ( SELECT customers.id
           FROM customers
          WHERE (customers.user_id = auth.uid()))))) OR (route_id IN ( SELECT delivery_routes.id
   FROM delivery_routes
  WHERE (delivery_routes.driver_id = auth.uid()))) OR is_admin()));

DROP POLICY IF EXISTS "admin_manage_routes" ON "public"."delivery_routes";

CREATE POLICY "admin_manage_routes" ON "public"."delivery_routes" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "delivery_agent_read_routes" ON "public"."delivery_routes";

CREATE POLICY "delivery_agent_read_routes" ON "public"."delivery_routes" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_delivery_agent() AND (driver_id = auth.uid())));

DROP POLICY IF EXISTS "drivers_view_own_routes" ON "public"."delivery_routes";

CREATE POLICY "drivers_view_own_routes" ON "public"."delivery_routes" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((driver_id = auth.uid()) OR is_admin()));

DROP POLICY IF EXISTS "admin_view_device_fingerprints" ON "public"."device_fingerprints";

CREATE POLICY "admin_view_device_fingerprints" ON "public"."device_fingerprints" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin_from_auth());

DROP POLICY IF EXISTS "admin_full_access_documents" ON "public"."document_attachments";

CREATE POLICY "admin_full_access_documents" ON "public"."document_attachments" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "sales_rep_manage_customer_documents" ON "public"."document_attachments";

CREATE POLICY "sales_rep_manage_customer_documents" ON "public"."document_attachments" AS PERMISSIVE FOR ALL TO "authenticated" USING ((is_sales_rep() AND (entity_type = 'customer'::attachment_entity_type) AND (EXISTS ( SELECT 1
   FROM customers c
  WHERE ((c.id = document_attachments.entity_id) AND (c.commercial_id = auth.uid())))))) WITH CHECK ((is_sales_rep() AND (entity_type = 'customer'::attachment_entity_type) AND (EXISTS ( SELECT 1
   FROM customers c
  WHERE ((c.id = document_attachments.entity_id) AND (c.commercial_id = auth.uid()))))));

DROP POLICY IF EXISTS "warehouse_manage_operational_documents" ON "public"."document_attachments";

CREATE POLICY "warehouse_manage_operational_documents" ON "public"."document_attachments" AS PERMISSIVE FOR ALL TO "authenticated" USING ((is_warehouse_staff() AND (entity_type = ANY (ARRAY['purchase_order'::attachment_entity_type, 'delivery'::attachment_entity_type]))));

DROP POLICY IF EXISTS "admin_full_access_escalation_config" ON "public"."escalation_configurations";

CREATE POLICY "admin_full_access_escalation_config" ON "public"."escalation_configurations" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "admin_view_escalation_history" ON "public"."escalation_history";

CREATE POLICY "admin_view_escalation_history" ON "public"."escalation_history" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin());

DROP POLICY IF EXISTS "exchange_rates_admin_manage" ON "public"."exchange_rates";

CREATE POLICY "exchange_rates_admin_manage" ON "public"."exchange_rates" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "exchange_rates_read" ON "public"."exchange_rates";

CREATE POLICY "exchange_rates_read" ON "public"."exchange_rates" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);

DROP POLICY IF EXISTS "expense_approval_admin_all" ON "public"."expense_approval_history";

CREATE POLICY "expense_approval_admin_all" ON "public"."expense_approval_history" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "expense_approval_comptable_insert" ON "public"."expense_approval_history";

CREATE POLICY "expense_approval_comptable_insert" ON "public"."expense_approval_history" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (is_comptable());

DROP POLICY IF EXISTS "expense_approval_comptable_select" ON "public"."expense_approval_history";

CREATE POLICY "expense_approval_comptable_select" ON "public"."expense_approval_history" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_comptable());

DROP POLICY IF EXISTS "expense_approval_comptable_update" ON "public"."expense_approval_history";

CREATE POLICY "expense_approval_comptable_update" ON "public"."expense_approval_history" AS PERMISSIVE FOR UPDATE TO "authenticated" USING (is_comptable()) WITH CHECK (is_comptable());

DROP POLICY IF EXISTS "admin_full_access_expenses" ON "public"."expenses";

CREATE POLICY "admin_full_access_expenses" ON "public"."expenses" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "admin_view_failed_logins" ON "public"."failed_login_attempts";

CREATE POLICY "admin_view_failed_logins" ON "public"."failed_login_attempts" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin());

DROP POLICY IF EXISTS "admin_view_all_feature_usage" ON "public"."feature_usage_stats";

CREATE POLICY "admin_view_all_feature_usage" ON "public"."feature_usage_stats" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin_from_auth());

DROP POLICY IF EXISTS "users_manage_own_feature_usage" ON "public"."feature_usage_stats";

CREATE POLICY "users_manage_own_feature_usage" ON "public"."feature_usage_stats" AS PERMISSIVE FOR ALL TO "authenticated" USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_view_all_timeline" ON "public"."forensic_event_timeline";

CREATE POLICY "admin_view_all_timeline" ON "public"."forensic_event_timeline" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin_from_auth());

DROP POLICY IF EXISTS "users_view_own_timeline" ON "public"."forensic_event_timeline";

CREATE POLICY "users_view_own_timeline" ON "public"."forensic_event_timeline" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_view_all_exports" ON "public"."forensic_export_history";

CREATE POLICY "admin_view_all_exports" ON "public"."forensic_export_history" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin_from_auth());

DROP POLICY IF EXISTS "users_manage_own_exports" ON "public"."forensic_export_history";

CREATE POLICY "users_manage_own_exports" ON "public"."forensic_export_history" AS PERMISSIVE FOR ALL TO "authenticated" USING ((exported_by = auth.uid())) WITH CHECK ((exported_by = auth.uid()));

DROP POLICY IF EXISTS "admin_manage_export_templates" ON "public"."forensic_export_templates";

CREATE POLICY "admin_manage_export_templates" ON "public"."forensic_export_templates" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin_from_auth()) WITH CHECK (is_admin_from_auth());

DROP POLICY IF EXISTS "admin_manage_reports" ON "public"."forensic_investigation_reports";

CREATE POLICY "admin_manage_reports" ON "public"."forensic_investigation_reports" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin_from_auth()) WITH CHECK (is_admin_from_auth());

DROP POLICY IF EXISTS "users_view_own_reports" ON "public"."forensic_investigation_reports";

CREATE POLICY "users_view_own_reports" ON "public"."forensic_investigation_reports" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((user_id = auth.uid()) OR (investigator_id = auth.uid())));

DROP POLICY IF EXISTS "admin_full_access_inventory" ON "public"."inventory_stock";

CREATE POLICY "admin_full_access_inventory" ON "public"."inventory_stock" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "commercial_view_inventory" ON "public"."inventory_stock";

CREATE POLICY "commercial_view_inventory" ON "public"."inventory_stock" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_sales_rep());

DROP POLICY IF EXISTS "depot_manage_inventory" ON "public"."inventory_stock";

CREATE POLICY "depot_manage_inventory" ON "public"."inventory_stock" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_warehouse_staff()) WITH CHECK (is_warehouse_staff());

DROP POLICY IF EXISTS "admin_full_access_evidence" ON "public"."investigation_evidence";

CREATE POLICY "admin_full_access_evidence" ON "public"."investigation_evidence" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin_from_auth()) WITH CHECK (is_admin_from_auth());

DROP POLICY IF EXISTS "team_members_access_investigation_evidence" ON "public"."investigation_evidence";

CREATE POLICY "team_members_access_investigation_evidence" ON "public"."investigation_evidence" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_investigation_team_member(incident_id)) WITH CHECK (is_investigation_team_member(incident_id));

DROP POLICY IF EXISTS "admin_full_access_messages" ON "public"."investigation_messages";

CREATE POLICY "admin_full_access_messages" ON "public"."investigation_messages" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin_from_auth()) WITH CHECK (is_admin_from_auth());

DROP POLICY IF EXISTS "team_members_access_investigation_messages" ON "public"."investigation_messages";

CREATE POLICY "team_members_access_investigation_messages" ON "public"."investigation_messages" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_investigation_team_member(incident_id)) WITH CHECK (is_investigation_team_member(incident_id));

DROP POLICY IF EXISTS "admin_full_access_tasks" ON "public"."investigation_tasks";

CREATE POLICY "admin_full_access_tasks" ON "public"."investigation_tasks" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin_from_auth()) WITH CHECK (is_admin_from_auth());

DROP POLICY IF EXISTS "team_members_access_investigation_tasks" ON "public"."investigation_tasks";

CREATE POLICY "team_members_access_investigation_tasks" ON "public"."investigation_tasks" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_investigation_team_member(incident_id)) WITH CHECK (is_investigation_team_member(incident_id));

DROP POLICY IF EXISTS "admin_full_access_team_members" ON "public"."investigation_team_members";

CREATE POLICY "admin_full_access_team_members" ON "public"."investigation_team_members" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin_from_auth()) WITH CHECK (is_admin_from_auth());

DROP POLICY IF EXISTS "team_members_access_investigation_team" ON "public"."investigation_team_members";

CREATE POLICY "team_members_access_investigation_team" ON "public"."investigation_team_members" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_investigation_team_member(incident_id)) WITH CHECK (is_investigation_team_member(incident_id));

DROP POLICY IF EXISTS "admin_full_access_timeline" ON "public"."investigation_timeline";

CREATE POLICY "admin_full_access_timeline" ON "public"."investigation_timeline" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin_from_auth()) WITH CHECK (is_admin_from_auth());

DROP POLICY IF EXISTS "team_members_access_investigation_timeline" ON "public"."investigation_timeline";

CREATE POLICY "team_members_access_investigation_timeline" ON "public"."investigation_timeline" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_investigation_team_member(incident_id));

DROP POLICY IF EXISTS "admin_full_access_invoices" ON "public"."invoices";

CREATE POLICY "admin_full_access_invoices" ON "public"."invoices" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "client_view_own_invoices" ON "public"."invoices";

CREATE POLICY "client_view_own_invoices" ON "public"."invoices" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_b2b_customer() AND (customer_id IN ( SELECT customers.id
   FROM customers
  WHERE (customers.user_id = auth.uid())))));

DROP POLICY IF EXISTS "commercial_view_customer_invoices" ON "public"."invoices";

CREATE POLICY "commercial_view_customer_invoices" ON "public"."invoices" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_sales_rep() AND (customer_id IN ( SELECT customers.id
   FROM customers
  WHERE (customers.commercial_id = auth.uid())))));

DROP POLICY IF EXISTS "comptable_read_all_invoices" ON "public"."invoices";

CREATE POLICY "comptable_read_all_invoices" ON "public"."invoices" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_comptable());

DROP POLICY IF EXISTS "admin_view_ip_geolocation" ON "public"."ip_geolocation_cache";

CREATE POLICY "admin_view_ip_geolocation" ON "public"."ip_geolocation_cache" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin_from_auth());

DROP POLICY IF EXISTS "admin_read_migration_repair_audit" ON "public"."migration_repair_audit";

CREATE POLICY "admin_read_migration_repair_audit" ON "public"."migration_repair_audit" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin());

DROP POLICY IF EXISTS "admin_manage_notifications" ON "public"."notification_queue";

CREATE POLICY "admin_manage_notifications" ON "public"."notification_queue" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "users_create_own_notifications" ON "public"."notification_queue";

CREATE POLICY "users_create_own_notifications" ON "public"."notification_queue" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK (((recipient_id = auth.uid()) OR is_admin()));

DROP POLICY IF EXISTS "users_update_own_notifications" ON "public"."notification_queue";

CREATE POLICY "users_update_own_notifications" ON "public"."notification_queue" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((recipient_id = auth.uid())) WITH CHECK ((recipient_id = auth.uid()));

DROP POLICY IF EXISTS "users_view_own_notifications" ON "public"."notification_queue";

CREATE POLICY "users_view_own_notifications" ON "public"."notification_queue" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((recipient_id = auth.uid()));

DROP POLICY IF EXISTS "admin_manage_templates" ON "public"."notification_templates";

CREATE POLICY "admin_manage_templates" ON "public"."notification_templates" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "authenticated_view_templates" ON "public"."notification_templates";

CREATE POLICY "authenticated_view_templates" ON "public"."notification_templates" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);

DROP POLICY IF EXISTS "admin_full_access_order_items" ON "public"."order_items";

CREATE POLICY "admin_full_access_order_items" ON "public"."order_items" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "client_view_own_order_items" ON "public"."order_items";

CREATE POLICY "client_view_own_order_items" ON "public"."order_items" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_b2b_customer() AND (order_id IN ( SELECT so.id
   FROM (sales_orders so
     JOIN customers c ON ((so.customer_id = c.id)))
  WHERE (c.user_id = auth.uid())))));

DROP POLICY IF EXISTS "commercial_access_assigned_order_items" ON "public"."order_items";

CREATE POLICY "commercial_access_assigned_order_items" ON "public"."order_items" AS PERMISSIVE FOR ALL TO "authenticated" USING ((is_sales_rep() AND (order_id IN ( SELECT so.id
   FROM (sales_orders so
     JOIN customers c ON ((so.customer_id = c.id)))
  WHERE (c.commercial_id = auth.uid()))))) WITH CHECK ((is_sales_rep() AND (order_id IN ( SELECT so.id
   FROM (sales_orders so
     JOIN customers c ON ((so.customer_id = c.id)))
  WHERE (c.commercial_id = auth.uid())))));

DROP POLICY IF EXISTS "comptable_read_all_order_items" ON "public"."order_items";

CREATE POLICY "comptable_read_all_order_items" ON "public"."order_items" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_comptable());

DROP POLICY IF EXISTS "admin_full_access_payments" ON "public"."payments";

CREATE POLICY "admin_full_access_payments" ON "public"."payments" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "commercial_manage_customer_payments" ON "public"."payments";

CREATE POLICY "commercial_manage_customer_payments" ON "public"."payments" AS PERMISSIVE FOR ALL TO "authenticated" USING ((is_sales_rep() AND (invoice_id IN ( SELECT i.id
   FROM (invoices i
     JOIN customers c ON ((i.customer_id = c.id)))
  WHERE (c.commercial_id = auth.uid()))))) WITH CHECK ((is_sales_rep() AND (invoice_id IN ( SELECT i.id
   FROM (invoices i
     JOIN customers c ON ((i.customer_id = c.id)))
  WHERE (c.commercial_id = auth.uid())))));

DROP POLICY IF EXISTS "comptable_read_all_payments" ON "public"."payments";

CREATE POLICY "comptable_read_all_payments" ON "public"."payments" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_comptable());

DROP POLICY IF EXISTS "admin_manage_categories" ON "public"."product_categories";

CREATE POLICY "admin_manage_categories" ON "public"."product_categories" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "all_users_view_categories" ON "public"."product_categories";

CREATE POLICY "all_users_view_categories" ON "public"."product_categories" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);

DROP POLICY IF EXISTS "admin_full_access_products" ON "public"."products";

CREATE POLICY "admin_full_access_products" ON "public"."products" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "b2b_customer_view_active_products" ON "public"."products";

CREATE POLICY "b2b_customer_view_active_products" ON "public"."products" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_b2b_customer() AND (is_active = true)));

DROP POLICY IF EXISTS "commercial_view_products" ON "public"."products";

CREATE POLICY "commercial_view_products" ON "public"."products" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_sales_rep());

DROP POLICY IF EXISTS "purchase_items_admin_acheteur_manage" ON "public"."purchase_items";

CREATE POLICY "purchase_items_admin_acheteur_manage" ON "public"."purchase_items" AS PERMISSIVE FOR ALL TO "authenticated" USING ((is_admin() OR is_acheteur())) WITH CHECK ((is_admin() OR is_acheteur()));

DROP POLICY IF EXISTS "purchase_items_procurement_read" ON "public"."purchase_items";

CREATE POLICY "purchase_items_procurement_read" ON "public"."purchase_items" AS PERMISSIVE FOR SELECT TO "authenticated" USING (can_read_procurement());

DROP POLICY IF EXISTS "purchases_admin_acheteur_manage" ON "public"."purchases";

CREATE POLICY "purchases_admin_acheteur_manage" ON "public"."purchases" AS PERMISSIVE FOR ALL TO "authenticated" USING ((is_admin() OR is_acheteur())) WITH CHECK ((is_admin() OR is_acheteur()));

DROP POLICY IF EXISTS "purchases_procurement_read" ON "public"."purchases";

CREATE POLICY "purchases_procurement_read" ON "public"."purchases" AS PERMISSIVE FOR SELECT TO "authenticated" USING (can_read_procurement());

DROP POLICY IF EXISTS "admin_full_access_rule_actions" ON "public"."rule_actions";

CREATE POLICY "admin_full_access_rule_actions" ON "public"."rule_actions" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "admin_full_access_rule_conditions" ON "public"."rule_conditions";

CREATE POLICY "admin_full_access_rule_conditions" ON "public"."rule_conditions" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "admin_view_execution_history" ON "public"."rule_execution_history";

CREATE POLICY "admin_view_execution_history" ON "public"."rule_execution_history" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin());

DROP POLICY IF EXISTS "admin_full_access_orders" ON "public"."sales_orders";

CREATE POLICY "admin_full_access_orders" ON "public"."sales_orders" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "client_insert_own_orders" ON "public"."sales_orders";

CREATE POLICY "client_insert_own_orders" ON "public"."sales_orders" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((is_b2b_customer() AND (customer_id IN ( SELECT customers.id
   FROM customers
  WHERE (customers.user_id = auth.uid())))));

DROP POLICY IF EXISTS "client_view_own_orders" ON "public"."sales_orders";

CREATE POLICY "client_view_own_orders" ON "public"."sales_orders" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_b2b_customer() AND (customer_id IN ( SELECT customers.id
   FROM customers
  WHERE (customers.user_id = auth.uid())))));

DROP POLICY IF EXISTS "commercial_insert_orders" ON "public"."sales_orders";

CREATE POLICY "commercial_insert_orders" ON "public"."sales_orders" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((is_sales_rep() AND (customer_id IN ( SELECT customers.id
   FROM customers
  WHERE (customers.commercial_id = auth.uid())))));

DROP POLICY IF EXISTS "commercial_view_assigned_customer_orders" ON "public"."sales_orders";

CREATE POLICY "commercial_view_assigned_customer_orders" ON "public"."sales_orders" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_sales_rep() AND (customer_id IN ( SELECT customers.id
   FROM customers
  WHERE (customers.commercial_id = auth.uid())))));

DROP POLICY IF EXISTS "comptable_read_all_orders" ON "public"."sales_orders";

CREATE POLICY "comptable_read_all_orders" ON "public"."sales_orders" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_comptable());

DROP POLICY IF EXISTS "admin_view_all_screen_views" ON "public"."screen_views";

CREATE POLICY "admin_view_all_screen_views" ON "public"."screen_views" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin_from_auth());

DROP POLICY IF EXISTS "users_manage_own_screen_views" ON "public"."screen_views";

CREATE POLICY "users_manage_own_screen_views" ON "public"."screen_views" AS PERMISSIVE FOR ALL TO "authenticated" USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_manage_anomalies" ON "public"."security_anomalies";

CREATE POLICY "admin_manage_anomalies" ON "public"."security_anomalies" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "admin_view_all_anomalies" ON "public"."security_anomalies";

CREATE POLICY "admin_view_all_anomalies" ON "public"."security_anomalies" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin());

DROP POLICY IF EXISTS "users_view_own_anomalies" ON "public"."security_anomalies";

CREATE POLICY "users_view_own_anomalies" ON "public"."security_anomalies" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_full_access_security_thresholds" ON "public"."security_thresholds";

CREATE POLICY "admin_full_access_security_thresholds" ON "public"."security_thresholds" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "acheteur_read_stock_movements" ON "public"."stock_movements";

CREATE POLICY "acheteur_read_stock_movements" ON "public"."stock_movements" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_acheteur());

DROP POLICY IF EXISTS "acheteur_stock_entries" ON "public"."stock_movements";

CREATE POLICY "acheteur_stock_entries" ON "public"."stock_movements" AS PERMISSIVE FOR INSERT TO "authenticated" WITH CHECK ((is_acheteur() AND (movement_type = ANY (ARRAY['in'::stock_movement_type, 'return'::stock_movement_type]))));

DROP POLICY IF EXISTS "admin_full_access_movements" ON "public"."stock_movements";

CREATE POLICY "admin_full_access_movements" ON "public"."stock_movements" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "depot_manage_movements" ON "public"."stock_movements";

CREATE POLICY "depot_manage_movements" ON "public"."stock_movements" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_warehouse_staff()) WITH CHECK (is_warehouse_staff());

DROP POLICY IF EXISTS "suppliers_admin_acheteur_manage" ON "public"."suppliers";

CREATE POLICY "suppliers_admin_acheteur_manage" ON "public"."suppliers" AS PERMISSIVE FOR ALL TO "authenticated" USING ((is_admin() OR is_acheteur())) WITH CHECK ((is_admin() OR is_acheteur()));

DROP POLICY IF EXISTS "suppliers_procurement_read" ON "public"."suppliers";

CREATE POLICY "suppliers_procurement_read" ON "public"."suppliers" AS PERMISSIVE FOR SELECT TO "authenticated" USING (can_read_procurement());

DROP POLICY IF EXISTS "support_tickets_admin_manage" ON "public"."support_tickets";

CREATE POLICY "support_tickets_admin_manage" ON "public"."support_tickets" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "support_tickets_sales_rep_view_assigned_customer" ON "public"."support_tickets";

CREATE POLICY "support_tickets_sales_rep_view_assigned_customer" ON "public"."support_tickets" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((is_sales_rep() AND (customer_id IN ( SELECT customers.id
   FROM customers
  WHERE (customers.commercial_id = auth.uid())))));

DROP POLICY IF EXISTS "support_tickets_user_manage_own" ON "public"."support_tickets";

CREATE POLICY "support_tickets_user_manage_own" ON "public"."support_tickets" AS PERMISSIVE FOR ALL TO "authenticated" USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_manage_system_config" ON "public"."system_configuration";

CREATE POLICY "admin_manage_system_config" ON "public"."system_configuration" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_system_admin()) WITH CHECK (is_system_admin());

DROP POLICY IF EXISTS "admin_full_access_blocking_records" ON "public"."user_blocking_records";

CREATE POLICY "admin_full_access_blocking_records" ON "public"."user_blocking_records" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "users_view_own_blocking_records" ON "public"."user_blocking_records";

CREATE POLICY "users_view_own_blocking_records" ON "public"."user_blocking_records" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_manage_all_permissions" ON "public"."user_permissions";

CREATE POLICY "admin_manage_all_permissions" ON "public"."user_permissions" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_system_admin()) WITH CHECK (is_system_admin());

DROP POLICY IF EXISTS "users_view_own_permissions" ON "public"."user_permissions";

CREATE POLICY "users_view_own_permissions" ON "public"."user_permissions" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_manage_all_profiles" ON "public"."user_profiles";

CREATE POLICY "admin_manage_all_profiles" ON "public"."user_profiles" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "users_update_own_profile" ON "public"."user_profiles";

CREATE POLICY "users_update_own_profile" ON "public"."user_profiles" AS PERMISSIVE FOR UPDATE TO "authenticated" USING ((id = auth.uid())) WITH CHECK ((id = auth.uid()));

DROP POLICY IF EXISTS "users_view_own_profile" ON "public"."user_profiles";

CREATE POLICY "users_view_own_profile" ON "public"."user_profiles" AS PERMISSIVE FOR SELECT TO "authenticated" USING (((id = auth.uid()) OR is_admin()));

DROP POLICY IF EXISTS "admin_manage_risk_scores" ON "public"."user_risk_scores";

CREATE POLICY "admin_manage_risk_scores" ON "public"."user_risk_scores" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "admin_view_all_risk_scores" ON "public"."user_risk_scores";

CREATE POLICY "admin_view_all_risk_scores" ON "public"."user_risk_scores" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin());

DROP POLICY IF EXISTS "users_view_own_risk_score" ON "public"."user_risk_scores";

CREATE POLICY "users_view_own_risk_score" ON "public"."user_risk_scores" AS PERMISSIVE FOR SELECT TO "authenticated" USING ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_view_all_sessions" ON "public"."user_sessions";

CREATE POLICY "admin_view_all_sessions" ON "public"."user_sessions" AS PERMISSIVE FOR SELECT TO "authenticated" USING (is_admin_from_auth());

DROP POLICY IF EXISTS "users_manage_own_sessions" ON "public"."user_sessions";

CREATE POLICY "users_manage_own_sessions" ON "public"."user_sessions" AS PERMISSIVE FOR ALL TO "authenticated" USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));

DROP POLICY IF EXISTS "admin_manage_warehouses" ON "public"."warehouse_locations";

CREATE POLICY "admin_manage_warehouses" ON "public"."warehouse_locations" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "all_users_view_warehouses" ON "public"."warehouse_locations";

CREATE POLICY "all_users_view_warehouses" ON "public"."warehouse_locations" AS PERMISSIVE FOR SELECT TO "authenticated" USING (true);

DROP POLICY IF EXISTS "admin_manage_workflow_states" ON "public"."workflow_states";

CREATE POLICY "admin_manage_workflow_states" ON "public"."workflow_states" AS PERMISSIVE FOR ALL TO "authenticated" USING (is_system_admin()) WITH CHECK (is_system_admin());

DROP POLICY IF EXISTS "admin_access_all_documents" ON "storage"."objects";

CREATE POLICY "admin_access_all_documents" ON "storage"."objects" AS PERMISSIVE FOR ALL TO "authenticated" USING (((bucket_id = 'erp-documents'::text) AND is_admin())) WITH CHECK (((bucket_id = 'erp-documents'::text) AND is_admin()));

DROP POLICY IF EXISTS "users_manage_own_documents" ON "storage"."objects";

CREATE POLICY "users_manage_own_documents" ON "storage"."objects" AS PERMISSIVE FOR ALL TO "authenticated" USING (((bucket_id = 'erp-documents'::text) AND (owner = auth.uid()))) WITH CHECK (((bucket_id = 'erp-documents'::text) AND (owner = auth.uid())));

DROP TRIGGER IF EXISTS "on_auth_user_created" ON "auth"."users";

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION handle_new_user();

DROP TRIGGER IF EXISTS "set_updated_at_automation_rules" ON "public"."automation_rules";

CREATE TRIGGER set_updated_at_automation_rules BEFORE UPDATE ON public.automation_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_bank_accounts" ON "public"."bank_accounts";

CREATE TRIGGER set_updated_at_bank_accounts BEFORE UPDATE ON public.bank_accounts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_cash_registers" ON "public"."cash_registers";

CREATE TRIGGER set_updated_at_cash_registers BEFORE UPDATE ON public.cash_registers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "audit_customers" ON "public"."customers";

CREATE TRIGGER audit_customers AFTER INSERT OR DELETE OR UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

ALTER TABLE "public"."customers" DISABLE TRIGGER "audit_customers";

DROP TRIGGER IF EXISTS "set_updated_at_customers" ON "public"."customers";

CREATE TRIGGER set_updated_at_customers BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_deliveries" ON "public"."deliveries";

CREATE TRIGGER set_updated_at_deliveries BEFORE UPDATE ON public.deliveries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "trigger_notify_delivery" ON "public"."deliveries";

CREATE TRIGGER trigger_notify_delivery AFTER UPDATE ON public.deliveries FOR EACH ROW WHEN ((new.status = 'delivered'::delivery_status)) EXECUTE FUNCTION notify_order_delivered();

DROP TRIGGER IF EXISTS "set_updated_at_delivery_routes" ON "public"."delivery_routes";

CREATE TRIGGER set_updated_at_delivery_routes BEFORE UPDATE ON public.delivery_routes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_escalation_configurations" ON "public"."escalation_configurations";

CREATE TRIGGER set_updated_at_escalation_configurations BEFORE UPDATE ON public.escalation_configurations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_expenses" ON "public"."expenses";

CREATE TRIGGER set_updated_at_expenses BEFORE UPDATE ON public.expenses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_feature_usage_stats" ON "public"."feature_usage_stats";

CREATE TRIGGER set_updated_at_feature_usage_stats BEFORE UPDATE ON public.feature_usage_stats FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_forensic_templates" ON "public"."forensic_export_templates";

CREATE TRIGGER set_updated_at_forensic_templates BEFORE UPDATE ON public.forensic_export_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_forensic_reports" ON "public"."forensic_investigation_reports";

CREATE TRIGGER set_updated_at_forensic_reports BEFORE UPDATE ON public.forensic_investigation_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_inventory_stock" ON "public"."inventory_stock";

CREATE TRIGGER set_updated_at_inventory_stock BEFORE UPDATE ON public.inventory_stock FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "log_evidence_timeline" ON "public"."investigation_evidence";

CREATE TRIGGER log_evidence_timeline AFTER INSERT OR UPDATE ON public.investigation_evidence FOR EACH ROW EXECUTE FUNCTION log_investigation_timeline();

DROP TRIGGER IF EXISTS "set_updated_at_investigation_messages" ON "public"."investigation_messages";

CREATE TRIGGER set_updated_at_investigation_messages BEFORE UPDATE ON public.investigation_messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "log_task_timeline" ON "public"."investigation_tasks";

CREATE TRIGGER log_task_timeline AFTER INSERT OR UPDATE ON public.investigation_tasks FOR EACH ROW EXECUTE FUNCTION log_investigation_timeline();

DROP TRIGGER IF EXISTS "log_team_timeline" ON "public"."investigation_team_members";

CREATE TRIGGER log_team_timeline AFTER INSERT OR UPDATE ON public.investigation_team_members FOR EACH ROW EXECUTE FUNCTION log_investigation_timeline();

DROP TRIGGER IF EXISTS "audit_invoices" ON "public"."invoices";

CREATE TRIGGER audit_invoices AFTER INSERT OR DELETE OR UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

DROP TRIGGER IF EXISTS "trigger_set_invoice_number" ON "public"."invoices";

CREATE TRIGGER trigger_set_invoice_number BEFORE INSERT ON public.invoices FOR EACH ROW EXECUTE FUNCTION set_invoice_number();

DROP TRIGGER IF EXISTS "trigger_invoke_send_email_notification" ON "public"."notification_queue";

CREATE TRIGGER trigger_invoke_send_email_notification AFTER INSERT ON public.notification_queue FOR EACH ROW EXECUTE FUNCTION invoke_send_email_notification();

DROP TRIGGER IF EXISTS "set_updated_at_notification_templates" ON "public"."notification_templates";

CREATE TRIGGER set_updated_at_notification_templates BEFORE UPDATE ON public.notification_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "trigger_recalculate_sales_order_totals" ON "public"."order_items";

CREATE TRIGGER trigger_recalculate_sales_order_totals AFTER INSERT OR DELETE OR UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION recalculate_sales_order_totals();

DROP TRIGGER IF EXISTS "trigger_set_order_item_line_total" ON "public"."order_items";

CREATE TRIGGER trigger_set_order_item_line_total BEFORE INSERT OR UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION set_order_item_line_total();

DROP TRIGGER IF EXISTS "audit_payments" ON "public"."payments";

CREATE TRIGGER audit_payments AFTER INSERT OR DELETE OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

DROP TRIGGER IF EXISTS "trigger_notify_payment" ON "public"."payments";

CREATE TRIGGER trigger_notify_payment AFTER INSERT ON public.payments FOR EACH ROW EXECUTE FUNCTION notify_payment_received();

DROP TRIGGER IF EXISTS "audit_products" ON "public"."products";

CREATE TRIGGER audit_products AFTER INSERT OR DELETE OR UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

DROP TRIGGER IF EXISTS "set_updated_at_products" ON "public"."products";

CREATE TRIGGER set_updated_at_products BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_purchases" ON "public"."purchases";

CREATE TRIGGER set_updated_at_purchases BEFORE UPDATE ON public.purchases FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "trigger_set_purchase_number" ON "public"."purchases";

CREATE TRIGGER trigger_set_purchase_number BEFORE INSERT ON public.purchases FOR EACH ROW EXECUTE FUNCTION set_purchase_number();

DROP TRIGGER IF EXISTS "audit_sales_orders" ON "public"."sales_orders";

CREATE TRIGGER audit_sales_orders AFTER INSERT OR DELETE OR UPDATE ON public.sales_orders FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

DROP TRIGGER IF EXISTS "set_updated_at_sales_orders" ON "public"."sales_orders";

CREATE TRIGGER set_updated_at_sales_orders BEFORE UPDATE ON public.sales_orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "trigger_notify_new_order" ON "public"."sales_orders";

CREATE TRIGGER trigger_notify_new_order AFTER INSERT ON public.sales_orders FOR EACH ROW EXECUTE FUNCTION notify_new_order();

DROP TRIGGER IF EXISTS "trigger_set_sales_order_number" ON "public"."sales_orders";

CREATE TRIGGER trigger_set_sales_order_number BEFORE INSERT ON public.sales_orders FOR EACH ROW EXECUTE FUNCTION set_sales_order_number();

DROP TRIGGER IF EXISTS "trigger_track_screen_navigation" ON "public"."screen_views";

CREATE TRIGGER trigger_track_screen_navigation BEFORE INSERT ON public.screen_views FOR EACH ROW EXECUTE FUNCTION track_screen_navigation();

DROP TRIGGER IF EXISTS "set_updated_at_security_thresholds" ON "public"."security_thresholds";

CREATE TRIGGER set_updated_at_security_thresholds BEFORE UPDATE ON public.security_thresholds FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "trigger_sync_inventory_stock_from_movements" ON "public"."stock_movements";

CREATE TRIGGER trigger_sync_inventory_stock_from_movements AFTER INSERT OR DELETE OR UPDATE ON public.stock_movements FOR EACH ROW EXECUTE FUNCTION sync_inventory_stock_from_movements();

DROP TRIGGER IF EXISTS "set_updated_at_suppliers" ON "public"."suppliers";

CREATE TRIGGER set_updated_at_suppliers BEFORE UPDATE ON public.suppliers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_support_tickets" ON "public"."support_tickets";

CREATE TRIGGER set_updated_at_support_tickets BEFORE UPDATE ON public.support_tickets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_system_configuration" ON "public"."system_configuration";

CREATE TRIGGER set_updated_at_system_configuration BEFORE UPDATE ON public.system_configuration FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_user_permissions" ON "public"."user_permissions";

CREATE TRIGGER set_updated_at_user_permissions BEFORE UPDATE ON public.user_permissions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "set_updated_at_user_profiles" ON "public"."user_profiles";

CREATE TRIGGER set_updated_at_user_profiles BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "trigger_prevent_profile_privilege_escalation" ON "public"."user_profiles";

CREATE TRIGGER trigger_prevent_profile_privilege_escalation BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION prevent_profile_privilege_escalation();

DROP TRIGGER IF EXISTS "set_updated_at_user_risk_scores" ON "public"."user_risk_scores";

CREATE TRIGGER set_updated_at_user_risk_scores BEFORE UPDATE ON public.user_risk_scores FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS "trigger_update_session_duration" ON "public"."user_sessions";

CREATE TRIGGER trigger_update_session_duration BEFORE UPDATE ON public.user_sessions FOR EACH ROW EXECUTE FUNCTION update_session_duration();

ALTER TABLE public."accounting_entries" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."accounting_entries" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."ai_insights" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."ai_insights" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."anomaly_correlation_patterns" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."anomaly_correlation_patterns" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."audit_logs" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."audit_logs" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."automation_rules" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."automation_rules" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."bank_accounts" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."bank_accounts" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."bank_transactions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."bank_transactions" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."barcode_scans" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."barcode_scans" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."cash_movements" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."cash_movements" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."cash_registers" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."cash_registers" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."customers" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."customers" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."deliveries" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."deliveries" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."delivery_routes" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."delivery_routes" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."device_fingerprints" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."device_fingerprints" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."document_attachments" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."document_attachments" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."escalation_configurations" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."escalation_configurations" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."escalation_history" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."escalation_history" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."exchange_rates" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."exchange_rates" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."expense_approval_history" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."expense_approval_history" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."expenses" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."expenses" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."failed_login_attempts" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."failed_login_attempts" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."feature_usage_stats" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."feature_usage_stats" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."forensic_event_timeline" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."forensic_event_timeline" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."forensic_export_history" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."forensic_export_history" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."forensic_export_templates" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."forensic_export_templates" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."forensic_investigation_reports" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."forensic_investigation_reports" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."inventory_stock" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."inventory_stock" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."investigation_evidence" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."investigation_evidence" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."investigation_messages" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."investigation_messages" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."investigation_tasks" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."investigation_tasks" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."investigation_team_members" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."investigation_team_members" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."investigation_timeline" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."investigation_timeline" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."invoices" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."invoices" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."ip_geolocation_cache" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."ip_geolocation_cache" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."migration_repair_audit" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."migration_repair_audit" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."notification_queue" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."notification_queue" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."notification_templates" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."notification_templates" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."order_items" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."order_items" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."payments" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."payments" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."product_categories" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."product_categories" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."products" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."products" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."purchase_items" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."purchase_items" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."purchases" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."purchases" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."rule_actions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."rule_actions" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."rule_conditions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."rule_conditions" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."rule_execution_history" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."rule_execution_history" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."sales_orders" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."sales_orders" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."screen_views" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."screen_views" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."security_anomalies" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."security_anomalies" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."security_thresholds" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."security_thresholds" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."stock_movements" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."stock_movements" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."suppliers" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."suppliers" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."support_tickets" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."support_tickets" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."system_configuration" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."system_configuration" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."user_blocking_records" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."user_blocking_records" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."user_permissions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."user_permissions" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."user_profiles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."user_profiles" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."user_risk_scores" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."user_risk_scores" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."user_sessions" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."user_sessions" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."warehouse_locations" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."warehouse_locations" NO FORCE ROW LEVEL SECURITY;

ALTER TABLE public."workflow_states" ENABLE ROW LEVEL SECURITY;

ALTER TABLE public."workflow_states" NO FORCE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public."accounting_entries" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."accounting_entries" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."accounting_entries" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."accounting_entries" TO "service_role";

REVOKE ALL ON TABLE public."ai_insights" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ai_insights" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ai_insights" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ai_insights" TO "service_role";

REVOKE ALL ON TABLE public."anomaly_correlation_patterns" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."anomaly_correlation_patterns" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."anomaly_correlation_patterns" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."anomaly_correlation_patterns" TO "service_role";

REVOKE ALL ON TABLE public."audit_logs" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."audit_logs" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."audit_logs" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."audit_logs" TO "service_role";

REVOKE ALL ON TABLE public."automation_rules" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."automation_rules" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."automation_rules" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."automation_rules" TO "service_role";

REVOKE ALL ON TABLE public."bank_accounts" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."bank_accounts" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."bank_accounts" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."bank_accounts" TO "service_role";

REVOKE ALL ON TABLE public."bank_transactions" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."bank_transactions" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."bank_transactions" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."bank_transactions" TO "service_role";

REVOKE ALL ON TABLE public."barcode_scans" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."barcode_scans" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."barcode_scans" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."barcode_scans" TO "service_role";

REVOKE ALL ON TABLE public."cash_movements" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."cash_movements" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."cash_movements" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."cash_movements" TO "service_role";

REVOKE ALL ON TABLE public."cash_registers" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."cash_registers" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."cash_registers" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."cash_registers" TO "service_role";

REVOKE ALL ON TABLE public."customers" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."customers" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."customers" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."customers" TO "service_role";

REVOKE ALL ON TABLE public."deliveries" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."deliveries" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."deliveries" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."deliveries" TO "service_role";

REVOKE ALL ON TABLE public."delivery_routes" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."delivery_routes" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."delivery_routes" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."delivery_routes" TO "service_role";

REVOKE ALL ON TABLE public."device_fingerprints" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."device_fingerprints" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."device_fingerprints" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."device_fingerprints" TO "service_role";

REVOKE ALL ON TABLE public."document_attachments" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."document_attachments" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."document_attachments" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."document_attachments" TO "service_role";

REVOKE ALL ON TABLE public."escalation_configurations" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."escalation_configurations" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."escalation_configurations" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."escalation_configurations" TO "service_role";

REVOKE ALL ON TABLE public."escalation_history" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."escalation_history" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."escalation_history" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."escalation_history" TO "service_role";

REVOKE ALL ON TABLE public."exchange_rates" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."exchange_rates" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."exchange_rates" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."exchange_rates" TO "service_role";

REVOKE ALL ON TABLE public."expense_approval_history" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."expense_approval_history" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."expense_approval_history" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."expense_approval_history" TO "service_role";

REVOKE ALL ON TABLE public."expenses" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."expenses" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."expenses" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."expenses" TO "service_role";

REVOKE ALL ON TABLE public."failed_login_attempts" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."failed_login_attempts" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."failed_login_attempts" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."failed_login_attempts" TO "service_role";

REVOKE ALL ON TABLE public."feature_usage_stats" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."feature_usage_stats" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."feature_usage_stats" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."feature_usage_stats" TO "service_role";

REVOKE ALL ON TABLE public."forensic_event_timeline" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_event_timeline" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_event_timeline" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_event_timeline" TO "service_role";

REVOKE ALL ON TABLE public."forensic_export_history" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_export_history" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_export_history" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_export_history" TO "service_role";

REVOKE ALL ON TABLE public."forensic_export_templates" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_export_templates" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_export_templates" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_export_templates" TO "service_role";

REVOKE ALL ON TABLE public."forensic_investigation_reports" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_investigation_reports" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_investigation_reports" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."forensic_investigation_reports" TO "service_role";

REVOKE ALL ON TABLE public."inventory_stock" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."inventory_stock" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."inventory_stock" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."inventory_stock" TO "service_role";

REVOKE ALL ON TABLE public."investigation_evidence" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_evidence" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_evidence" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_evidence" TO "service_role";

REVOKE ALL ON TABLE public."investigation_messages" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_messages" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_messages" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_messages" TO "service_role";

REVOKE ALL ON TABLE public."investigation_tasks" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_tasks" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_tasks" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_tasks" TO "service_role";

REVOKE ALL ON TABLE public."investigation_team_members" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_team_members" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_team_members" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_team_members" TO "service_role";

REVOKE ALL ON TABLE public."investigation_timeline" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_timeline" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_timeline" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."investigation_timeline" TO "service_role";

REVOKE ALL ON SEQUENCE public."invoice_number_seq" FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT, UPDATE, USAGE ON SEQUENCE public."invoice_number_seq" TO "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE public."invoice_number_seq" TO "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE public."invoice_number_seq" TO "service_role";

REVOKE ALL ON TABLE public."invoices" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."invoices" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."invoices" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."invoices" TO "service_role";

REVOKE ALL ON TABLE public."ip_geolocation_cache" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ip_geolocation_cache" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ip_geolocation_cache" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."ip_geolocation_cache" TO "service_role";

REVOKE ALL ON TABLE public."migration_repair_audit" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."migration_repair_audit" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."migration_repair_audit" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."migration_repair_audit" TO "service_role";

REVOKE ALL ON TABLE public."notification_queue" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."notification_queue" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."notification_queue" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."notification_queue" TO "service_role";

REVOKE ALL ON TABLE public."notification_templates" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."notification_templates" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."notification_templates" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."notification_templates" TO "service_role";

REVOKE ALL ON TABLE public."order_items" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."order_items" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."order_items" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."order_items" TO "service_role";

REVOKE ALL ON SEQUENCE public."order_number_seq" FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT, UPDATE, USAGE ON SEQUENCE public."order_number_seq" TO "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE public."order_number_seq" TO "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE public."order_number_seq" TO "service_role";

REVOKE ALL ON TABLE public."payments" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."payments" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."payments" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."payments" TO "service_role";

REVOKE ALL ON TABLE public."product_categories" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."product_categories" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."product_categories" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."product_categories" TO "service_role";

REVOKE ALL ON TABLE public."products" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."products" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."products" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."products" TO "service_role";

REVOKE ALL ON TABLE public."purchase_items" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."purchase_items" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."purchase_items" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."purchase_items" TO "service_role";

REVOKE ALL ON SEQUENCE public."purchase_number_seq" FROM PUBLIC, anon, authenticated, service_role;

GRANT SELECT, UPDATE, USAGE ON SEQUENCE public."purchase_number_seq" TO "anon";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE public."purchase_number_seq" TO "authenticated";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE public."purchase_number_seq" TO "service_role";

REVOKE ALL ON TABLE public."purchases" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."purchases" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."purchases" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."purchases" TO "service_role";

REVOKE ALL ON TABLE public."receivables_aging" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."receivables_aging" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."receivables_aging" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."receivables_aging" TO "service_role";

REVOKE ALL ON TABLE public."rule_actions" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rule_actions" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rule_actions" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rule_actions" TO "service_role";

REVOKE ALL ON TABLE public."rule_conditions" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rule_conditions" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rule_conditions" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rule_conditions" TO "service_role";

REVOKE ALL ON TABLE public."rule_execution_history" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rule_execution_history" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rule_execution_history" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."rule_execution_history" TO "service_role";

REVOKE ALL ON TABLE public."sales_orders" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."sales_orders" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."sales_orders" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."sales_orders" TO "service_role";

REVOKE ALL ON TABLE public."screen_views" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."screen_views" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."screen_views" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."screen_views" TO "service_role";

REVOKE ALL ON TABLE public."security_anomalies" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."security_anomalies" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."security_anomalies" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."security_anomalies" TO "service_role";

REVOKE ALL ON TABLE public."security_thresholds" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."security_thresholds" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."security_thresholds" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."security_thresholds" TO "service_role";

REVOKE ALL ON TABLE public."stock_movements" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."stock_movements" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."stock_movements" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."stock_movements" TO "service_role";

REVOKE ALL ON TABLE public."suppliers" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."suppliers" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."suppliers" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."suppliers" TO "service_role";

REVOKE ALL ON TABLE public."support_tickets" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."support_tickets" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."support_tickets" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."support_tickets" TO "service_role";

REVOKE ALL ON TABLE public."system_configuration" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."system_configuration" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."system_configuration" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."system_configuration" TO "service_role";

REVOKE ALL ON TABLE public."user_blocking_records" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_blocking_records" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_blocking_records" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_blocking_records" TO "service_role";

REVOKE ALL ON TABLE public."user_permissions" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_permissions" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_permissions" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_permissions" TO "service_role";

REVOKE ALL ON TABLE public."user_profiles" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_profiles" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_profiles" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_profiles" TO "service_role";

REVOKE ALL ON TABLE public."user_risk_scores" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_risk_scores" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_risk_scores" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_risk_scores" TO "service_role";

REVOKE ALL ON TABLE public."user_sessions" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_sessions" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_sessions" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."user_sessions" TO "service_role";

REVOKE ALL ON TABLE public."warehouse_locations" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."warehouse_locations" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."warehouse_locations" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."warehouse_locations" TO "service_role";

REVOKE ALL ON TABLE public."workflow_states" FROM PUBLIC, anon, authenticated, service_role;

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."workflow_states" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."workflow_states" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE public."workflow_states" TO "service_role";

REVOKE ALL ON FUNCTION public."adjust_stock"(p_product_id uuid, p_warehouse_id uuid, p_adjustment_quantity integer, p_reason text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."adjust_stock"(p_product_id uuid, p_warehouse_id uuid, p_adjustment_quantity integer, p_reason text) TO "service_role";

REVOKE ALL ON FUNCTION public."auto_unblock_expired_users"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."auto_unblock_expired_users"() TO "service_role";

REVOKE ALL ON FUNCTION public."build_forensic_timeline"(user_id_input uuid, start_time_input timestamp with time zone, end_time_input timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."build_forensic_timeline"(user_id_input uuid, start_time_input timestamp with time zone, end_time_input timestamp with time zone) TO "service_role";

REVOKE ALL ON FUNCTION public."calculate_correlation_score"(anomaly_ids_input uuid[]) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."calculate_correlation_score"(anomaly_ids_input uuid[]) TO "service_role";

REVOKE ALL ON FUNCTION public."calculate_user_risk_scores"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."calculate_user_risk_scores"() TO "service_role";

REVOKE ALL ON FUNCTION public."can_read_finance"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."can_read_finance"() TO "service_role";

REVOKE ALL ON FUNCTION public."can_read_procurement"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."can_read_procurement"() TO "service_role";

REVOKE ALL ON FUNCTION public."check_low_stock"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."check_low_stock"() TO "service_role";

REVOKE ALL ON FUNCTION public."check_overdue_invoices"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."check_overdue_invoices"() TO "service_role";

REVOKE ALL ON FUNCTION public."confirm_delivery"(p_delivery_id uuid, p_signature_url text, p_notes text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."confirm_delivery"(p_delivery_id uuid, p_signature_url text, p_notes text) TO "service_role";

REVOKE ALL ON FUNCTION public."convert_to_cdf"(p_amount numeric, p_currency text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."convert_to_cdf"(p_amount numeric, p_currency text) TO "service_role";

REVOKE ALL ON FUNCTION public."create_forensic_export_record"(p_export_name text, p_template_id uuid, p_format export_format, p_filter_start_date timestamp with time zone, p_filter_end_date timestamp with time zone, p_filter_user_ids uuid[], p_filter_anomaly_types text[], p_filter_severity_levels text[]) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."create_forensic_export_record"(p_export_name text, p_template_id uuid, p_format export_format, p_filter_start_date timestamp with time zone, p_filter_end_date timestamp with time zone, p_filter_user_ids uuid[], p_filter_anomaly_types text[], p_filter_severity_levels text[]) TO "service_role";

REVOKE ALL ON FUNCTION public."create_order_with_items"(p_customer_id uuid, p_items jsonb, p_notes text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."create_order_with_items"(p_customer_id uuid, p_items jsonb, p_notes text) TO "service_role";

REVOKE ALL ON FUNCTION public."current_user_role"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."current_user_role"() TO "service_role";

REVOKE ALL ON FUNCTION public."detect_correlation_patterns"(user_id_input uuid, time_window_hours integer) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."detect_correlation_patterns"(user_id_input uuid, time_window_hours integer) TO "service_role";

REVOKE ALL ON FUNCTION public."detect_inventory_anomalies"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."detect_inventory_anomalies"() TO "service_role";

REVOKE ALL ON FUNCTION public."detect_suspicious_transactions"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."detect_suspicious_transactions"() TO "service_role";

REVOKE ALL ON FUNCTION public."detect_unauthorized_access"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."detect_unauthorized_access"() TO "service_role";

REVOKE ALL ON FUNCTION public."edge_function_auth_headers"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."edge_function_auth_headers"() TO "service_role";

REVOKE ALL ON FUNCTION public."evaluate_rule_conditions"(p_rule_id uuid, p_trigger_data jsonb) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."evaluate_rule_conditions"(p_rule_id uuid, p_trigger_data jsonb) TO "service_role";

REVOKE ALL ON FUNCTION public."execute_rule_actions"(p_rule_id uuid, p_trigger_data jsonb, p_affected_user_id uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."execute_rule_actions"(p_rule_id uuid, p_trigger_data jsonb, p_affected_user_id uuid) TO "service_role";

REVOKE ALL ON FUNCTION public."generate_ai_insights"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."generate_ai_insights"() TO "service_role";

REVOKE ALL ON FUNCTION public."generate_device_fingerprint"(user_agent_val text, ip_addr inet) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."generate_device_fingerprint"(user_agent_val text, ip_addr inet) TO "service_role";

REVOKE ALL ON FUNCTION public."generate_forensic_evidence_export"(p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_user_ids uuid[], p_anomaly_types text[], p_severity_levels text[], p_ip_addresses inet[]) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."generate_forensic_evidence_export"(p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_user_ids uuid[], p_anomaly_types text[], p_severity_levels text[], p_ip_addresses inet[]) TO "service_role";

REVOKE ALL ON FUNCTION public."generate_investigation_summary_export"(p_investigation_report_id uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."generate_investigation_summary_export"(p_investigation_report_id uuid) TO "service_role";

REVOKE ALL ON FUNCTION public."generate_invoice_number"(p_date timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."generate_invoice_number"(p_date timestamp with time zone) TO "service_role";

REVOKE ALL ON FUNCTION public."generate_ip_correlation_export"(p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_threat_levels text[]) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."generate_ip_correlation_export"(p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_threat_levels text[]) TO "service_role";

REVOKE ALL ON FUNCTION public."generate_order_number"(p_date timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."generate_order_number"(p_date timestamp with time zone) TO "service_role";

REVOKE ALL ON FUNCTION public."generate_purchase_number"(p_date timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."generate_purchase_number"(p_date timestamp with time zone) TO "service_role";

REVOKE ALL ON FUNCTION public."get_admin_finance_report"(p_start timestamp with time zone, p_end timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."get_admin_finance_report"(p_start timestamp with time zone, p_end timestamp with time zone) TO "service_role";

REVOKE ALL ON FUNCTION public."get_admin_operations_report"(p_start timestamp with time zone, p_end timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."get_admin_operations_report"(p_start timestamp with time zone, p_end timestamp with time zone) TO "service_role";

REVOKE ALL ON FUNCTION public."get_admin_sales_report"(p_start timestamp with time zone, p_end timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."get_admin_sales_report"(p_start timestamp with time zone, p_end timestamp with time zone) TO "service_role";

REVOKE ALL ON FUNCTION public."get_admin_total_report"(p_start timestamp with time zone, p_end timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."get_admin_total_report"(p_start timestamp with time zone, p_end timestamp with time zone) TO "service_role";

REVOKE ALL ON FUNCTION public."get_user_productivity_metrics"(p_user_id uuid, p_start_date timestamp with time zone, p_end_date timestamp with time zone) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."get_user_productivity_metrics"(p_user_id uuid, p_start_date timestamp with time zone, p_end_date timestamp with time zone) TO "service_role";

REVOKE ALL ON FUNCTION public."handle_new_user"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."handle_new_user"() TO "service_role";

REVOKE ALL ON FUNCTION public."has_module_permission"(module text, permission text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."has_module_permission"(module text, permission text) TO "service_role";

REVOKE ALL ON FUNCTION public."invoke_send_email_notification"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."invoke_send_email_notification"() TO "service_role";

REVOKE ALL ON FUNCTION public."is_acheteur"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."is_acheteur"() TO "service_role";

REVOKE ALL ON FUNCTION public."is_admin"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."is_admin"() TO "service_role";

REVOKE ALL ON FUNCTION public."is_admin_from_auth"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."is_admin_from_auth"() TO "service_role";

REVOKE ALL ON FUNCTION public."is_b2b_customer"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."is_b2b_customer"() TO "service_role";

REVOKE ALL ON FUNCTION public."is_comptable"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."is_comptable"() TO "service_role";

REVOKE ALL ON FUNCTION public."is_delivery_agent"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."is_delivery_agent"() TO "service_role";

REVOKE ALL ON FUNCTION public."is_investigation_team_member"(incident_uuid uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."is_investigation_team_member"(incident_uuid uuid) TO "service_role";

REVOKE ALL ON FUNCTION public."is_sales_rep"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."is_sales_rep"() TO "service_role";

REVOKE ALL ON FUNCTION public."is_system_admin"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."is_system_admin"() TO "service_role";

REVOKE ALL ON FUNCTION public."is_warehouse_staff"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."is_warehouse_staff"() TO "service_role";

REVOKE ALL ON FUNCTION public."log_audit_trail"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."log_audit_trail"() TO "service_role";

REVOKE ALL ON FUNCTION public."log_investigation_timeline"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."log_investigation_timeline"() TO "service_role";

REVOKE ALL ON FUNCTION public."notify_new_order"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."notify_new_order"() TO "service_role";

REVOKE ALL ON FUNCTION public."notify_order_delivered"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."notify_order_delivered"() TO "service_role";

REVOKE ALL ON FUNCTION public."notify_payment_received"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."notify_payment_received"() TO "service_role";

REVOKE ALL ON FUNCTION public."parse_user_agent"(user_agent_text text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."parse_user_agent"(user_agent_text text) TO "service_role";

REVOKE ALL ON FUNCTION public."prevent_profile_privilege_escalation"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."prevent_profile_privilege_escalation"() TO "service_role";

REVOKE ALL ON FUNCTION public."process_automation_rules"(p_trigger_type rule_trigger_type, p_trigger_data jsonb, p_affected_user_id uuid) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."process_automation_rules"(p_trigger_type rule_trigger_type, p_trigger_data jsonb, p_affected_user_id uuid) TO "service_role";

REVOKE ALL ON FUNCTION public."recalculate_sales_order_totals"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."recalculate_sales_order_totals"() TO "service_role";

REVOKE ALL ON FUNCTION public."record_payment"(p_invoice_id uuid, p_amount numeric, p_currency text, p_payment_method text, p_reference_number text, p_notes text) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."record_payment"(p_invoice_id uuid, p_amount numeric, p_currency text, p_payment_method text, p_reference_number text, p_notes text) TO "service_role";

REVOKE ALL ON FUNCTION public."set_invoice_number"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."set_invoice_number"() TO "service_role";

REVOKE ALL ON FUNCTION public."set_order_item_line_total"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."set_order_item_line_total"() TO "service_role";

REVOKE ALL ON FUNCTION public."set_purchase_number"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."set_purchase_number"() TO "service_role";

REVOKE ALL ON FUNCTION public."set_sales_order_number"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."set_sales_order_number"() TO "service_role";

REVOKE ALL ON FUNCTION public."sync_inventory_stock_from_movements"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."sync_inventory_stock_from_movements"() TO "service_role";

REVOKE ALL ON FUNCTION public."track_screen_navigation"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."track_screen_navigation"() TO "service_role";

REVOKE ALL ON FUNCTION public."update_feature_usage_stats"(p_user_id uuid, p_feature_name text, p_module_name text, p_action_type text, p_time_seconds integer) FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."update_feature_usage_stats"(p_user_id uuid, p_feature_name text, p_module_name text, p_action_type text, p_time_seconds integer) TO "service_role";

REVOKE ALL ON FUNCTION public."update_session_duration"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."update_session_duration"() TO "service_role";

REVOKE ALL ON FUNCTION public."update_updated_at_column"() FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE ON FUNCTION public."update_updated_at_column"() TO "service_role";

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('erp-documents', 'erp-documents', false, 10485760, ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit, allowed_mime_types = EXCLUDED.allowed_mime_types;

COMMIT;
