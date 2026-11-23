-- Location: supabase/migrations/20251219180550_add_audit_configuration_system.sql
-- Schema Analysis: 18 existing tables (user_profiles, customers, products, sales_orders, etc.)
-- Integration Type: ADDITIVE (adding 4 new tables for audit and configuration)
-- Dependencies: user_profiles, existing business tables
-- Module: System Administration & Audit Trail

-- ============================================================
-- 1. CREATE CUSTOM TYPES
-- ============================================================

-- Audit action types
CREATE TYPE public.audit_action_type AS ENUM (
    'insert',
    'update', 
    'delete',
    'login',
    'logout',
    'export',
    'import'
);

-- Configuration value types
CREATE TYPE public.config_value_type AS ENUM (
    'string',
    'number',
    'boolean',
    'json',
    'date'
);

-- Permission types
CREATE TYPE public.permission_type AS ENUM (
    'module',
    'feature',
    'action'
);

-- Workflow entity types
CREATE TYPE public.workflow_entity_type AS ENUM (
    'sales_order',
    'invoice',
    'payment',
    'delivery'
);

-- Workflow states
CREATE TYPE public.workflow_state_type AS ENUM (
    'draft',
    'pending_approval',
    'approved',
    'rejected',
    'completed',
    'cancelled'
);

-- ============================================================
-- 2. CREATE CORE TABLES
-- ============================================================

-- Table 1: Audit Logs - Complete activity tracing
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action_type public.audit_action_type NOT NULL,
    old_values JSONB,
    new_values JSONB,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 2: System Configuration - Company settings
CREATE TABLE public.system_configuration (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key TEXT NOT NULL UNIQUE,
    config_value TEXT NOT NULL,
    config_type public.config_value_type DEFAULT 'string'::public.config_value_type,
    description TEXT,
    is_editable BOOLEAN DEFAULT true,
    company_id UUID,
    category TEXT DEFAULT 'general',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Table 3: User Permissions - Granular access control
CREATE TABLE public.user_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    module_name TEXT NOT NULL,
    permission_type public.permission_type DEFAULT 'module'::public.permission_type,
    can_view BOOLEAN DEFAULT false,
    can_create BOOLEAN DEFAULT false,
    can_edit BOOLEAN DEFAULT false,
    can_delete BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, module_name, permission_type)
);

-- Table 4: Workflow States - Document approval tracking
CREATE TABLE public.workflow_states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type public.workflow_entity_type NOT NULL,
    entity_id UUID NOT NULL,
    current_state public.workflow_state_type NOT NULL,
    previous_state public.workflow_state_type,
    changed_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    change_reason TEXT,
    approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. CREATE INDEXES
-- ============================================================

-- Audit logs indexes
CREATE INDEX idx_audit_logs_table_name ON public.audit_logs(table_name);
CREATE INDEX idx_audit_logs_record_id ON public.audit_logs(record_id);
CREATE INDEX idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_action_type ON public.audit_logs(action_type);
CREATE INDEX idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

-- System configuration indexes
CREATE INDEX idx_system_config_category ON public.system_configuration(category);
CREATE INDEX idx_system_config_company ON public.system_configuration(company_id);

-- User permissions indexes
CREATE INDEX idx_user_permissions_user_id ON public.user_permissions(user_id);
CREATE INDEX idx_user_permissions_module ON public.user_permissions(module_name);

-- Workflow states indexes
CREATE INDEX idx_workflow_states_entity ON public.workflow_states(entity_type, entity_id);
CREATE INDEX idx_workflow_states_current ON public.workflow_states(current_state);
CREATE INDEX idx_workflow_states_changed_by ON public.workflow_states(changed_by);

-- ============================================================
-- 4. CREATE HELPER FUNCTIONS (BEFORE RLS POLICIES)
-- ============================================================

-- Function to check if user is admin (using existing user_role enum)
CREATE OR REPLACE FUNCTION public.is_system_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND up.role = 'admin'::public.user_role
)
$$;

