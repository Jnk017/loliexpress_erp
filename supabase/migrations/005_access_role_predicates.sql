-- P0.b — utiliser le rôle interne et rendre exécutables les prédicats RLS.

BEGIN;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $predicate$
    SELECT coalesce(public.current_user_role() = 'admin', false)
$predicate$;

CREATE OR REPLACE FUNCTION public.is_sales_rep()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $predicate$
    SELECT coalesce(public.current_user_role() = 'sales_rep', false)
$predicate$;

CREATE OR REPLACE FUNCTION public.is_warehouse_staff()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $predicate$
    SELECT coalesce(public.current_user_role() = 'warehouse_staff', false)
$predicate$;

CREATE OR REPLACE FUNCTION public.is_b2b_customer()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $predicate$
    SELECT coalesce(public.current_user_role() = 'b2b_customer', false)
$predicate$;

CREATE OR REPLACE FUNCTION public.is_comptable()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $predicate$
    SELECT coalesce(public.current_user_role() = 'comptable', false)
$predicate$;

CREATE OR REPLACE FUNCTION public.is_acheteur()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $predicate$
    SELECT coalesce(public.current_user_role() = 'acheteur', false)
$predicate$;

CREATE OR REPLACE FUNCTION public.is_delivery_agent()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $predicate$
    SELECT coalesce(public.current_user_role() = 'delivery_agent', false)
$predicate$;

CREATE OR REPLACE FUNCTION public.is_admin_from_auth()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $predicate$
    SELECT coalesce(public.current_user_role() = 'admin', false)
$predicate$;

CREATE OR REPLACE FUNCTION public.is_system_admin()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $predicate$
    SELECT coalesce(public.current_user_role() = 'admin', false)
$predicate$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

REVOKE ALL ON FUNCTION public.is_sales_rep() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_sales_rep() TO authenticated;

REVOKE ALL ON FUNCTION public.is_warehouse_staff() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_warehouse_staff() TO authenticated;

REVOKE ALL ON FUNCTION public.is_b2b_customer() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_b2b_customer() TO authenticated;

REVOKE ALL ON FUNCTION public.is_comptable() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_comptable() TO authenticated;

REVOKE ALL ON FUNCTION public.is_acheteur() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_acheteur() TO authenticated;

REVOKE ALL ON FUNCTION public.is_delivery_agent() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_delivery_agent() TO authenticated;

REVOKE ALL ON FUNCTION public.is_admin_from_auth() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_admin_from_auth() TO authenticated;

REVOKE ALL ON FUNCTION public.is_system_admin() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_system_admin() TO authenticated;

REVOKE ALL ON FUNCTION public.can_read_finance() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.can_read_finance() TO authenticated;

REVOKE ALL ON FUNCTION public.can_read_procurement() FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.can_read_procurement() TO authenticated;

COMMIT;
