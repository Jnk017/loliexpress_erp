# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview
This is a Flutter mobile ERP application (LoliExpress ERP) with a Supabase backend. The app targets Android/iOS with web support for development convenience.

### Development Environment
- **Flutter SDK**: Installed at `/opt/flutter` (v3.29.3, Dart 3.7.2). Path is set in `~/.bashrc`.
- **Web platform**: Enabled via `flutter config --enable-web`. The `web/` directory exists for browser testing.
- **Dependencies**: Managed via `pubspec.yaml`. Run `flutter pub get` to install.
- **Environment config**: `env.json` at project root contains Supabase credentials and API keys. Passed to app via `--dart-define-from-file=env.json`.

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

### Remaining Warnings
- ~15 warnings remain (unused fields/variables in pre-existing security/audit/invoice code). These are non-blocking.
- No CI/CD pipeline configured yet.
