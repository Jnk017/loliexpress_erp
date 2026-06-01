# LoliExpress ERP

Flutter mobile/web ERP for LoliExpress with a Supabase backend. The app covers sales, customers, stock, purchases, expenses, documents, reporting, notifications, audit, security monitoring and a B2B customer portal.

## Stack

- Flutter 3.29.x / Dart 3.7.x
- Supabase Auth, Postgres, RLS, Storage, Realtime and Edge Functions
- Material 3, Sizer, Riverpod for new typed repository flows

## Setup

```bash
cp env.json.example env.json
flutter pub get
```

Fill `env.json` with your Supabase project values, then run:

```bash
flutter run --dart-define-from-file=env.json
```

For web development, scaffold web support first because `web/` is intentionally not committed:

```bash
flutter create --platforms web .
flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json
```

## Quality checks

```bash
flutter analyze
flutter test
```

## Supabase

Local development:

```bash
supabase start
supabase db reset
```

Migrations live in `supabase/migrations/`, seed data lives in `supabase/seed.sql`, and Edge Functions live in `supabase/functions/`.

## Documentation

- `docs/env.md`
- `docs/supabase_local.md`
- `docs/deployment.md`
- `docs/roles.md`
