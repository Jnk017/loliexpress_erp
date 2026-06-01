# Environment configuration

Copy `env.json.example` to `env.json` and fill the Supabase values:

- `SUPABASE_URL`: Supabase project API URL.
- `SUPABASE_ANON_KEY`: publishable/anon client key used by Flutter.
- Optional AI/OAuth keys are left empty unless a feature needs them.

Do not commit `env.json`; it is ignored because it can point to live projects.

## OTP password reset

The OTP reset Edge Function sends email through Resend. Configure these Supabase secrets before using password reset:

```bash
supabase secrets set RESEND_API_KEY=your_resend_api_key
supabase secrets set NOTIFICATION_FROM_EMAIL=noreply@your-domain.com
```

Without `RESEND_API_KEY`, the app shows a clear configuration error and no OTP is generated.
