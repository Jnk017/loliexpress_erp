-- Clean bootstrap 008: forensic analysis schema only.
CREATE TABLE IF NOT EXISTS public.forensic_events(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),event_type text NOT NULL,user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,ip_address inet,user_agent text,device_fingerprint text,payload jsonb NOT NULL DEFAULT '{}'::jsonb,occurred_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.ip_geolocation_cache(ip_address inet PRIMARY KEY,country_code text,country_name text,region text,city text,latitude numeric,longitude numeric,timezone text,isp text,is_proxy boolean NOT NULL DEFAULT false,threat_level text,updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.device_fingerprints(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),fingerprint_hash text NOT NULL UNIQUE,user_agent text,device_type text,browser_name text,os_name text,is_mobile boolean,first_seen_at timestamptz NOT NULL DEFAULT now(),last_seen_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.forensic_events ENABLE ROW LEVEL SECURITY; ALTER TABLE public.ip_geolocation_cache ENABLE ROW LEVEL SECURITY; ALTER TABLE public.device_fingerprints ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS forensic_admin ON public.forensic_events;
CREATE POLICY forensic_admin ON public.forensic_events FOR SELECT TO authenticated USING(public.is_admin()); DROP POLICY IF EXISTS geo_admin ON public.ip_geolocation_cache;
CREATE POLICY geo_admin ON public.ip_geolocation_cache FOR SELECT TO authenticated USING(public.is_admin()); DROP POLICY IF EXISTS fingerprints_admin ON public.device_fingerprints;
CREATE POLICY fingerprints_admin ON public.device_fingerprints FOR SELECT TO authenticated USING(public.is_admin());
