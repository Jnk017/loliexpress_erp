-- Password reset now uses Supabase Auth email OTP directly.
DROP TABLE IF EXISTS public.password_reset_otps;
