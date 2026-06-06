# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview
This is a Flutter mobile ERP application (LoliExpress ERP) with a Supabase backend. The app targets Android/iOS with web support for development convenience.

### Development Environment
- **Flutter SDK**: Installed at `/opt/flutter` (stable channel; ensure `export PATH="/opt/flutter/bin:$PATH"`). Run `flutter config --enable-web` once per machine.
- **Web platform**: The `web/` directory is NOT committed (gitignored). Scaffold once per clone: `flutter create --platforms web .` before `flutter build web` or `flutter run -d chrome`.
- **Dependencies**: Managed via `pubspec.yaml`. Run `flutter pub get` to install.
- **Environment config**: `env.json` holds hosted Supabase credentials (`--dart-define-from-file=env.json`). For **local Supabase**, use a gitignored `env.local.json` with URL/keys from `supabase status` and `--dart-define-from-file=env.local.json`.
- **Supabase CLI**: Use the full release tarball (`supabase` + `supabase-go` in the same directory on `PATH`, e.g. `~/.local/share/supabase`). Docker required; on cloud VMs use `sudo service docker start` and often `sudo supabase start` / `sudo supabase status`.

### Key Commands
- **Install deps**: `flutter pub get`
- **Lint/Analyze**: `flutter analyze`
- **Run tests**: `flutter test`
- **Run app (web)**: `flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json`
- **Build web**: `flutter build web --dart-define-from-file=env.json`

### Architecture
- **Services** (`lib/services/`): Singleton services wrapping Supabase client (auth, products, orders, customers, inventory, documents, notifications, etc.)
- **Presentation** (`lib/presentation/`): 24 feature screens, each with a main file and `widgets/` subfolder
- **Theme** (`lib/theme/`): Material 3 light/dark themes with `ThemeService` for runtime toggle
- **Routes** (`lib/routes/`): Central named-route map in `app_routes.dart`

### Backend (Supabase)
- The app requires `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `env.json` to connect to a Supabase project.
- 10 migration files in `supabase/migrations/` define the full schema (RLS-protected).
- Authentication uses Supabase Auth (email/password). User roles stored in `user_profiles` table.
- To run locally: `supabase init && supabase start`, then apply migrations.

### Testing Notes
- Tests in `test/services/` test singleton instantiation (don't require Supabase).
- Widget tests use `GoogleFonts.config.allowRuntimeFetching = false` to avoid network calls.
- Full integration testing requires valid Supabase credentials in `env.json`.

### Deployment & Configuration

#### Disable Email Confirmation (Development)
In the Supabase Dashboard: **Auth → Providers → Email → Disable "Confirm email"**. This allows users to sign up without verifying their email address (useful for local dev/testing).

#### Configure SMTP for Production Emails
In the Supabase Dashboard: **Auth → SMTP Settings**. Configure your SMTP provider (e.g. Resend, Mailgun, SendGrid) for password reset and confirmation emails in production.

#### Build APK (Android Release)
```bash
flutter build apk --release --dart-define-from-file=env.json
```

#### Deploy Web
```bash
flutter build web --dart-define-from-file=env.json
```
Then host the `build/web/` directory on any static hosting (Vercel, Netlify, Firebase Hosting, etc.).

#### User Roles
The app supports 6 roles (defined in `lib/services/role_service.dart`):
| Role | Description |
|------|-------------|
| `admin` | Full access to all features, user management, and configuration |
| `salesRep` | Sales-focused: orders, customers, limited inventory view |
| `warehouseStaff` | Inventory management, stock receiving, warehouse operations |
| `comptable` | Finance-focused: expenses, purchases, receivables, financial reports |
| `acheteur` | Purchasing: supplier management, purchase orders |
| `customer` | External customer portal (limited self-service) |

To create users: use the Supabase Dashboard (Auth → Users) or the Supabase Auth REST API. The login screen does not currently have a registration/sign-up UI. Then set the role in the `user_profiles` table (`role` column).

### Remaining Warnings
- ~100 info-level lint issues remain (style suggestions, deprecated API usage, print statements). These are non-blocking.
- No CI/CD pipeline configured yet.

### Gotchas
- The `web/` directory is gitignored/not committed. Run `flutter create --platforms web .` to scaffold it before `flutter build web` or `flutter run -d chrome`.
- The hosted Supabase instance has email confirmation enabled by default. Disable it in the Dashboard for dev/test or create pre-confirmed users via the Admin API.
- `flutter run -d chrome` requires a display/headless Chrome. For CI or headless environments, use `flutter build web` + a static server instead.
