# Environment configuration

Copy `env.json.example` to `env.json` and fill the Supabase values:

- `SUPABASE_URL`: Supabase project API URL.
- `SUPABASE_ANON_KEY`: publishable/anon client key used by Flutter.
- Optional AI/OAuth keys are left empty unless a feature needs them.

Do not commit `env.json`; it is ignored because it can point to live projects.

## OTP password reset

Password reset OTP is sent by Supabase Auth using the project Auth email provider. No Resend key is required for password reset.

In Supabase Dashboard, configure Auth email templates so the OTP template includes `{{ .Token }}`. The app verifies that token with Supabase Auth, then lets the user set a new password.
