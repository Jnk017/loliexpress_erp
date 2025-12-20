-- Location: supabase/migrations/20251219194647_add_forensic_export_system.sql
-- Schema Analysis: Extending existing forensic analysis system with advanced export capabilities
-- Integration Type: PARTIAL_EXISTS - Extension
-- Dependencies: forensic_investigation_reports, forensic_event_timeline, anomaly_correlation_patterns, 
--               ip_geolocation_cache, device_fingerprints, audit_logs, security_anomalies, user_profiles

-- ============================================================================
-- STEP 1: ENUM TYPES FOR EXPORT SYSTEM
-- ============================================================================

CREATE TYPE public.export_format AS ENUM ('pdf', 'csv', 'json', 'excel');
CREATE TYPE public.export_template_type AS ENUM (
    'forensic_evidence', 
    'ip_correlation', 
    'investigation_summary',
    'regulatory_compliance',
    'incident_report',
    'audit_trail',
    'timeline_analysis'
);
CREATE TYPE public.export_status AS ENUM ('pending', 'processing', 'completed', 'failed');

-- ============================================================================
-- STEP 2: EXPORT TEMPLATES TABLE
-- ============================================================================

CREATE TABLE public.forensic_export_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_name TEXT NOT NULL,
    template_type public.export_template_type NOT NULL,
    description TEXT,
    format public.export_format NOT NULL,
    
    -- Template configuration
    include_timeline BOOLEAN DEFAULT true,
    include_ip_geolocation BOOLEAN DEFAULT true,
    include_device_fingerprints BOOLEAN DEFAULT true,
    include_anomaly_correlations BOOLEAN DEFAULT true,
    include_audit_logs BOOLEAN DEFAULT true,
    
    -- Regulatory compliance fields
    compliance_standard TEXT, -- ISO 27001, SOC2, GDPR, etc.
    report_sections JSONB, -- Structured report sections
    watermark_text TEXT,
    digital_signature_required BOOLEAN DEFAULT false,
    
    -- Metadata
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- ============================================================================
-- STEP 3: EXPORT HISTORY TABLE
-- ============================================================================

CREATE TABLE public.forensic_export_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    export_name TEXT NOT NULL,
    template_id UUID REFERENCES public.forensic_export_templates(id) ON DELETE SET NULL,
    
    -- Export parameters
    format public.export_format NOT NULL,
    status public.export_status DEFAULT 'pending'::public.export_status,
    
    -- Filter criteria (stored for audit trail)
    filter_start_date TIMESTAMPTZ,
    filter_end_date TIMESTAMPTZ,
    filter_user_ids UUID[],
    filter_anomaly_types TEXT[],
    filter_severity_levels TEXT[],
    filter_ip_addresses INET[],
    
    -- Export metadata
    file_path TEXT,
    file_size_bytes BIGINT,
    record_count INTEGER,
    
    -- Chain of custody
    exported_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    exported_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    digital_signature TEXT,
    watermark_applied BOOLEAN DEFAULT false,
    
    -- Error handling
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STEP 4: INDEXES
-- ============================================================================

CREATE INDEX idx_export_templates_type ON public.forensic_export_templates(template_type);
CREATE INDEX idx_export_templates_created_by ON public.forensic_export_templates(created_by);
CREATE INDEX idx_export_templates_active ON public.forensic_export_templates(is_active);

CREATE INDEX idx_export_history_status ON public.forensic_export_history(status);
CREATE INDEX idx_export_history_exported_by ON public.forensic_export_history(exported_by);
CREATE INDEX idx_export_history_exported_at ON public.forensic_export_history(exported_at);
CREATE INDEX idx_export_history_template_id ON public.forensic_export_history(template_id);
CREATE INDEX idx_export_history_date_range ON public.forensic_export_history(filter_start_date, filter_end_date);

-- ============================================================================
-- STEP 5: POSTGRESQL FUNCTIONS FOR EXPORT GENERATION
-- ============================================================================

