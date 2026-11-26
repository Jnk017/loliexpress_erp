-- Location: supabase/migrations/20251219185253_add_user_interaction_metrics.sql
-- Schema Analysis: Existing audit_logs table with basic action tracking
-- Integration Type: Extension - Adding user interaction metrics
-- Dependencies: user_profiles, audit_logs

-- ============================================
-- 1. ENUM TYPES
-- ============================================

CREATE TYPE public.session_status AS ENUM ('active', 'idle', 'logged_out');
CREATE TYPE public.screen_category AS ENUM ('dashboard', 'inventory', 'sales', 'customers', 'finances', 'reports', 'settings', 'other');

-- ============================================
-- 2. USER SESSIONS TABLE
-- ============================================

CREATE TABLE public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    session_start TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    session_end TIMESTAMPTZ,
    duration_minutes INTEGER,
    ip_address INET,
    user_agent TEXT,
    device_type TEXT,
    status public.session_status DEFAULT 'active'::public.session_status,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 3. SCREEN VIEWS TABLE  
-- ============================================

CREATE TABLE public.screen_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    session_id UUID REFERENCES public.user_sessions(id) ON DELETE CASCADE,
    screen_name TEXT NOT NULL,
    screen_category public.screen_category DEFAULT 'other'::public.screen_category,
    view_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    time_spent_seconds INTEGER,
    previous_screen TEXT,
    next_screen TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 4. FEATURE USAGE STATS TABLE
-- ============================================

CREATE TABLE public.feature_usage_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    feature_name TEXT NOT NULL,
    module_name TEXT NOT NULL,
    action_type TEXT NOT NULL,
    usage_count INTEGER DEFAULT 1,
    last_used_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    average_time_seconds NUMERIC(10,2),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 5. INDEXES
-- ============================================

-- User sessions indexes
CREATE INDEX idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX idx_user_sessions_session_start ON public.user_sessions(session_start);
CREATE INDEX idx_user_sessions_status ON public.user_sessions(status);
CREATE INDEX idx_user_sessions_created_at ON public.user_sessions(created_at DESC);

-- Screen views indexes
CREATE INDEX idx_screen_views_user_id ON public.screen_views(user_id);
CREATE INDEX idx_screen_views_session_id ON public.screen_views(session_id);
CREATE INDEX idx_screen_views_screen_name ON public.screen_views(screen_name);
CREATE INDEX idx_screen_views_screen_category ON public.screen_views(screen_category);
CREATE INDEX idx_screen_views_timestamp ON public.screen_views(view_timestamp DESC);

-- Feature usage indexes
CREATE INDEX idx_feature_usage_user_id ON public.feature_usage_stats(user_id);
CREATE INDEX idx_feature_usage_feature_name ON public.feature_usage_stats(feature_name);
CREATE INDEX idx_feature_usage_module_name ON public.feature_usage_stats(module_name);
CREATE INDEX idx_feature_usage_last_used ON public.feature_usage_stats(last_used_at DESC);

-- Composite indexes for analytics queries
CREATE INDEX idx_screen_views_user_time ON public.screen_views(user_id, view_timestamp DESC);
CREATE INDEX idx_feature_usage_user_module ON public.feature_usage_stats(user_id, module_name, last_used_at DESC);

-- ============================================
-- 6. FUNCTIONS
-- ============================================

-- Function to automatically update session duration
CREATE OR REPLACE FUNCTION public.update_session_duration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NEW.session_end IS NOT NULL THEN
        NEW.duration_minutes := EXTRACT(EPOCH FROM (NEW.session_end - NEW.session_start)) / 60;
    END IF;
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Function to track screen view navigation
CREATE OR REPLACE FUNCTION public.track_screen_navigation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
$$;

