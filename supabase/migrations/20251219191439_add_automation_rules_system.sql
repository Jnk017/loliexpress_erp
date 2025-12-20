-- Location: supabase/migrations/20251219191439_add_automation_rules_system.sql
-- Schema Analysis: Existing security monitoring system with anomalies, thresholds, failed_login_attempts
-- Integration Type: NEW_MODULE - Adding automation rules engine
-- Dependencies: security_anomalies, user_profiles, notification_queue

-- ===========================
-- 1. CUSTOM TYPES (ENUMs)
-- ===========================

CREATE TYPE public.rule_trigger_type AS ENUM (
    'anomaly_detected',
    'failed_login_threshold',
    'risk_score_exceeded',
    'repeated_violation',
    'time_based'
);

CREATE TYPE public.rule_action_type AS ENUM (
    'send_notification',
    'block_user_temporary',
    'block_user_permanent',
    'suspend_user',
    'escalate_to_admin',
    'escalate_to_support',
    'generate_report',
    'lock_module',
    'enable_detailed_logging'
);

CREATE TYPE public.blocking_reason_type AS ENUM (
    'failed_login_attempts',
    'suspicious_transactions',
    'unauthorized_access',
    'repeated_violations',
    'manual_block',
    'automated_rule'
);

CREATE TYPE public.blocking_status AS ENUM (
    'active',
    'expired',
    'manually_removed'
);

CREATE TYPE public.escalation_level AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);

-- ===========================
-- 2. CORE TABLES
-- ===========================

-- Automation Rules Configuration
CREATE TABLE public.automation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name TEXT NOT NULL,
    description TEXT,
    trigger_type public.rule_trigger_type NOT NULL,
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Rule Conditions (IF part)
CREATE TABLE public.rule_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES public.automation_rules(id) ON DELETE CASCADE,
    condition_field TEXT NOT NULL,
    condition_operator TEXT NOT NULL,
    condition_value TEXT NOT NULL,
    logical_operator TEXT DEFAULT 'AND',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Rule Actions (THEN part)
CREATE TABLE public.rule_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES public.automation_rules(id) ON DELETE CASCADE,
    action_type public.rule_action_type NOT NULL,
    action_parameters JSONB,
    execution_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Rule Execution History
CREATE TABLE public.rule_execution_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES public.automation_rules(id) ON DELETE CASCADE,
    executed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    trigger_data JSONB,
    actions_executed JSONB,
    execution_status TEXT DEFAULT 'success',
    error_message TEXT,
    affected_user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL
);

-- User Blocking Records
CREATE TABLE public.user_blocking_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    blocking_reason public.blocking_reason_type NOT NULL,
    blocking_status public.blocking_status DEFAULT 'active'::public.blocking_status,
    blocked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    unblock_at TIMESTAMPTZ,
    blocked_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    unblocked_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    unblocked_at TIMESTAMPTZ,
    notes TEXT,
    related_rule_id UUID REFERENCES public.automation_rules(id) ON DELETE SET NULL
);

-- Escalation Configurations
CREATE TABLE public.escalation_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    escalation_name TEXT NOT NULL,
    severity_level public.escalation_level NOT NULL,
    escalation_delay_minutes INTEGER DEFAULT 30,
    primary_admin_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    secondary_admin_ids UUID[],
    external_support_email TEXT,
    notification_channels TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Escalation History
CREATE TABLE public.escalation_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    escalation_config_id UUID REFERENCES public.escalation_configurations(id) ON DELETE CASCADE,
    anomaly_id UUID REFERENCES public.security_anomalies(id) ON DELETE CASCADE,
    escalated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    escalated_to UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    response_received_at TIMESTAMPTZ,
    response_action TEXT,
    escalation_level_reached INTEGER DEFAULT 1
);

-- ===========================
-- 3. INDEXES
-- ===========================

CREATE INDEX idx_automation_rules_active ON public.automation_rules(is_active);
CREATE INDEX idx_automation_rules_trigger_type ON public.automation_rules(trigger_type);
CREATE INDEX idx_rule_conditions_rule_id ON public.rule_conditions(rule_id);
CREATE INDEX idx_rule_actions_rule_id ON public.rule_actions(rule_id);
CREATE INDEX idx_rule_execution_history_rule_id ON public.rule_execution_history(rule_id);
CREATE INDEX idx_rule_execution_history_user ON public.rule_execution_history(affected_user_id);
CREATE INDEX idx_user_blocking_records_user_id ON public.user_blocking_records(user_id);
CREATE INDEX idx_user_blocking_records_status ON public.user_blocking_records(blocking_status);
CREATE INDEX idx_escalation_configurations_severity ON public.escalation_configurations(severity_level);
CREATE INDEX idx_escalation_history_anomaly ON public.escalation_history(anomaly_id);

-- ===========================
-- 4. FUNCTIONS
-- ===========================

