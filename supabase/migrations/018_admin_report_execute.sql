-- The Flutter admin dashboard calls this RPC with an authenticated session.
-- The SECURITY DEFINER function already rejects callers unless is_admin()
-- confirms an active administrator in user_profiles.
GRANT EXECUTE ON FUNCTION public.get_admin_total_report(timestamptz, timestamptz)
TO authenticated;