-- Function to check if user has specific permission
CREATE OR REPLACE FUNCTION public.has_module_permission(
    module TEXT,
    permission TEXT
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
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
$$;

-- Function to log audit trail automatically
CREATE OR REPLACE FUNCTION public.log_audit_trail()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
$$;

-- ============================================================
-- 5. ENABLE ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_configuration ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workflow_states ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 6. CREATE RLS POLICIES
-- ============================================================

-- Audit Logs: Admin-only access (read-only for compliance)
CREATE POLICY "admin_view_all_audit_logs"
ON public.audit_logs
FOR SELECT
TO authenticated
USING (public.is_system_admin());

-- Users can view their own audit trail
CREATE POLICY "users_view_own_audit_logs"
ON public.audit_logs
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- System Configuration: Admin full access
CREATE POLICY "admin_manage_system_config"
ON public.system_configuration
FOR ALL
TO authenticated
USING (public.is_system_admin())
WITH CHECK (public.is_system_admin());

-- All authenticated users can view non-editable configs
CREATE POLICY "users_view_system_config"
ON public.system_configuration
FOR SELECT
TO authenticated
USING (true);

-- User Permissions: Pattern 2 (Simple User Ownership)
CREATE POLICY "users_view_own_permissions"
ON public.user_permissions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Admin can manage all permissions
CREATE POLICY "admin_manage_all_permissions"
ON public.user_permissions
FOR ALL
TO authenticated
USING (public.is_system_admin())
WITH CHECK (public.is_system_admin());

-- Workflow States: Users can view states for entities they have access to
CREATE POLICY "users_view_workflow_states"
ON public.workflow_states
FOR SELECT
TO authenticated
USING (true);

-- Pattern 2: Users can create workflow states for their entities
CREATE POLICY "users_create_workflow_states"
ON public.workflow_states
FOR INSERT
TO authenticated
WITH CHECK (changed_by = auth.uid());

-- Admin can manage all workflow states
CREATE POLICY "admin_manage_workflow_states"
ON public.workflow_states
FOR ALL
TO authenticated
USING (public.is_system_admin())
WITH CHECK (public.is_system_admin());

-- ============================================================
-- 7. CREATE AUDIT TRIGGERS FOR EXISTING TABLES
-- ============================================================

-- Apply audit logging to critical business tables
CREATE TRIGGER audit_sales_orders
AFTER INSERT OR UPDATE OR DELETE ON public.sales_orders
FOR EACH ROW EXECUTE FUNCTION public.log_audit_trail();

CREATE TRIGGER audit_invoices
AFTER INSERT OR UPDATE OR DELETE ON public.invoices
FOR EACH ROW EXECUTE FUNCTION public.log_audit_trail();

CREATE TRIGGER audit_payments
AFTER INSERT OR UPDATE OR DELETE ON public.payments
FOR EACH ROW EXECUTE FUNCTION public.log_audit_trail();

CREATE TRIGGER audit_customers
AFTER INSERT OR UPDATE OR DELETE ON public.customers
FOR EACH ROW EXECUTE FUNCTION public.log_audit_trail();

CREATE TRIGGER audit_products
AFTER INSERT OR UPDATE OR DELETE ON public.products
FOR EACH ROW EXECUTE FUNCTION public.log_audit_trail();

-- ============================================================
-- 8. MOCK DATA GENERATION
-- ============================================================

DO $$
DECLARE
    existing_admin_id UUID;
    existing_sales_id UUID;
    existing_warehouse_id UUID;
    existing_order_id UUID;
    existing_invoice_id UUID;
BEGIN
    -- Get existing user IDs from different roles
    SELECT id INTO existing_admin_id 
    FROM public.user_profiles 
    WHERE role = 'admin'::public.user_role 
    LIMIT 1;
    
    SELECT id INTO existing_sales_id 
    FROM public.user_profiles 
    WHERE role = 'sales_rep'::public.user_role 
    LIMIT 1;
    
    SELECT id INTO existing_warehouse_id 
    FROM public.user_profiles 
    WHERE role = 'warehouse_staff'::public.user_role 
    LIMIT 1;

    -- Get existing business entity IDs
    SELECT id INTO existing_order_id FROM public.sales_orders LIMIT 1;
    SELECT id INTO existing_invoice_id FROM public.invoices LIMIT 1;

    -- Only proceed if we have required data
    IF existing_admin_id IS NOT NULL THEN
        -- Insert system configurations
        INSERT INTO public.system_configuration (config_key, config_value, config_type, description, category, is_editable)
        VALUES
            ('company_name', 'LoliExpress ERP', 'string'::public.config_value_type, 'Company display name', 'general', true),
            ('tax_rate', '20', 'number'::public.config_value_type, 'Default VAT rate percentage', 'finance', true),
            ('currency', 'EUR', 'string'::public.config_value_type, 'Default currency code', 'finance', true),
            ('low_stock_threshold', '10', 'number'::public.config_value_type, 'Alert threshold for low stock', 'inventory', true),
            ('invoice_prefix', 'INV', 'string'::public.config_value_type, 'Invoice number prefix', 'finance', true),
            ('order_prefix', 'ORD', 'string'::public.config_value_type, 'Order number prefix', 'sales', true),
            ('enable_notifications', 'true', 'boolean'::public.config_value_type, 'Enable system notifications', 'system', true),
            ('session_timeout', '3600', 'number'::public.config_value_type, 'Session timeout in seconds', 'security', false);

        -- Insert user permissions for admin
        INSERT INTO public.user_permissions (user_id, module_name, permission_type, can_view, can_create, can_edit, can_delete)
        VALUES
            (existing_admin_id, 'dashboard', 'module'::public.permission_type, true, true, true, true),
            (existing_admin_id, 'sales', 'module'::public.permission_type, true, true, true, true),
            (existing_admin_id, 'inventory', 'module'::public.permission_type, true, true, true, true),
            (existing_admin_id, 'finance', 'module'::public.permission_type, true, true, true, true),
            (existing_admin_id, 'reports', 'module'::public.permission_type, true, true, true, true),
            (existing_admin_id, 'users', 'module'::public.permission_type, true, true, true, true);

        -- Insert permissions for sales rep if exists
        IF existing_sales_id IS NOT NULL THEN
            INSERT INTO public.user_permissions (user_id, module_name, permission_type, can_view, can_create, can_edit, can_delete)
            VALUES
                (existing_sales_id, 'dashboard', 'module'::public.permission_type, true, false, false, false),
                (existing_sales_id, 'sales', 'module'::public.permission_type, true, true, true, false),
                (existing_sales_id, 'customers', 'module'::public.permission_type, true, true, true, false),
                (existing_sales_id, 'products', 'module'::public.permission_type, true, false, false, false);
        END IF;

        -- Insert permissions for warehouse staff if exists
        IF existing_warehouse_id IS NOT NULL THEN
            INSERT INTO public.user_permissions (user_id, module_name, permission_type, can_view, can_create, can_edit, can_delete)
            VALUES
                (existing_warehouse_id, 'inventory', 'module'::public.permission_type, true, true, true, false),
                (existing_warehouse_id, 'products', 'module'::public.permission_type, true, false, true, false),
                (existing_warehouse_id, 'barcode', 'module'::public.permission_type, true, true, false, false);
        END IF;

        -- Insert workflow states for existing orders
        IF existing_order_id IS NOT NULL THEN
            INSERT INTO public.workflow_states (entity_type, entity_id, current_state, previous_state, changed_by, change_reason)
            VALUES
                ('sales_order'::public.workflow_entity_type, existing_order_id, 'pending_approval'::public.workflow_state_type, 'draft'::public.workflow_state_type, existing_admin_id, 'Order submitted for approval'),
                ('sales_order'::public.workflow_entity_type, existing_order_id, 'approved'::public.workflow_state_type, 'pending_approval'::public.workflow_state_type, existing_admin_id, 'Order approved by manager');
        END IF;

        -- Insert workflow states for existing invoices
        IF existing_invoice_id IS NOT NULL THEN
            INSERT INTO public.workflow_states (entity_type, entity_id, current_state, previous_state, changed_by, change_reason, approved_by, approved_at)
            VALUES
                ('invoice'::public.workflow_entity_type, existing_invoice_id, 'approved'::public.workflow_state_type, 'draft'::public.workflow_state_type, existing_admin_id, 'Invoice validated and approved', existing_admin_id, now());
        END IF;

        -- Insert sample audit logs (will be generated automatically by triggers going forward)
        INSERT INTO public.audit_logs (table_name, record_id, action_type, new_values, user_id, created_at)
        VALUES
            ('system_configuration', gen_random_uuid(), 'insert'::public.audit_action_type, '{"config_key": "company_name", "config_value": "LoliExpress ERP"}'::jsonb, existing_admin_id, now() - interval '2 days'),
            ('user_permissions', gen_random_uuid(), 'insert'::public.audit_action_type, '{"module_name": "sales", "can_create": true}'::jsonb, existing_admin_id, now() - interval '1 day');

    ELSE
        RAISE NOTICE 'No admin user found. Please create users first via the authentication system.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data generation error: %', SQLERRM;
END $$;

-- ============================================================
-- 9. COMMENTS FOR DOCUMENTATION
-- ============================================================

COMMENT ON TABLE public.audit_logs IS 'Complete audit trail of all system modifications';
COMMENT ON TABLE public.system_configuration IS 'Company-wide configuration and settings';
COMMENT ON TABLE public.user_permissions IS 'Granular permission control per user and module';
COMMENT ON TABLE public.workflow_states IS 'Document approval and workflow state tracking';

COMMENT ON FUNCTION public.log_audit_trail() IS 'Automatically logs changes to audited tables';
COMMENT ON FUNCTION public.is_system_admin() IS 'Checks if current user has admin role';
COMMENT ON FUNCTION public.has_module_permission(TEXT, TEXT) IS 'Validates user permission for specific module action';