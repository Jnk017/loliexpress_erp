-- Clean bootstrap 016: extensions and Vault-backed auth headers, no jobs and no URLs.
CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
CREATE OR REPLACE FUNCTION public.edge_function_auth_headers() RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path=public,vault AS $$ SELECT jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||COALESCE((SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name='service_role_key' LIMIT 1),'')) $$;
REVOKE ALL ON FUNCTION public.edge_function_auth_headers() FROM PUBLIC,anon,authenticated;
