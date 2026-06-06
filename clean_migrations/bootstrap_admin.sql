-- This script never creates auth users and intentionally contains no credentials.
-- Deploy supabase/functions/bootstrap_admin, configure BOOTSTRAP_ADMIN_SECRET and
-- invoke it once through HTTPS with x-bootstrap-secret. The function sends an
-- invitation and calls provision_invited_user_profile(..., 'admin', ...).
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.roles WHERE name='admin' AND is_system) THEN
    RAISE EXCEPTION 'System admin role is missing; apply migrations first';
  END IF;
  IF COALESCE((SELECT config_value FROM public.system_configuration WHERE config_key='bootstrap_admin_enabled'),'false'::jsonb) <> 'true'::jsonb THEN
    RAISE NOTICE 'Bootstrap is already disabled. No database change was made.';
  ELSE
    RAISE NOTICE 'Database is ready. Invoke the bootstrap_admin Edge Function; do not create auth.users from SQL.';
  END IF;
END $$;
