-- Schedule Edge Functions through Supabase Cron/pg_net.
-- Store the service role key in Vault as `service_role_key` before relying on
-- these jobs in production.

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.edge_function_auth_headers()
RETURNS JSONB
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, vault
AS $$
    SELECT jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(
            (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'service_role_key' LIMIT 1),
            ''
        )
    )
$$;

CREATE OR REPLACE FUNCTION public.invoke_send_email_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
    IF NEW.status = 'pending' AND NEW.channel IN ('email', 'both') THEN
        PERFORM net.http_post(
            url := 'https://lvzdlmojjoqrwxwluvih.supabase.co/functions/v1/send-email-notification',
            headers := public.edge_function_auth_headers(),
            body := jsonb_build_object('notification_id', NEW.id)
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_invoke_send_email_notification ON public.notification_queue;
CREATE TRIGGER trigger_invoke_send_email_notification
    AFTER INSERT ON public.notification_queue
    FOR EACH ROW
    EXECUTE FUNCTION public.invoke_send_email_notification();

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'forensic-export-daily') THEN
        PERFORM cron.unschedule('forensic-export-daily');
    END IF;
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'invoice-reminder-daily') THEN
        PERFORM cron.unschedule('invoice-reminder-daily');
    END IF;
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'stock-alert-hourly') THEN
        PERFORM cron.unschedule('stock-alert-hourly');
    END IF;
END $$;

SELECT cron.schedule(
    'forensic-export-daily',
    '0 2 * * *',
    $$
    SELECT net.http_post(
        url := 'https://lvzdlmojjoqrwxwluvih.supabase.co/functions/v1/forensic-export',
        headers := public.edge_function_auth_headers(),
        body := '{}'::jsonb
    );
    $$
);

SELECT cron.schedule(
    'invoice-reminder-daily',
    '0 8 * * *',
    $$
    SELECT net.http_post(
        url := 'https://lvzdlmojjoqrwxwluvih.supabase.co/functions/v1/invoice-reminder',
        headers := public.edge_function_auth_headers(),
        body := '{}'::jsonb
    );
    $$
);

SELECT cron.schedule(
    'stock-alert-hourly',
    '0 * * * *',
    $$
    SELECT net.http_post(
        url := 'https://lvzdlmojjoqrwxwluvih.supabase.co/functions/v1/stock-alert',
        headers := public.edge_function_auth_headers(),
        body := '{}'::jsonb
    );
    $$
);
