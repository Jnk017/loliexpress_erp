-- Clean bootstrap 003: GED, notifications and workflow primitives.
CREATE TABLE IF NOT EXISTS public.document_attachments(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),entity_type text NOT NULL CHECK(entity_type IN('customer','sales_order','invoice','delivery','expense','purchase')),entity_id uuid NOT NULL,file_name text NOT NULL,file_path text NOT NULL UNIQUE,mime_type text,file_size bigint CHECK(file_size>=0),is_sensitive boolean NOT NULL DEFAULT false,uploaded_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.notification_queue(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),recipient_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,recipient_email text,notification_type text NOT NULL,channel text NOT NULL DEFAULT 'email' CHECK(channel IN('email','push','both')),subject text,payload jsonb NOT NULL DEFAULT '{}'::jsonb,status text NOT NULL DEFAULT 'pending' CHECK(status IN('pending','processing','sent','failed')),attempts integer NOT NULL DEFAULT 0,last_error text,created_at timestamptz NOT NULL DEFAULT now(),sent_at timestamptz);
CREATE TABLE IF NOT EXISTS public.notification_templates(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),notification_type text NOT NULL UNIQUE,subject_template text NOT NULL,email_body_template text,push_body_template text,variables jsonb NOT NULL DEFAULT '[]'::jsonb,is_active boolean NOT NULL DEFAULT true,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.workflow_transitions(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),entity_type text NOT NULL,entity_id uuid NOT NULL,from_status text,to_status text NOT NULL,reason text,changed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,created_at timestamptz NOT NULL DEFAULT now());
INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types) VALUES('erp-documents','erp-documents',false,52428800,ARRAY['application/pdf','image/jpeg','image/png','text/csv']) ON CONFLICT(id) DO UPDATE SET public=false;
INSERT INTO public.notification_templates(notification_type,subject_template,email_body_template,variables) VALUES
('user_invitation','Invitation LoliExpress ERP','Vous avez été invité à rejoindre LoliExpress ERP.','["full_name","invite_url"]'),
('invoice_reminder','Rappel de facture {{invoice_number}}','La facture {{invoice_number}} arrive à échéance.','["invoice_number","due_date"]'),
('stock_alert','Alerte de stock {{sku}}','Le stock du produit {{sku}} est sous le seuil.','["sku","quantity"]')
ON CONFLICT(notification_type) DO NOTHING;
DO $$ DECLARE t text; BEGIN FOREACH t IN ARRAY ARRAY['document_attachments','notification_queue','notification_templates','workflow_transitions'] LOOP EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t); END LOOP; END $$;
DROP POLICY IF EXISTS notification_own ON public.notification_queue;
CREATE POLICY notification_own ON public.notification_queue FOR SELECT TO authenticated USING(public.is_admin() OR recipient_id=auth.uid());
DROP POLICY IF EXISTS templates_admin ON public.notification_templates;
CREATE POLICY templates_admin ON public.notification_templates FOR ALL TO authenticated USING(public.is_admin()) WITH CHECK(public.is_admin());
DROP POLICY IF EXISTS workflow_admin_read ON public.workflow_transitions;
CREATE POLICY workflow_admin_read ON public.workflow_transitions FOR SELECT TO authenticated USING(public.is_admin());
