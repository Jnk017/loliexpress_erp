# Supabase local development

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
