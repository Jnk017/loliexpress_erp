ALTER TABLE public.notification_queue ADD COLUMN read_at timestamptz;

-- Legacy sent_at mixes delivery and reading, so it cannot backfill read_at.
CREATE OR REPLACE FUNCTION public.invoke_send_email_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  project_url text;
  headers jsonb;
BEGIN
  IF NEW.status IS DISTINCT FROM 'pending' OR NEW.channel NOT IN ('email', 'both') THEN
    RETURN NEW;
  END IF;

  SELECT rtrim(btrim(decrypted_secret), '/') INTO project_url
    FROM vault.decrypted_secrets
    WHERE name = 'supabase_url'
    ORDER BY created_at DESC LIMIT 1;
  headers := public.edge_function_auth_headers();
  -- Keep the notification pending when deployment has no mail configuration.
  IF project_url IS NULL OR project_url !~ '^https://[a-z0-9]+[.]supabase[.]co$'
     OR COALESCE(btrim(headers->>'Authorization'), '') IN ('', 'Bearer') THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := project_url || '/functions/v1/send-email-notification',
    headers := headers,
    body := jsonb_build_object('notification_id', NEW.id)
  );
  RETURN NEW;
END;
$$;
