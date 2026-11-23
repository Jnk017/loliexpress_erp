-- Location: supabase/migrations/20251219185928_add_security_monitoring_system.sql
-- Schema Analysis: Existing audit_logs, user_sessions, transactions, inventory tracking
-- Integration Type: Additive - Security monitoring extension
-- Dependencies: audit_logs, user_sessions, sales_orders, payments, stock_movements, user_profiles

-- ============================================================================
-- STEP 1: CUSTOM TYPES
-- ============================================================================

CREATE TYPE public.anomaly_severity AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE public.anomaly_category AS ENUM ('transaction', 'access', 'inventory', 'permission', 'system');
CREATE TYPE public.alert_status AS ENUM ('pending', 'reviewing', 'resolved', 'false_positive');

-- ============================================================================
-- STEP 2: CORE TABLES
-- ============================================================================

-- Security thresholds configuration table
CREATE TABLE public.security_thresholds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    threshold_name TEXT NOT NULL,
    category public.anomaly_category NOT NULL,
    threshold_value NUMERIC NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Security anomalies and alerts table
CREATE TABLE public.security_anomalies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    category public.anomaly_category NOT NULL,
    severity public.anomaly_severity NOT NULL,
    alert_status public.alert_status DEFAULT 'pending'::public.alert_status,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    metadata JSONB,
    risk_score NUMERIC DEFAULT 0,
    detected_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- User risk scoring table
CREATE TABLE public.user_risk_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    overall_score NUMERIC DEFAULT 0,
    transaction_score NUMERIC DEFAULT 0,
    access_score NUMERIC DEFAULT 0,
    inventory_score NUMERIC DEFAULT 0,
    last_calculated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Failed login attempts tracking
CREATE TABLE public.failed_login_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    ip_address INET,
    user_agent TEXT,
    attempt_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    failure_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 3: INDEXES
-- ============================================================================

CREATE INDEX idx_security_anomalies_user_id ON public.security_anomalies(user_id);
CREATE INDEX idx_security_anomalies_category ON public.security_anomalies(category);
CREATE INDEX idx_security_anomalies_severity ON public.security_anomalies(severity);
CREATE INDEX idx_security_anomalies_status ON public.security_anomalies(alert_status);
CREATE INDEX idx_security_anomalies_detected_at ON public.security_anomalies(detected_at);
CREATE INDEX idx_user_risk_scores_user_id ON public.user_risk_scores(user_id);
CREATE INDEX idx_failed_login_attempts_email ON public.failed_login_attempts(email);
CREATE INDEX idx_failed_login_attempts_ip ON public.failed_login_attempts(ip_address);
CREATE INDEX idx_failed_login_attempts_time ON public.failed_login_attempts(attempt_time);
CREATE INDEX idx_security_thresholds_category ON public.security_thresholds(category);

-- ============================================================================
-- STEP 4: DETECTION FUNCTIONS (MUST BE BEFORE RLS POLICIES)
-- ============================================================================

-- Function to detect suspicious transaction patterns
CREATE OR REPLACE FUNCTION public.detect_suspicious_transactions()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- Function to detect unauthorized access attempts
CREATE OR REPLACE FUNCTION public.detect_unauthorized_access()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- Function to detect inventory discrepancies
CREATE OR REPLACE FUNCTION public.detect_inventory_anomalies()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- Function to calculate user risk scores
CREATE OR REPLACE FUNCTION public.calculate_user_risk_scores()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- ============================================================================
-- STEP 5: ENABLE RLS
-- ============================================================================

ALTER TABLE public.security_thresholds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_risk_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.failed_login_attempts ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 6: RLS POLICIES
-- ============================================================================

-- Security thresholds - Admin only
CREATE POLICY "admin_full_access_security_thresholds"
ON public.security_thresholds
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Security anomalies - Admins see all, users see their own
CREATE POLICY "admin_view_all_anomalies"
ON public.security_anomalies
FOR SELECT
TO authenticated
USING (public.is_admin());

CREATE POLICY "users_view_own_anomalies"
ON public.security_anomalies
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "admin_manage_anomalies"
ON public.security_anomalies
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- User risk scores - Admins see all, users see their own
CREATE POLICY "admin_view_all_risk_scores"
ON public.user_risk_scores
FOR SELECT
TO authenticated
USING (public.is_admin());

CREATE POLICY "users_view_own_risk_score"
ON public.user_risk_scores
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "admin_manage_risk_scores"
ON public.user_risk_scores
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Failed login attempts - Admin only
CREATE POLICY "admin_view_failed_logins"
ON public.failed_login_attempts
FOR SELECT
TO authenticated
USING (public.is_admin());

-- ============================================================================
-- STEP 7: MOCK DATA
-- ============================================================================

DO $$
DECLARE
    v_admin_id UUID;
    v_sales_rep_id UUID;
BEGIN
    -- Get existing user IDs
    SELECT id INTO v_admin_id FROM public.user_profiles WHERE role = 'admin' LIMIT 1;
    SELECT id INTO v_sales_rep_id FROM public.user_profiles WHERE role = 'sales_rep' LIMIT 1;
    
    -- Insert security thresholds
    INSERT INTO public.security_thresholds (threshold_name, category, threshold_value, description) VALUES
        ('high_amount_threshold', 'transaction', 10000, 'Transaction amount threshold for high-value alerts'),
        ('failed_login_threshold', 'access', 5, 'Number of failed login attempts before alert'),
        ('variance_threshold', 'inventory', 20, 'Percentage variance threshold for inventory adjustments'),
        ('after_hours_enabled', 'transaction', 1, 'Enable after-hours transaction monitoring');
    
    -- Insert sample security anomalies
    IF v_sales_rep_id IS NOT NULL THEN
        INSERT INTO public.security_anomalies (
            user_id, category, severity, title, description, risk_score, alert_status, metadata
        ) VALUES
            (v_sales_rep_id, 'transaction', 'medium', 'After-Hours Transaction', 
             'Transaction processed at 10:30 PM', 50, 'pending',
             '{"order_number": "SO-2024-456", "time": "22:30:00"}'::jsonb),
            (v_sales_rep_id, 'access', 'low', 'New Device Login', 
             'Login from previously unseen device', 30, 'resolved',
             '{"device": "iPhone 14", "location": "Paris"}'::jsonb);
    END IF;
    
    -- Insert sample failed login attempts
    INSERT INTO public.failed_login_attempts (email, ip_address, failure_reason) VALUES
        ('test@example.com', '192.168.1.100', 'Invalid password'),
        ('test@example.com', '192.168.1.100', 'Invalid password'),
        ('admin@loliexpress.com', '10.0.0.50', 'Account locked');
    
    -- Insert sample risk scores
    IF v_sales_rep_id IS NOT NULL THEN
        INSERT INTO public.user_risk_scores (
            user_id, overall_score, transaction_score, access_score, inventory_score
        ) VALUES
            (v_sales_rep_id, 45, 50, 40, 45);
    END IF;
END $$;

-- ============================================================================
-- STEP 8: COMMENTS
-- ============================================================================

COMMENT ON TABLE public.security_thresholds IS 'Configuration thresholds for security monitoring';
COMMENT ON TABLE public.security_anomalies IS 'Detected security anomalies and alerts';
COMMENT ON TABLE public.user_risk_scores IS 'Calculated risk scores per user across different categories';
COMMENT ON TABLE public.failed_login_attempts IS 'Failed authentication attempts for security monitoring';