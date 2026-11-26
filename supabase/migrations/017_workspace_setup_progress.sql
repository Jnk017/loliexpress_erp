-- P1.b.2 — progression issue des données et limitée au rôle courant.
BEGIN;
CREATE OR REPLACE FUNCTION public.get_workspace_setup_progress()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $workspace$
DECLARE
    actor uuid := auth.uid();
    actor_role text := public.current_user_role();
    company_ready boolean;
BEGIN
    SELECT company_name IS NOT NULL AND company_address IS NOT NULL
    INTO company_ready FROM public.company_settings WHERE singleton;
    CASE actor_role
        WHEN 'sales_rep' THEN
            RETURN jsonb_build_object(
                'assigned_customer',EXISTS (SELECT 1 FROM public.customers WHERE commercial_id = actor AND is_active),
                'first_order',EXISTS (SELECT 1 FROM public.sales_orders WHERE sales_rep_id = actor));
        WHEN 'comptable' THEN
            RETURN jsonb_build_object('company_profile',coalesce(company_ready,false),
                'first_invoice',EXISTS (SELECT 1 FROM public.invoices),
                'first_payment',EXISTS (SELECT 1 FROM public.payments));
        WHEN 'acheteur' THEN
            RETURN jsonb_build_object('first_supplier',EXISTS (SELECT 1 FROM public.suppliers WHERE is_active),
                'first_purchase',EXISTS (SELECT 1 FROM public.purchases WHERE created_by = actor));
        WHEN 'admin' THEN
            RETURN jsonb_build_object('company_profile',coalesce(company_ready,false),
                'first_product',EXISTS (SELECT 1 FROM public.products WHERE is_active),
                'first_invoice',EXISTS (SELECT 1 FROM public.invoices));
        ELSE
            RAISE EXCEPTION 'Workspace setup unavailable' USING ERRCODE = '42501';
    END CASE;
END;
$workspace$;
REVOKE ALL ON FUNCTION public.get_workspace_setup_progress() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_workspace_setup_progress() TO authenticated;
COMMIT;
