# Supabase local development

> **Current status — 2026-11-25:** Consolidated migrations 000–024 only; historical_migrations is provenance, not a second replay path. Fresh baseline assertions immediately after 000, then 001–024 and all audit scripts. Use disposable local/authorized test project only. Do not repair production history blindly. [Current audit](gate_audit_2026-11-25.md).


Prerequisites: Supabase CLI and Docker.

```bash
supabase start
supabase db reset
```

`supabase/config.toml` loads `supabase/seed.sql` after migrations. Use Supabase Studio to create Auth users, then update `public.user_profiles.role` as an admin for development users.

Important tables:

- `user_profiles`: app profile and role source.
- `sales_orders`, `order_items`: sales flow.
- `inventory_stock`, `stock_movements`: stock on hand and movement ledger.
- `notification_queue`: notifications consumed by Edge Functions.
