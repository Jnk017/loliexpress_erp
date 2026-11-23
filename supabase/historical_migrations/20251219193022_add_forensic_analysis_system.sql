-- Location: supabase/migrations/20251219193022_add_forensic_analysis_system.sql
-- Schema Analysis: Existing audit_logs, user_sessions, security_anomalies tables
-- Integration Type: Extension - Adding forensic analysis capabilities
-- Dependencies: audit_logs, user_sessions, security_anomalies, user_profiles

-- ============================================
-- FORENSIC ANALYSIS EXTENSION MODULE
-- ============================================

-- 1. IP GEOLOCATION DATA TABLE
CREATE TABLE public.ip_geolocation_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ip_address INET NOT NULL UNIQUE,
    country_code VARCHAR(2),
    country_name TEXT,
    region TEXT,
    city TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    timezone TEXT,
    isp TEXT,
    is_proxy BOOLEAN DEFAULT false,
    is_vpn BOOLEAN DEFAULT false,
    threat_level TEXT CHECK (threat_level IN ('low', 'medium', 'high')),
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_coordinates CHECK (
        (latitude IS NULL AND longitude IS NULL) OR
        (latitude >= -90 AND latitude <= 90 AND longitude >= -180 AND longitude <= 180)
    )
);

-- 2. DEVICE FINGERPRINT TABLE
CREATE TABLE public.device_fingerprints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fingerprint_hash TEXT NOT NULL UNIQUE,
    user_agent TEXT NOT NULL,
    device_type TEXT,
    browser_name TEXT,
    browser_version TEXT,
    os_name TEXT,
    os_version TEXT,
    screen_resolution TEXT,
    timezone TEXT,
    language TEXT,
    platform TEXT,
    is_mobile BOOLEAN DEFAULT false,
    first_seen TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    total_sessions INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. FORENSIC EVENT TIMELINE TABLE
CREATE TABLE public.forensic_event_timeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    session_id UUID REFERENCES public.user_sessions(id) ON DELETE SET NULL,
    audit_log_id UUID REFERENCES public.audit_logs(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    event_category TEXT NOT NULL,
    event_timestamp TIMESTAMPTZ NOT NULL,
    ip_address INET,
    device_fingerprint_id UUID REFERENCES public.device_fingerprints(id) ON DELETE SET NULL,
    event_data JSONB,
    sequence_number INTEGER NOT NULL,
    time_delta_seconds INTEGER,
    is_anomalous BOOLEAN DEFAULT false,
    anomaly_score DECIMAL(5, 2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. ANOMALY CORRELATION PATTERNS TABLE
CREATE TABLE public.anomaly_correlation_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_name TEXT NOT NULL,
    pattern_type TEXT NOT NULL,
    anomaly_ids UUID[] NOT NULL,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    correlation_score DECIMAL(5, 2) NOT NULL,
    risk_level TEXT NOT NULL CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    pattern_description TEXT,
    detected_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    event_count INTEGER NOT NULL,
    unique_ips INTEGER,
    unique_devices INTEGER,
    investigation_status TEXT DEFAULT 'pending' CHECK (investigation_status IN ('pending', 'investigating', 'resolved', 'false_positive')),
    investigation_notes TEXT,
    investigated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    investigated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. FORENSIC INVESTIGATION REPORTS TABLE
CREATE TABLE public.forensic_investigation_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_title TEXT NOT NULL,
    report_type TEXT NOT NULL CHECK (report_type IN ('incident', 'user_behavior', 'threat_analysis', 'compliance_audit')),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    investigator_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    time_range_start TIMESTAMPTZ NOT NULL,
    time_range_end TIMESTAMPTZ NOT NULL,
    summary TEXT,
    findings JSONB,
    recommendations JSONB,
    evidence_audit_logs UUID[],
    evidence_sessions UUID[],
    evidence_anomalies UUID[],
    risk_assessment TEXT,
    severity TEXT CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'completed', 'archived')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ
);

-- ============================================
-- INDEXES FOR FORENSIC ANALYSIS
-- ============================================

CREATE INDEX idx_ip_geolocation_ip ON public.ip_geolocation_cache(ip_address);
CREATE INDEX idx_ip_geolocation_threat ON public.ip_geolocation_cache(threat_level) WHERE threat_level IN ('high', 'medium');
CREATE INDEX idx_ip_geolocation_proxy ON public.ip_geolocation_cache(is_proxy, is_vpn) WHERE is_proxy = true OR is_vpn = true;

