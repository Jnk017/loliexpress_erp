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

Password reset OTP uses Supabase Auth email OTP directly. The repository template `supabase/templates/magic_link.html` includes `{{ .Token }}` so Supabase sends a 6-digit code instead of a magic link. Push config with:

```bash
supabase config push --project-ref <project-ref>
```

For the first production admin, set `BOOTSTRAP_ADMIN_SECRET` and call `bootstrap_admin` once with `x-bootstrap-secret`; it refuses to run when an admin already exists.
