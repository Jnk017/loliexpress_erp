# Environment configuration

Copy `env.json.example` to `env.json` and fill the Supabase values:

- `SUPABASE_URL`: Supabase project API URL.
- `SUPABASE_ANON_KEY`: publishable/anon client key used by Flutter.
- Optional AI/OAuth keys are left empty unless a feature needs them.

Do not commit `env.json`; it is ignored because it can point to live projects.

## OTP password reset

Password reset OTP is sent by Supabase Auth using the project Auth email provider. No Resend key is required for password reset.

The repository configures `[auth.email.template.magic_link]` with `supabase/templates/magic_link.html`, which uses `{{ .Token }}` instead of `{{ .ConfirmationURL }}`. Push `supabase/config.toml` with `supabase config push --project-ref <project-ref>` so hosted Supabase sends a 6-digit code instead of a magic link.
