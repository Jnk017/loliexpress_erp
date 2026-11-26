-- Location: supabase/migrations/20251201021518_add_ged_and_workflow_automation.sql
-- Schema Analysis: Existing ERP schema with customers, expenses, sales_orders, etc.
-- Integration Type: Addition (New module for document management and workflow automation)
-- Dependencies: customers, expenses, sales_orders, user_profiles

-- ============================================================================
-- 1. DOCUMENT MANAGEMENT (GED) - NEW TABLES
-- ============================================================================

-- Create enum for entity types that can have attachments
CREATE TYPE public.attachment_entity_type AS ENUM (
    'customer',
    'expense', 
    'purchase_order',
    'invoice',
    'delivery'
);

-- Table for tracking document attachments metadata
CREATE TABLE public.document_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type public.attachment_entity_type NOT NULL,
    entity_id UUID NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    mime_type TEXT NOT NULL,
    uploaded_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    CONSTRAINT check_file_size CHECK (file_size > 0 AND file_size <= 10485760)
);

-- Indexes for document attachments
CREATE INDEX idx_document_attachments_entity ON public.document_attachments(entity_type, entity_id);
CREATE INDEX idx_document_attachments_uploaded_by ON public.document_attachments(uploaded_by);

-- ============================================================================
-- 2. WORKFLOW AUTOMATION - NOTIFICATION SYSTEM
-- ============================================================================

-- Create enum for notification types
CREATE TYPE public.notification_type AS ENUM (
    'new_order',
    'overdue_invoice',
    'low_stock',
    'payment_received',
    'order_delivered'
);

-- Create enum for notification status
CREATE TYPE public.notification_status AS ENUM (
    'pending',
    'sent',
    'failed'
);

-- Create enum for notification channels
CREATE TYPE public.notification_channel AS ENUM (
    'email',
    'push',
    'both'
);

-- Table for notification queue
CREATE TABLE public.notification_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_type public.notification_type NOT NULL,
    recipient_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    recipient_email TEXT NOT NULL,
    channel public.notification_channel NOT NULL,
    subject TEXT NOT NULL,
    message TEXT NOT NULL,
    status public.notification_status DEFAULT 'pending'::public.notification_status,
    related_entity_type TEXT,
    related_entity_id UUID,
    scheduled_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMPTZ,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for notification queue
CREATE INDEX idx_notification_queue_status ON public.notification_queue(status);
CREATE INDEX idx_notification_queue_recipient ON public.notification_queue(recipient_id);
CREATE INDEX idx_notification_queue_scheduled ON public.notification_queue(scheduled_at);

-- Table for notification templates
CREATE TABLE public.notification_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_type public.notification_type NOT NULL UNIQUE,
    subject_template TEXT NOT NULL,
    email_body_template TEXT NOT NULL,
    push_body_template TEXT,
    variables JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 3. STORAGE BUCKETS FOR DOCUMENTS
-- ============================================================================

-- Create private bucket for user documents
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'erp-documents',
    'erp-documents',
    false,
    10485760,
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/webp', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
);

-- ============================================================================
-- 4. ENABLE ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.document_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. RLS POLICIES FOR DOCUMENT ATTACHMENTS
-- ============================================================================

-- Admin has full access to all documents
CREATE POLICY "admin_full_access_documents"
ON public.document_attachments
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Sales reps can manage documents for their customers
CREATE POLICY "sales_rep_manage_customer_documents"
ON public.document_attachments
FOR ALL
TO authenticated
USING (
    public.is_sales_rep() AND
    entity_type = 'customer' AND
    EXISTS (
        SELECT 1 FROM public.customers c
        WHERE c.id = entity_id AND c.commercial_id = auth.uid()
    )
)
WITH CHECK (
    public.is_sales_rep() AND
    entity_type = 'customer' AND
    EXISTS (
        SELECT 1 FROM public.customers c
        WHERE c.id = entity_id AND c.commercial_id = auth.uid()
    )
);

-- Warehouse staff can manage documents for purchases and deliveries
CREATE POLICY "warehouse_manage_operational_documents"
ON public.document_attachments
FOR ALL
TO authenticated
USING (
    public.is_warehouse_staff() AND
    entity_type IN ('purchase_order', 'delivery')
);

-- ============================================================================
-- 6. RLS POLICIES FOR STORAGE BUCKET
-- ============================================================================

-- Users can manage their own uploaded files
CREATE POLICY "users_manage_own_documents"
ON storage.objects
FOR ALL
TO authenticated
USING (
    bucket_id = 'erp-documents' AND
    owner = auth.uid()
)
WITH CHECK (
    bucket_id = 'erp-documents' AND
    owner = auth.uid()
);