CREATE INDEX idx_device_fingerprint_hash ON public.device_fingerprints(fingerprint_hash);
CREATE INDEX idx_device_fingerprint_last_seen ON public.device_fingerprints(last_seen DESC);

CREATE INDEX idx_forensic_timeline_user ON public.forensic_event_timeline(user_id, event_timestamp DESC);
CREATE INDEX idx_forensic_timeline_session ON public.forensic_event_timeline(session_id);
CREATE INDEX idx_forensic_timeline_anomalous ON public.forensic_event_timeline(is_anomalous) WHERE is_anomalous = true;
CREATE INDEX idx_forensic_timeline_timestamp ON public.forensic_event_timeline(event_timestamp DESC);

CREATE INDEX idx_anomaly_correlation_user ON public.anomaly_correlation_patterns(user_id, detected_at DESC);
CREATE INDEX idx_anomaly_correlation_risk ON public.anomaly_correlation_patterns(risk_level, investigation_status);
CREATE INDEX idx_anomaly_correlation_time ON public.anomaly_correlation_patterns(start_time, end_time);

CREATE INDEX idx_forensic_reports_user ON public.forensic_investigation_reports(user_id);
CREATE INDEX idx_forensic_reports_investigator ON public.forensic_investigation_reports(investigator_id);
CREATE INDEX idx_forensic_reports_time ON public.forensic_investigation_reports(time_range_start, time_range_end);

-- ============================================
-- RLS POLICIES
-- ============================================

ALTER TABLE public.ip_geolocation_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_fingerprints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forensic_event_timeline ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anomaly_correlation_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forensic_investigation_reports ENABLE ROW LEVEL SECURITY;

-- IP Geolocation (admin only)
CREATE POLICY "admin_view_ip_geolocation"
ON public.ip_geolocation_cache
FOR SELECT
TO authenticated
USING (public.is_admin_from_auth());

-- Device Fingerprints (admin only)
CREATE POLICY "admin_view_device_fingerprints"
ON public.device_fingerprints
FOR SELECT
TO authenticated
USING (public.is_admin_from_auth());

-- Forensic Timeline (users see own, admins see all)
CREATE POLICY "users_view_own_timeline"
ON public.forensic_event_timeline
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "admin_view_all_timeline"
ON public.forensic_event_timeline
FOR SELECT
TO authenticated
USING (public.is_admin_from_auth());

-- Anomaly Correlation (users see own, admins see all)
CREATE POLICY "users_view_own_correlations"
ON public.anomaly_correlation_patterns
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

CREATE POLICY "admin_manage_correlations"
ON public.anomaly_correlation_patterns
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- Forensic Reports (users see own, admins see all)
CREATE POLICY "users_view_own_reports"
ON public.forensic_investigation_reports
FOR SELECT
TO authenticated
USING (user_id = auth.uid() OR investigator_id = auth.uid());

CREATE POLICY "admin_manage_reports"
ON public.forensic_investigation_reports
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- ============================================
-- FORENSIC ANALYSIS FUNCTIONS
-- ============================================

-- Function to parse User-Agent and extract device details
CREATE OR REPLACE FUNCTION public.parse_user_agent(user_agent_text TEXT)
RETURNS JSONB
LANGUAGE plpgsql
IMMUTABLE
AS $func$
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
$func$;

-- Function to generate device fingerprint hash
CREATE OR REPLACE FUNCTION public.generate_device_fingerprint(
    user_agent_val TEXT,
    ip_addr INET
)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $func$
BEGIN
    RETURN md5(COALESCE(user_agent_val, '') || '|' || COALESCE(host(ip_addr), ''));
END;
$func$;

-- Function to calculate anomaly correlation score
CREATE OR REPLACE FUNCTION public.calculate_correlation_score(
    anomaly_ids_input UUID[]
)
RETURNS DECIMAL
LANGUAGE plpgsql
STABLE
AS $func$
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
$func$;

-- Function to build forensic timeline from audit logs
CREATE OR REPLACE FUNCTION public.build_forensic_timeline(
    user_id_input UUID,
    start_time_input TIMESTAMPTZ,
    end_time_input TIMESTAMPTZ
)
RETURNS TABLE(
    event_id UUID,
    event_timestamp TIMESTAMPTZ,
    event_type TEXT,
    event_category TEXT,
    event_description TEXT,
    ip_address INET,
    device_info JSONB,
    location_info JSONB,
    risk_indicator BOOLEAN
)
LANGUAGE plpgsql
STABLE
AS $func$
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
$func$;

