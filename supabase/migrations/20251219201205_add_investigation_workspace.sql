-- Location: supabase/migrations/20251219201205_add_investigation_workspace.sql
-- Schema Analysis: Extending existing incident management schema
-- Integration Type: Addition - Investigation workspace tables
-- Dependencies: security_anomalies, user_profiles, document_attachments

-- 1. Types
CREATE TYPE public.investigation_task_status AS ENUM ('assigned', 'in_progress', 'review', 'complete');
CREATE TYPE public.evidence_category AS ENUM ('log', 'screenshot', 'document', 'network_capture', 'forensic_artifact', 'other');
CREATE TYPE public.investigation_role AS ENUM ('lead_investigator', 'investigator', 'analyst', 'observer');

-- 2. Investigation Teams (Junction Table)
CREATE TABLE public.investigation_team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES public.security_anomalies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    role public.investigation_role DEFAULT 'investigator'::public.investigation_role,
    assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES public.user_profiles(id),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(incident_id, user_id)
);

-- 3. Investigation Tasks
CREATE TABLE public.investigation_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES public.security_anomalies(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    status public.investigation_task_status DEFAULT 'assigned'::public.investigation_task_status,
    priority INTEGER DEFAULT 0,
    assigned_to UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_by UUID NOT NULL REFERENCES public.user_profiles(id),
    due_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    sort_order INTEGER DEFAULT 0,
    checklist_items JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Investigation Evidence (Extends document_attachments pattern)
CREATE TABLE public.investigation_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES public.security_anomalies(id) ON DELETE CASCADE,
    category public.evidence_category NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT,
    file_size INTEGER,
    mime_type TEXT,
    metadata JSONB,
    is_critical BOOLEAN DEFAULT false,
    chain_of_custody JSONB,
    collected_by UUID NOT NULL REFERENCES public.user_profiles(id),
    collected_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Investigation Messages
CREATE TABLE public.investigation_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES public.security_anomalies(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.user_profiles(id),
    message TEXT NOT NULL,
    mentions JSONB,
    attachments JSONB,
    is_decision BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. Investigation Timeline Events
CREATE TABLE public.investigation_timeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES public.security_anomalies(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    description TEXT NOT NULL,
    actor_id UUID REFERENCES public.user_profiles(id),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. Indexes for Performance
CREATE INDEX idx_team_members_incident ON public.investigation_team_members(incident_id);
CREATE INDEX idx_team_members_user ON public.investigation_team_members(user_id);
CREATE INDEX idx_team_members_role ON public.investigation_team_members(role);

CREATE INDEX idx_tasks_incident ON public.investigation_tasks(incident_id);
CREATE INDEX idx_tasks_assigned_to ON public.investigation_tasks(assigned_to);
CREATE INDEX idx_tasks_status ON public.investigation_tasks(status);
CREATE INDEX idx_tasks_sort_order ON public.investigation_tasks(sort_order);

CREATE INDEX idx_evidence_incident ON public.investigation_evidence(incident_id);
CREATE INDEX idx_evidence_category ON public.investigation_evidence(category);
CREATE INDEX idx_evidence_collected_by ON public.investigation_evidence(collected_by);
CREATE INDEX idx_evidence_critical ON public.investigation_evidence(is_critical);

CREATE INDEX idx_messages_incident ON public.investigation_messages(incident_id);
CREATE INDEX idx_messages_sender ON public.investigation_messages(sender_id);
CREATE INDEX idx_messages_created_at ON public.investigation_messages(created_at);

CREATE INDEX idx_timeline_incident ON public.investigation_timeline(incident_id);
CREATE INDEX idx_timeline_created_at ON public.investigation_timeline(created_at);

-- 8. Functions (MUST BE BEFORE RLS)
CREATE OR REPLACE FUNCTION public.is_investigation_team_member(incident_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.investigation_team_members itm
    WHERE itm.incident_id = incident_uuid
    AND itm.user_id = auth.uid()
    AND itm.is_active = true
)
$$;

CREATE OR REPLACE FUNCTION public.log_investigation_timeline()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
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
$func$;

-- 9. Enable RLS
ALTER TABLE public.investigation_team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investigation_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investigation_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investigation_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investigation_timeline ENABLE ROW LEVEL SECURITY;

-- 10. RLS Policies (Using Pattern 7 - Complex Relationships)
CREATE POLICY "team_members_access_investigation_team"
ON public.investigation_team_members
FOR ALL
TO authenticated
USING (public.is_investigation_team_member(incident_id))
WITH CHECK (public.is_investigation_team_member(incident_id));

CREATE POLICY "team_members_access_investigation_tasks"
ON public.investigation_tasks
FOR ALL
TO authenticated
USING (public.is_investigation_team_member(incident_id))
WITH CHECK (public.is_investigation_team_member(incident_id));

CREATE POLICY "team_members_access_investigation_evidence"
ON public.investigation_evidence
FOR ALL
TO authenticated
USING (public.is_investigation_team_member(incident_id))
WITH CHECK (public.is_investigation_team_member(incident_id));

CREATE POLICY "team_members_access_investigation_messages"
ON public.investigation_messages
FOR ALL
TO authenticated
USING (public.is_investigation_team_member(incident_id))
WITH CHECK (public.is_investigation_team_member(incident_id));

CREATE POLICY "team_members_access_investigation_timeline"
ON public.investigation_timeline
FOR SELECT
TO authenticated
USING (public.is_investigation_team_member(incident_id));

-- Admin full access policies
CREATE POLICY "admin_full_access_team_members"
ON public.investigation_team_members
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

CREATE POLICY "admin_full_access_tasks"
ON public.investigation_tasks
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

CREATE POLICY "admin_full_access_evidence"
ON public.investigation_evidence
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

CREATE POLICY "admin_full_access_messages"
ON public.investigation_messages
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

CREATE POLICY "admin_full_access_timeline"
ON public.investigation_timeline
FOR ALL
TO authenticated
USING (public.is_admin_from_auth())
WITH CHECK (public.is_admin_from_auth());

-- 11. Triggers for Timeline Logging
CREATE TRIGGER log_task_timeline
AFTER INSERT OR UPDATE ON public.investigation_tasks
FOR EACH ROW
EXECUTE FUNCTION public.log_investigation_timeline();

CREATE TRIGGER log_evidence_timeline
AFTER INSERT OR UPDATE ON public.investigation_evidence
FOR EACH ROW
EXECUTE FUNCTION public.log_investigation_timeline();

CREATE TRIGGER log_team_timeline
AFTER INSERT OR UPDATE ON public.investigation_team_members
FOR EACH ROW
EXECUTE FUNCTION public.log_investigation_timeline();

-- 12. Mock Data for Testing
DO $$
DECLARE
    existing_incident_id UUID;
    existing_admin_id UUID;
    existing_user_id UUID;
    task1_id UUID := gen_random_uuid();
    task2_id UUID := gen_random_uuid();
    evidence1_id UUID := gen_random_uuid();
BEGIN
    SELECT id INTO existing_incident_id FROM public.security_anomalies LIMIT 1;
    SELECT id INTO existing_admin_id FROM public.user_profiles WHERE role = 'admin' LIMIT 1;
    SELECT id INTO existing_user_id FROM public.user_profiles WHERE role = 'sales_rep' LIMIT 1;

    IF existing_incident_id IS NOT NULL AND existing_admin_id IS NOT NULL THEN
        INSERT INTO public.investigation_team_members (incident_id, user_id, role, assigned_by)
        VALUES
            (existing_incident_id, existing_admin_id, 'lead_investigator'::public.investigation_role, existing_admin_id),
            (existing_incident_id, existing_user_id, 'investigator'::public.investigation_role, existing_admin_id);

        INSERT INTO public.investigation_tasks (id, incident_id, title, description, status, priority, assigned_to, created_by, sort_order)
        VALUES
            (task1_id, existing_incident_id, 'Analyze Network Logs', 'Review firewall and network traffic logs for anomalies', 'in_progress'::public.investigation_task_status, 1, existing_admin_id, existing_admin_id, 1),
            (task2_id, existing_incident_id, 'Interview Affected Users', 'Gather witness accounts from users who reported the incident', 'assigned'::public.investigation_task_status, 2, existing_user_id, existing_admin_id, 2);

        INSERT INTO public.investigation_evidence (id, incident_id, category, title, description, collected_by, is_critical)
        VALUES
            (evidence1_id, existing_incident_id, 'log'::public.evidence_category, 'Firewall Logs - Suspicious Traffic', 'Logs showing unauthorized access attempts from external IP', existing_admin_id, true);

        INSERT INTO public.investigation_messages (incident_id, sender_id, message, is_decision)
        VALUES
            (existing_incident_id, existing_admin_id, 'Initial analysis shows potential brute force attack. Escalating priority.', true),
            (existing_incident_id, existing_user_id, 'Confirmed multiple failed login attempts from same IP range. Collecting additional evidence.', false);
    END IF;
END $$;