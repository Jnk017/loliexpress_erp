# Changelog

## 2026-05-18

- Restrict displayed and persisted currencies to `CDF` and `USD`.
- Add Supabase migrations to normalize legacy currency values and canonicalize roles.
- Move application roles to `admin`, `sales`, and `warehouse` while keeping migration-time compatibility for legacy role values.
- Add a dedicated unauthorized page and tighten role-based navigation.
- Remove client-side private email provider key handling and stop tracking local `env.json`.
