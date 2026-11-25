# Environment configuration

> **Current status — 2026-11-25:** Use only project-specific public URL/key in Flutter, never service-role, DB credentials, LLM secrets or dispatch keys. Verify OTP and invitation with real email; configuration alone is not evidence. [Current audit](gate_audit_2026-11-25.md).


Copy `env.json.example` to `env.json` and fill the Supabase values:

- `SUPABASE_URL`: Supabase project API URL.
- `SUPABASE_ANON_KEY`: publishable/anon client key used by Flutter.
- Optional AI/OAuth keys are left empty unless a feature needs them.

Do not commit `env.json`; it is ignored because it can point to live projects.

## OTP password reset

Password reset OTP is sent by Supabase Auth using the project Auth email provider. No Resend key is required for password reset.

The repository configures `[auth.email.template.magic_link]` with `supabase/templates/magic_link.html`, which uses `{{ .Token }}` instead of `{{ .ConfirmationURL }}`. Push `supabase/config.toml` with `supabase config push --project-ref <project-ref>` so hosted Supabase sends a 6-digit code instead of a magic link.
