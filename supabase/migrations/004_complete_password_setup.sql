-- P0.a — restaurer le contrat de finalisation après l'inscription Auth.
BEGIN;
ALTER TABLE public.user_profiles
    ADD COLUMN IF NOT EXISTS must_change_password boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $fn$
    SELECT role::text FROM public.user_profiles
    WHERE id = auth.uid() AND is_active AND NOT must_change_password
$fn$;

CREATE OR REPLACE FUNCTION public.prevent_profile_privilege_escalation()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = ''
AS $fn$
BEGIN
    IF current_user IN ('anon', 'authenticated') AND
        (NEW.role IS DISTINCT FROM OLD.role OR NEW.is_active IS DISTINCT FROM OLD.is_active
         OR NEW.must_change_password IS DISTINCT FROM OLD.must_change_password) THEN
        RAISE EXCEPTION 'Use the authorized account management endpoint' USING ERRCODE = '42501';
    END IF;
    RETURN NEW;
END;
$fn$;

CREATE OR REPLACE FUNCTION public.complete_password_setup()
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
BEGIN
    IF auth.uid() IS NULL OR NOT EXISTS (
        SELECT 1 FROM auth.users
        WHERE id = auth.uid() AND nullif(encrypted_password, '') IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'An Auth password is required' USING ERRCODE = '42501';
    END IF;
    UPDATE public.user_profiles SET must_change_password = false
    WHERE id = auth.uid() AND is_active;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active profile required' USING ERRCODE = '42501';
    END IF;
    RETURN true;
END;
$fn$;
REVOKE ALL ON FUNCTION public.complete_password_setup() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_password_setup() TO authenticated;
COMMIT;
