CREATE TABLE IF NOT EXISTS public.password_reset_otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    otp_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_password_reset_otps_email_created
ON public.password_reset_otps (lower(email), created_at DESC);

CREATE INDEX IF NOT EXISTS idx_password_reset_otps_active
ON public.password_reset_otps (lower(email), expires_at)
WHERE consumed_at IS NULL;

ALTER TABLE public.password_reset_otps ENABLE ROW LEVEL SECURITY;

-- Edge Functions use the service role; no client-side RLS policy is needed.
DROP POLICY IF EXISTS "password_reset_otps_no_client_access" ON public.password_reset_otps;
