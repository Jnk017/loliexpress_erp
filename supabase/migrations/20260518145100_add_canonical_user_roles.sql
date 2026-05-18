-- Add canonical operational roles used by the Flutter app.
-- Existing legacy enum values stay in place because PostgreSQL enum values
-- cannot be safely removed in a forward-only migration.
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'sales';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'warehouse';