-- Function to aggregate feature usage stats
CREATE OR REPLACE FUNCTION public.update_feature_usage_stats(
    p_user_id UUID,
    p_feature_name TEXT,
    p_module_name TEXT,
    p_action_type TEXT,
    p_time_seconds INTEGER DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
$$;

-- Function to get user productivity metrics
CREATE OR REPLACE FUNCTION public.get_user_productivity_metrics(
    p_user_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS TABLE(
    total_sessions INTEGER,
    total_session_time_minutes NUMERIC,
    avg_session_duration_minutes NUMERIC,
    total_screens_visited INTEGER,
    unique_screens_count INTEGER,
    most_used_feature TEXT,
    most_visited_screen TEXT,
    productivity_score NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
$$;

-- ============================================
-- 7. ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.screen_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_usage_stats ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 8. RLS POLICIES
-- ============================================

-- User sessions policies (Pattern 2: Simple User Ownership)
CREATE POLICY "users_manage_own_sessions"
ON public.user_sessions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Admin view all sessions (Pattern 6: Role-Based Access)
CREATE OR REPLACE FUNCTION public.is_admin_from_auth()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid() 
    AND (au.raw_user_meta_data->>'role' = 'admin' 
         OR au.raw_app_meta_data->>'role' = 'admin')
)
$$;

CREATE POLICY "admin_view_all_sessions"
ON public.user_sessions
FOR SELECT
TO authenticated
USING (public.is_admin_from_auth());

-- Screen views policies (Pattern 2: Simple User Ownership)
CREATE POLICY "users_manage_own_screen_views"
ON public.screen_views
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "admin_view_all_screen_views"
ON public.screen_views
FOR SELECT
TO authenticated
USING (public.is_admin_from_auth());

-- Feature usage policies (Pattern 2: Simple User Ownership)
CREATE POLICY "users_manage_own_feature_usage"
ON public.feature_usage_stats
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "admin_view_all_feature_usage"
ON public.feature_usage_stats
FOR SELECT
TO authenticated
USING (public.is_admin_from_auth());

-- ============================================
-- 9. TRIGGERS
-- ============================================

CREATE TRIGGER trigger_update_session_duration
    BEFORE UPDATE ON public.user_sessions
    FOR EACH ROW
    EXECUTE FUNCTION public.update_session_duration();

CREATE TRIGGER trigger_track_screen_navigation
    BEFORE INSERT ON public.screen_views
    FOR EACH ROW
    EXECUTE FUNCTION public.track_screen_navigation();

-- ============================================
-- 10. MOCK DATA
-- ============================================

DO $$
DECLARE
    admin_user_id UUID;
    sales_user_id UUID;
    session1_id UUID;
    session2_id UUID;
BEGIN
    -- Get existing user IDs
    SELECT id INTO admin_user_id FROM public.user_profiles WHERE role = 'admin' LIMIT 1;
    SELECT id INTO sales_user_id FROM public.user_profiles WHERE role = 'sales_rep' LIMIT 1;

    IF admin_user_id IS NULL OR sales_user_id IS NULL THEN
        RAISE NOTICE 'No existing users found. Skipping mock data insertion.';
        RETURN;
    END IF;

    -- Insert sample sessions
    session1_id := gen_random_uuid();
    session2_id := gen_random_uuid();

    INSERT INTO public.user_sessions (id, user_id, session_start, session_end, ip_address, device_type, status)
    VALUES
        (session1_id, admin_user_id, CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '30 minutes', '192.168.1.100', 'Desktop', 'logged_out'),
        (session2_id, sales_user_id, CURRENT_TIMESTAMP - INTERVAL '1 hour', NULL, '192.168.1.101', 'Mobile', 'active');

    -- Insert screen views
    INSERT INTO public.screen_views (user_id, session_id, screen_name, screen_category, view_timestamp, time_spent_seconds)
    VALUES
        (admin_user_id, session1_id, 'Main Dashboard', 'dashboard', CURRENT_TIMESTAMP - INTERVAL '2 hours', 180),
        (admin_user_id, session1_id, 'Financial Dashboard', 'finances', CURRENT_TIMESTAMP - INTERVAL '1 hour 45 minutes', 420),
        (admin_user_id, session1_id, 'Audit Log', 'reports', CURRENT_TIMESTAMP - INTERVAL '1 hour 15 minutes', 600),
        (sales_user_id, session2_id, 'Main Dashboard', 'dashboard', CURRENT_TIMESTAMP - INTERVAL '1 hour', 120),
        (sales_user_id, session2_id, 'Sales Orders', 'sales', CURRENT_TIMESTAMP - INTERVAL '45 minutes', 900),
        (sales_user_id, session2_id, 'Customer Management', 'customers', CURRENT_TIMESTAMP - INTERVAL '15 minutes', 300);

    -- Insert feature usage stats
    INSERT INTO public.feature_usage_stats (user_id, feature_name, module_name, action_type, usage_count, average_time_seconds)
    VALUES
        (admin_user_id, 'View Financial Reports', 'Finances', 'VIEW', 15, 45.5),
        (admin_user_id, 'Export Audit Logs', 'Reports', 'EXPORT', 8, 12.3),
        (admin_user_id, 'Create User', 'Settings', 'CREATE', 3, 90.2),
        (sales_user_id, 'Create Sales Order', 'Sales', 'CREATE', 42, 120.5),
        (sales_user_id, 'View Customer Details', 'Customers', 'VIEW', 68, 30.8),
        (sales_user_id, 'Update Order Status', 'Sales', 'UPDATE', 35, 15.2);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inserting mock data: %', SQLERRM;
END $$;

-- ============================================
-- 11. COMMENTS
-- ============================================

COMMENT ON TABLE public.user_sessions IS 'Tracks user login sessions with duration and device info';
COMMENT ON TABLE public.screen_views IS 'Records screen navigation and time spent per screen';
COMMENT ON TABLE public.feature_usage_stats IS 'Aggregates feature usage frequency and performance metrics';

COMMENT ON FUNCTION public.update_feature_usage_stats IS 'Increments feature usage count and updates average time';
COMMENT ON FUNCTION public.get_user_productivity_metrics IS 'Calculates comprehensive productivity score for users';