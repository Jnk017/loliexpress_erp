-- Edge Function URLs must follow the current Supabase project, not a project id
-- embedded in migration history. Store the project URL in Vault as `supabase_url`.

CREATE OR REPLACE FUNCTION public.edge_function_url(p_function_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public, vault
AS $$
DECLARE
    v_base_url TEXT;
BEGIN
    SELECT decrypted_secret
    INTO v_base_url
    FROM vault.decrypted_secrets
    WHERE name = 'supabase_url'
    LIMIT 1;

    IF NULLIF(btrim(v_base_url), '') IS NULL THEN
        RAISE EXCEPTION 'Vault secret supabase_url is not configured';
    END IF;
    IF p_function_name !~ '^[a-z0-9_-]+$' THEN
        RAISE EXCEPTION 'Invalid Edge Function name';
    END IF;

    RETURN rtrim(v_base_url, '/') || '/functions/v1/' || p_function_name;
END;
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
            url := public.edge_function_url('send-email-notification'),
            headers := public.edge_function_auth_headers(),
            body := jsonb_build_object('notification_id', NEW.id)
        );
    END IF;
    RETURN NEW;
END;
$$;

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
    $$SELECT net.http_post(
        url := public.edge_function_url('forensic-export'),
        headers := public.edge_function_auth_headers(),
        body := '{}'::jsonb
    );$$
);
SELECT cron.schedule(
    'invoice-reminder-daily',
    '0 8 * * *',
    $$SELECT net.http_post(
        url := public.edge_function_url('invoice-reminder'),
        headers := public.edge_function_auth_headers(),
        body := '{}'::jsonb
    );$$
);
SELECT cron.schedule(
    'stock-alert-hourly',
    '0 * * * *',
    $$SELECT net.http_post(
        url := public.edge_function_url('stock-alert'),
        headers := public.edge_function_auth_headers(),
        body := '{}'::jsonb
    );$$
);

REVOKE ALL ON FUNCTION public.edge_function_url(TEXT) FROM PUBLIC, anon, authenticated;