-- Function to detect anomaly correlation patterns
CREATE OR REPLACE FUNCTION public.detect_correlation_patterns(
    user_id_input UUID,
    time_window_hours INTEGER DEFAULT 24
)
RETURNS TABLE(
    pattern_id UUID,
    pattern_type TEXT,
    correlated_anomalies UUID[],
    correlation_score DECIMAL,
    risk_level TEXT,
    description TEXT
)
LANGUAGE plpgsql
STABLE
AS $func$
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
$func$;

-- ============================================
-- MOCK DATA FOR FORENSIC ANALYSIS
-- ============================================

DO $$
DECLARE
    admin_user_id UUID;
    sample_session_id UUID;
    sample_audit_id UUID;
    fingerprint_id UUID;
BEGIN
    -- Get existing admin user
    SELECT id INTO admin_user_id FROM public.user_profiles WHERE role = 'admin' LIMIT 1;

    IF admin_user_id IS NULL THEN
        RAISE NOTICE 'No admin user found for forensic analysis mock data';
        RETURN;
    END IF;

    -- Insert sample IP geolocation data
    INSERT INTO public.ip_geolocation_cache (
        ip_address, country_code, country_name, region, city,
        latitude, longitude, timezone, isp, is_proxy, threat_level
    ) VALUES
        ('192.168.1.100', 'US', 'United States', 'California', 'San Francisco',
         37.7749, -122.4194, 'America/Los_Angeles', 'Comcast', false, 'low'),
        ('10.0.0.50', 'GB', 'United Kingdom', 'England', 'London',
         51.5074, -0.1278, 'Europe/London', 'BT Group', false, 'low'),
        ('203.0.113.45', 'CN', 'China', 'Beijing', 'Beijing',
         39.9042, 116.4074, 'Asia/Shanghai', 'Unknown ISP', true, 'high')
    ON CONFLICT (ip_address) DO NOTHING;

    -- Insert sample device fingerprints (one at a time to avoid multi-row return error)
    INSERT INTO public.device_fingerprints (
        fingerprint_hash, user_agent, device_type, browser_name, browser_version,
        os_name, os_version, screen_resolution, is_mobile
    ) VALUES
        (md5('device1'), 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0',
         'Desktop', 'Chrome', '120.0', 'Windows', '10', '1920x1080', false)
    ON CONFLICT (fingerprint_hash) DO NOTHING;

    INSERT INTO public.device_fingerprints (
        fingerprint_hash, user_agent, device_type, browser_name, browser_version,
        os_name, os_version, screen_resolution, is_mobile
    ) VALUES
        (md5('device2'), 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) Safari/604.1',
         'Mobile', 'Safari', '17.0', 'iOS', '17.0', '390x844', true)
    ON CONFLICT (fingerprint_hash) DO NOTHING;

    -- Get the first device fingerprint for use in timeline
    SELECT id INTO fingerprint_id 
    FROM public.device_fingerprints 
    WHERE fingerprint_hash = md5('device1') 
    LIMIT 1;

    -- Get sample session and audit log
    SELECT id INTO sample_session_id FROM public.user_sessions WHERE user_id = admin_user_id LIMIT 1;
    SELECT id INTO sample_audit_id FROM public.audit_logs WHERE user_id = admin_user_id LIMIT 1;

    -- Insert sample forensic timeline events
    IF sample_session_id IS NOT NULL AND fingerprint_id IS NOT NULL THEN
        INSERT INTO public.forensic_event_timeline (
            user_id, session_id, audit_log_id, event_type, event_category,
            event_timestamp, ip_address, device_fingerprint_id, sequence_number,
            is_anomalous, anomaly_score
        ) VALUES
            (admin_user_id, sample_session_id, sample_audit_id, 'login', 'authentication',
             NOW() - INTERVAL '2 hours', '192.168.1.100', fingerprint_id, 1, false, 0),
            (admin_user_id, sample_session_id, NULL, 'page_view', 'navigation',
             NOW() - INTERVAL '1 hour 55 minutes', '192.168.1.100', fingerprint_id, 2, false, 0),
            (admin_user_id, sample_session_id, sample_audit_id, 'update', 'user_profiles',
             NOW() - INTERVAL '1 hour 30 minutes', '192.168.1.100', fingerprint_id, 3, true, 65.5);
    END IF;
END $$;