# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview
This is a Flutter mobile ERP application (LoliExpress ERP) with a Supabase backend. The app targets Android/iOS with web support added for development convenience.

### Development Environment
- **Flutter SDK**: Installed at `/opt/flutter` (v3.29.3, Dart 3.7.2). Path is set in `~/.bashrc`.
- **Web platform**: Enabled via `flutter config --enable-web`. The `web/` directory was created with `flutter create --platforms web .`
- **Dependencies**: Managed via `pubspec.yaml`. Run `flutter pub get` to install.
- **Environment config**: `env.json` at project root contains Supabase credentials and API keys. Passed to app via `--dart-define-from-file=env.json`.

### Key Commands
- **Install deps**: `flutter pub get`
- **Lint/Analyze**: `flutter analyze`
- **Run tests**: `flutter test`
- **Run app (web)**: `flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json`
- **Build web**: `flutter build web --dart-define-from-file=env.json`

### Known Issues (pre-existing in codebase)
- `lib/theme/app_theme.dart` uses `AppBarThemeData` and `InputDecorationThemeData` which are not valid Flutter API names (should be `AppBarTheme` and `InputDecorationTheme`). This causes compilation failures.
- `lib/presentation/incident_investigation_workspace/incident_investigation_workspace.dart` references `RealtimeChannel` which is not resolved (undefined class).
- Multiple widgets use `initialValue` parameter on `DropdownButtonFormField` which doesn't exist in this Flutter version (should use `value`).
- These errors prevent `flutter build`, `flutter run`, and `flutter test` from completing successfully. `flutter analyze` runs but reports these errors.

### Backend (Supabase)
- No `supabase/config.toml` exists; only migration SQL files in `supabase/migrations/`.
- The app requires `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `env.json` to connect to a Supabase project.
- To run a local Supabase instance, you would need to `supabase init` and `supabase start`, then apply the 10 migration files.

### Notes
- No test infrastructure exists beyond the default `test/widget_test.dart` (which references `const MyApp()` but `MyApp` is not const-constructible).
- No CI/CD, Makefile, Docker, or devcontainer configuration exists.
- No git hooks or pre-commit configuration.
