# Deployment

## Frontend

```bash
flutter create --platforms web .
flutter build web --release --dart-define-from-file=env.json
```

Deploy `build/web/` to Vercel, Netlify, Firebase Hosting or any static host.

## Android

```bash
flutter build apk --release --dart-define-from-file=env.json
```

Configure release signing before production distribution.

## Supabase

Apply migrations to the target project, then deploy Edge Functions:

```bash
supabase db push
supabase functions deploy send-email-notification
supabase functions deploy track-failed-login
supabase functions deploy forensic-export
supabase functions deploy invoice-reminder
supabase functions deploy stock-alert
supabase functions deploy bootstrap_admin
supabase functions deploy create_user
supabase functions deploy ai_assistant
```

Set function secrets: `SUPABASE_SERVICE_ROLE_KEY`, `RESEND_API_KEY`, `NOTIFICATION_FROM_EMAIL`, and `AUTH_WEBHOOK_SECRET` for server-side admin actions and notification emails.

Password reset OTP uses Supabase Auth email OTP directly. Configure the Supabase Auth email OTP template to include `{{ .Token }}`; no Resend secret is required for password reset.

For the first production admin, set `BOOTSTRAP_ADMIN_SECRET` and call `bootstrap_admin` once with `x-bootstrap-secret`; it refuses to run when an admin already exists.