-- Admin can access all documents
CREATE POLICY "admin_access_all_documents"
ON storage.objects
FOR ALL
TO authenticated
USING (
    bucket_id = 'erp-documents' AND
    public.is_admin()
)
WITH CHECK (
    bucket_id = 'erp-documents' AND
    public.is_admin()
);

-- ============================================================================
-- 7. RLS POLICIES FOR NOTIFICATIONS
-- ============================================================================

-- Users can view their own notifications
CREATE POLICY "users_view_own_notifications"
ON public.notification_queue
FOR SELECT
TO authenticated
USING (recipient_id = auth.uid());

-- Admin can manage all notifications
CREATE POLICY "admin_manage_notifications"
ON public.notification_queue
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Admin can manage notification templates
CREATE POLICY "admin_manage_templates"
ON public.notification_templates
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- All authenticated users can view templates
CREATE POLICY "authenticated_view_templates"
ON public.notification_templates
FOR SELECT
TO authenticated
USING (true);

-- ============================================================================
-- 8. FUNCTIONS FOR WORKFLOW AUTOMATION
-- ============================================================================

-- Function to create notification for new order
CREATE OR REPLACE FUNCTION public.notify_new_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
$$;

-- Function to check for overdue invoices and create notifications
CREATE OR REPLACE FUNCTION public.check_overdue_invoices()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    overdue_invoice RECORD;
BEGIN
    FOR overdue_invoice IN
        SELECT 
            i.id,
            i.customer_id,
            c.commercial_id,
            up.email,
            i.invoice_date,
            i.due_date,
            c.name as customer_name
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
            'overdue_invoice'::public.notification_type,
            overdue_invoice.commercial_id,
            overdue_invoice.email,
            'email'::public.notification_channel,
            'Alerte : Facture échue',
            'Alerte : Facture #' || overdue_invoice.id::TEXT || ' du client ' || overdue_invoice.customer_name || ' est échue. Veuillez procéder au recouvrement.',
            'invoice',
            overdue_invoice.id
        );
    END LOOP;
END;
$$;

-- Function to check low stock and create notifications
CREATE OR REPLACE FUNCTION public.check_low_stock()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    low_stock_item RECORD;
    admin_users UUID[];
    admin_user UUID;
BEGIN
    -- Get all admin users
    SELECT ARRAY_AGG(id) INTO admin_users
    FROM public.user_profiles
    WHERE role = 'admin';
    
    FOR low_stock_item IN
        SELECT 
            p.id,
            p.name,
            p.reorder_level,
            COALESCE(SUM(s.quantity), 0) as total_quantity
        FROM public.products p
        LEFT JOIN public.inventory_stock s ON p.id = s.product_id
        GROUP BY p.id, p.name, p.reorder_level
        HAVING COALESCE(SUM(s.quantity), 0) <= p.reorder_level
        AND NOT EXISTS (
            SELECT 1 FROM public.notification_queue nq
            WHERE nq.related_entity_id = p.id
            AND nq.notification_type = 'low_stock'
            AND nq.created_at > CURRENT_DATE - INTERVAL '1 day'
        )
    LOOP
        -- Create notification for each admin
        FOREACH admin_user IN ARRAY admin_users
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
                'low_stock'::public.notification_type,
                admin_user,
                up.email,
                'both'::public.notification_channel,
                'Alerte Stock : Réapprovisionnement nécessaire',
                'Alerte Stock : Le produit ' || low_stock_item.name || ' est tombé sous le seuil critique (Stock actuel : ' || low_stock_item.total_quantity || ').',
                'product',
                low_stock_item.id
            FROM public.user_profiles up
            WHERE up.id = admin_user;
        END LOOP;
    END LOOP;
END;
$$;

-- Function to notify on payment received
CREATE OR REPLACE FUNCTION public.notify_payment_received()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    admin_users UUID[];
    admin_user UUID;
    customer_name TEXT;
BEGIN
    -- Get customer name
    SELECT c.name INTO customer_name
    FROM public.invoices i
    JOIN public.customers c ON i.customer_id = c.id
    WHERE i.id = NEW.invoice_id;
    
    -- Get all admin users
    SELECT ARRAY_AGG(id) INTO admin_users
    FROM public.user_profiles
    WHERE role = 'admin';
    
    -- Create notification for each admin
    FOREACH admin_user IN ARRAY admin_users
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
            'payment_received'::public.notification_type,
            admin_user,
            up.email,
            'email'::public.notification_channel,
            'Paiement reçu',
            'Paiement de ' || NEW.amount::TEXT || ' reçu du client ' || customer_name || '.',
            'payment',
            NEW.id
        FROM public.user_profiles up
        WHERE up.id = admin_user;
    END LOOP;
    
    RETURN NEW;
END;
$$;