-- Function to evaluate rule conditions
CREATE OR REPLACE FUNCTION public.evaluate_rule_conditions(
    p_rule_id UUID,
    p_trigger_data JSONB
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- Function to execute rule actions
CREATE OR REPLACE FUNCTION public.execute_rule_actions(
    p_rule_id UUID,
    p_trigger_data JSONB,
    p_affected_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- Function to process automation rules on trigger
CREATE OR REPLACE FUNCTION public.process_automation_rules(
    p_trigger_type public.rule_trigger_type,
    p_trigger_data JSONB,
    p_affected_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- Function to check and auto-unblock users
CREATE OR REPLACE FUNCTION public.auto_unblock_expired_users()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- ===========================
-- 5. RLS POLICIES
-- ===========================

ALTER TABLE public.automation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_execution_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_blocking_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escalation_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escalation_history ENABLE ROW LEVEL SECURITY;

-- Admin full access to all automation tables
CREATE POLICY "admin_full_access_automation_rules"
ON public.automation_rules
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "admin_full_access_rule_conditions"
ON public.rule_conditions
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "admin_full_access_rule_actions"
ON public.rule_actions
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "admin_view_execution_history"
ON public.rule_execution_history
FOR SELECT
TO authenticated
USING (public.is_admin());

CREATE POLICY "admin_full_access_blocking_records"
ON public.user_blocking_records
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "users_view_own_blocking_records"
ON public.user_blocking_records
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "admin_full_access_escalation_config"
ON public.escalation_configurations
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "admin_view_escalation_history"
ON public.escalation_history
FOR SELECT
TO authenticated
USING (public.is_admin());

-- ===========================
-- 6. MOCK DATA
-- ===========================

DO $$
DECLARE
    admin_id UUID;
    rule1_id UUID := gen_random_uuid();
    rule2_id UUID := gen_random_uuid();
    rule3_id UUID := gen_random_uuid();
    escalation_config_id UUID := gen_random_uuid();
BEGIN
    SELECT id INTO admin_id FROM public.user_profiles WHERE role = 'admin' LIMIT 1;
    
    IF admin_id IS NULL THEN
        RAISE NOTICE 'No admin user found. Skipping mock data creation.';
        RETURN;
    END IF;
    
    -- Sample automation rules
    INSERT INTO public.automation_rules (id, rule_name, description, trigger_type, priority, created_by) VALUES
        (rule1_id, 'Critical Anomaly Auto-Escalation', 'Automatically escalate critical severity anomalies to primary admin', 'anomaly_detected', 100, admin_id),
        (rule2_id, 'Failed Login Auto-Block', 'Temporarily block users after 5 failed login attempts', 'failed_login_threshold', 90, admin_id),
        (rule3_id, 'High Risk Score Alert', 'Send email notification when user risk score exceeds 80', 'risk_score_exceeded', 80, admin_id);
    
    -- Conditions for rule 1
    INSERT INTO public.rule_conditions (rule_id, condition_field, condition_operator, condition_value) VALUES
        (rule1_id, 'severity', 'equals', 'critical'),
        (rule1_id, 'category', 'equals', 'transaction');
    
    -- Actions for rule 1
    INSERT INTO public.rule_actions (rule_id, action_type, action_parameters, execution_order) VALUES
        (rule1_id, 'escalate_to_admin', '{"severity": "critical"}'::JSONB, 1),
        (rule1_id, 'send_notification', '{"subject": "Critical Security Alert", "message": "Critical anomaly detected requiring immediate attention", "channel": "email"}'::JSONB, 2);
    
    -- Conditions for rule 2
    INSERT INTO public.rule_conditions (rule_id, condition_field, condition_operator, condition_value) VALUES
        (rule2_id, 'failed_attempts', 'greater_than', '5');
    
    -- Actions for rule 2
    INSERT INTO public.rule_actions (rule_id, action_type, action_parameters, execution_order) VALUES
        (rule2_id, 'block_user_temporary', '{"duration_minutes": "60"}'::JSONB, 1),
        (rule2_id, 'send_notification', '{"subject": "Account Temporarily Blocked", "message": "Your account has been temporarily blocked due to multiple failed login attempts", "channel": "email"}'::JSONB, 2);
    
    -- Conditions for rule 3
    INSERT INTO public.rule_conditions (rule_id, condition_field, condition_operator, condition_value) VALUES
        (rule3_id, 'risk_score', 'greater_than', '80');
    
    -- Actions for rule 3
    INSERT INTO public.rule_actions (rule_id, action_type, action_parameters, execution_order) VALUES
        (rule3_id, 'send_notification', '{"subject": "High Risk Score Detected", "message": "Your account has been flagged with a high risk score. Please review recent activities.", "channel": "email"}'::JSONB, 1),
        (rule3_id, 'enable_detailed_logging', '{}'::JSONB, 2);
    
    -- Sample escalation configuration
    INSERT INTO public.escalation_configurations (
        id, escalation_name, severity_level, escalation_delay_minutes,
        primary_admin_id, notification_channels
    ) VALUES (
        escalation_config_id, 
        'Critical Security Escalation', 
        'critical', 
        0,
        admin_id,
        ARRAY['email', 'push']
    );
    
    RAISE NOTICE 'Automation rules mock data created successfully';
END $$;