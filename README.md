# LoliExpress ERP
## Current release status (25 November 2026)

**NO GO — partially verified.** See [current release audit](docs/gate_audit_2026-11-25.md) and [final verification](FINAL_VERIFICATION.md). The gate branch has 30 consolidated migrations (000–029), deployed only to the isolated Gate project. Production has a different migration history. Never blindly push the baseline to production. Flutter 3.35.7 is pinned in the Android Gate workflows; the older SDK note below is historical. Recorded web build and 18 tests refer to ad59a4d, not the final candidate. Android APK, full business UI journeys, fresh baseline, real email/notification dispatch and production reconciliation remain open. [Android handoff](MOBILE_HANDOFF.md) · [Go-live checklist](docs/pre_go_live_checklist.md) · [Runbook](docs/production_runbook.md) · [Permissions](docs/permissions_matrix.md) · [Monitoring](docs/monitoring_and_alerting.md).


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

[Current readiness state](audit/production_readiness/STATE.md) · [RPC security audit](audit/production_readiness/RPC_SECURITY_MATRIX.md) · [Local release gate](audit/production_readiness/run_release_gate.py)

- `docs/env.md`
- `docs/supabase_local.md`
- `docs/deployment.md`
- `docs/roles.md`
- `docs/ai_assistant.md`