-- Function to notify customer on order delivery
CREATE OR REPLACE FUNCTION public.notify_order_delivered()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
$$;

-- ============================================================================
-- 9. CREATE TRIGGERS FOR WORKFLOW AUTOMATION
-- ============================================================================

-- Trigger for new order notification
CREATE TRIGGER trigger_notify_new_order
    AFTER INSERT ON public.sales_orders
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_new_order();

-- Trigger for payment received notification
CREATE TRIGGER trigger_notify_payment
    AFTER INSERT ON public.payments
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_payment_received();

-- Trigger for order delivered notification
CREATE TRIGGER trigger_notify_delivery
    AFTER UPDATE ON public.deliveries
    FOR EACH ROW
    WHEN (NEW.status = 'delivered')
    EXECUTE FUNCTION public.notify_order_delivered();

-- ============================================================================
-- 10. INSERT DEFAULT NOTIFICATION TEMPLATES
-- ============================================================================

INSERT INTO public.notification_templates (notification_type, subject_template, email_body_template, push_body_template, variables) VALUES
('new_order', 'Nouvelle commande à préparer', 
 'Bonjour,\n\nUne nouvelle commande #{order_id} a été reçue et doit être préparée.\n\nDétails :\n- Client : {customer_name}\n- Date : {order_date}\n- Total : {total_amount}\n\nMerci de traiter cette commande rapidement.\n\nCordialement,\nLoliexpress',
 'Nouvelle commande #{order_id} à préparer',
 '{"order_id": "UUID", "customer_name": "string", "order_date": "date", "total_amount": "decimal"}'::jsonb),

('overdue_invoice', 'Alerte : Facture échue', 
 'Bonjour,\n\nLa facture #{invoice_id} du client {customer_name} est échue depuis le {due_date}.\n\nMontant : {invoice_amount}\nDate de facture : {invoice_date}\nDate d échéance : {due_date}\n\nMerci de procéder au recouvrement dans les plus brefs délais.\n\nCordialement,\nLoliexpress',
 'Facture #{invoice_id} échue - Client {customer_name}',
 '{"invoice_id": "UUID", "customer_name": "string", "invoice_date": "date", "due_date": "date", "invoice_amount": "decimal"}'::jsonb),

('low_stock', 'Alerte Stock : Réapprovisionnement nécessaire', 
 'Bonjour,\n\nLe produit {product_name} est tombé sous le seuil critique de réapprovisionnement.\n\nStock actuel : {current_stock}\nSeuil minimum : {reorder_level}\n\nMerci de procéder à une commande fournisseur rapidement.\n\nCordialement,\nLoliexpress',
 'Stock faible : {product_name} ({current_stock} unités)',
 '{"product_name": "string", "current_stock": "integer", "reorder_level": "integer"}'::jsonb),

('payment_received', 'Paiement reçu', 
 'Bonjour,\n\nUn paiement de {payment_amount} a été reçu du client {customer_name}.\n\nDétails :\n- Facture : #{invoice_id}\n- Date de paiement : {payment_date}\n- Mode de paiement : {payment_method}\n\nCordialement,\nLoliexpress',
 'Paiement de {payment_amount} reçu',
 '{"payment_amount": "decimal", "customer_name": "string", "invoice_id": "UUID", "payment_date": "date", "payment_method": "string"}'::jsonb),

('order_delivered', 'Commande livrée', 
 'Bonjour {customer_name},\n\nVotre commande #{order_id} a été livrée avec succès.\n\nDate de livraison : {delivery_date}\nAdresse de livraison : {delivery_address}\n\nMerci pour votre confiance.\n\nCordialement,\nLoliexpress',
 'Votre commande #{order_id} a été livrée',
 '{"customer_name": "string", "order_id": "UUID", "delivery_date": "date", "delivery_address": "string"}'::jsonb);

-- ============================================================================
-- 11. COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE public.document_attachments IS 'Stores metadata for documents attached to various entities (customers, expenses, etc.)';
COMMENT ON TABLE public.notification_queue IS 'Queue for managing notifications to be sent via email or push notifications';
COMMENT ON TABLE public.notification_templates IS 'Templates for different types of notifications with variable placeholders';
COMMENT ON FUNCTION public.notify_new_order() IS 'Triggers notification to depot staff when a new order is created';
COMMENT ON FUNCTION public.check_overdue_invoices() IS 'Scheduled function to check for overdue invoices and notify sales reps';
COMMENT ON FUNCTION public.check_low_stock() IS 'Scheduled function to check for low stock levels and notify admins';
COMMENT ON FUNCTION public.notify_payment_received() IS 'Triggers notification to admins when a payment is received';
COMMENT ON FUNCTION public.notify_order_delivered() IS 'Triggers notification to customers when their order is delivered';