-- Function: Generate filtered forensic evidence export data
CREATE OR REPLACE FUNCTION public.generate_forensic_evidence_export(
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
    p_user_ids UUID[] DEFAULT NULL,
    p_anomaly_types TEXT[] DEFAULT NULL,
    p_severity_levels TEXT[] DEFAULT NULL,
    p_ip_addresses INET[] DEFAULT NULL
)
RETURNS TABLE(
    evidence_type TEXT,
    event_timestamp TIMESTAMPTZ,
    user_email TEXT,
    ip_address INET,
    location_info TEXT,
    device_info TEXT,
    anomaly_description TEXT,
    risk_score NUMERIC,
    evidence_details JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- Function: Generate IP correlation export data
CREATE OR REPLACE FUNCTION public.generate_ip_correlation_export(
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
    p_threat_levels TEXT[] DEFAULT NULL
)
RETURNS TABLE(
    ip_address INET,
    country TEXT,
    city TEXT,
    isp TEXT,
    threat_level TEXT,
    is_proxy BOOLEAN,
    is_vpn BOOLEAN,
    connection_count BIGINT,
    unique_users BIGINT,
    first_seen TIMESTAMPTZ,
    last_seen TIMESTAMPTZ,
    suspicious_activities JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- Function: Generate investigation summary export
CREATE OR REPLACE FUNCTION public.generate_investigation_summary_export(
    p_investigation_report_id UUID
)
RETURNS TABLE(
    report_title TEXT,
    report_type TEXT,
    severity TEXT,
    status TEXT,
    investigator_name TEXT,
    time_range_start TIMESTAMPTZ,
    time_range_end TIMESTAMPTZ,
    summary TEXT,
    findings JSONB,
    risk_assessment TEXT,
    recommendations JSONB,
    evidence_count INTEGER,
    correlation_patterns JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- Function: Create export record and track audit trail
CREATE OR REPLACE FUNCTION public.create_forensic_export_record(
    p_export_name TEXT,
    p_template_id UUID,
    p_format public.export_format,
    p_filter_start_date TIMESTAMPTZ,
    p_filter_end_date TIMESTAMPTZ,
    p_filter_user_ids UUID[] DEFAULT NULL,
    p_filter_anomaly_types TEXT[] DEFAULT NULL,
    p_filter_severity_levels TEXT[] DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- ============================================================================
-- STEP 6: ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.forensic_export_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forensic_export_history ENABLE ROW LEVEL SECURITY;

-- Pattern 6: Role-Based Access - Admin full access
CREATE POLICY "admin_manage_export_templates"
ON public.forensic_export_templates
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- Pattern 2: Simple User Ownership - Users view own exports
CREATE POLICY "users_manage_own_exports"
ON public.forensic_export_history
FOR ALL
TO authenticated
USING (exported_by = auth.uid())
WITH CHECK (exported_by = auth.uid());

-- Pattern 6: Admin view all exports
CREATE POLICY "admin_view_all_exports"
ON public.forensic_export_history
FOR SELECT
TO authenticated
USING (public.is_admin_from_auth());

-- ============================================================================
-- STEP 7: MOCK DATA - Export Templates
-- ============================================================================

DO $$
DECLARE
    v_admin_id UUID;
BEGIN
    -- Get existing admin user
    SELECT id INTO v_admin_id FROM public.user_profiles WHERE role = 'admin' LIMIT 1;
    
    IF v_admin_id IS NOT NULL THEN
        -- ISO 27001 Compliance Template
        INSERT INTO public.forensic_export_templates (
            template_name,
            template_type,
            description,
            format,
            include_timeline,
            include_ip_geolocation,
            include_device_fingerprints,
            include_anomaly_correlations,
            include_audit_logs,
            compliance_standard,
            watermark_text,
            digital_signature_required,
            created_by
        ) VALUES (
            'ISO 27001 Security Incident Report',
            'regulatory_compliance'::public.export_template_type,
            'Complete security incident report compliant with ISO 27001 standards',
            'pdf'::public.export_format,
            true,
            true,
            true,
            true,
            true,
            'ISO 27001:2013',
            'CONFIDENTIAL - ISO 27001 Compliance Report',
            true,
            v_admin_id
        );

        -- Forensic Evidence Template
        INSERT INTO public.forensic_export_templates (
            template_name,
            template_type,
            description,
            format,
            include_timeline,
            include_ip_geolocation,
            include_device_fingerprints,
            include_anomaly_correlations,
            include_audit_logs,
            watermark_text,
            digital_signature_required,
            created_by
        ) VALUES (
            'Detailed Forensic Evidence Package',
            'forensic_evidence'::public.export_template_type,
            'Comprehensive forensic evidence with timeline, IP correlations, and device fingerprints',
            'csv'::public.export_format,
            true,
            true,
            true,
            true,
            true,
            'EVIDENCE PACKAGE - DO NOT DISTRIBUTE',
            true,
            v_admin_id
        );

        -- IP Correlation Template
        INSERT INTO public.forensic_export_templates (
            template_name,
            template_type,
            description,
            format,
            include_timeline,
            include_ip_geolocation,
            include_device_fingerprints,
            include_anomaly_correlations,
            include_audit_logs,
            created_by
        ) VALUES (
            'IP Geolocation Analysis Report',
            'ip_correlation'::public.export_template_type,
            'Geographic analysis of suspicious IP addresses and access patterns',
            'excel'::public.export_format,
            false,
            true,
            false,
            true,
            false,
            v_admin_id
        );
    END IF;
END $$;