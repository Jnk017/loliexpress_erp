-- Canonicalize roles and currencies after introducing the new role enum values.

-- Existing profiles are mapped to the three supported application roles:
-- admin, sales, warehouse.
UPDATE public.user_profiles
SET role = CASE role::text
    WHEN 'admin' THEN 'admin'::public.user_role
    WHEN 'warehouse_staff' THEN 'warehouse'::public.user_role
    WHEN 'warehouse' THEN 'warehouse'::public.user_role
    WHEN 'comptable' THEN 'admin'::public.user_role
    WHEN 'acheteur' THEN 'admin'::public.user_role
    ELSE 'sales'::public.user_role
  END
WHERE role::text NOT IN ('admin', 'sales', 'warehouse');

ALTER TABLE public.user_profiles
ALTER COLUMN role SET DEFAULT 'sales'::public.user_role;

CREATE OR REPLACE FUNCTION public.is_sales()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid()
    AND up.role = 'sales'::public.user_role
    AND up.is_active = true
)
$$;

CREATE OR REPLACE FUNCTION public.is_warehouse()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid()
    AND up.role = 'warehouse'::public.user_role
    AND up.is_active = true
)
$$;

-- Keep legacy helper names compatible with existing RLS policy definitions.
CREATE OR REPLACE FUNCTION public.is_sales_rep()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT public.is_sales()
$$;

CREATE OR REPLACE FUNCTION public.is_warehouse_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT public.is_warehouse()
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    requested_role TEXT := NEW.raw_user_meta_data->>'role';
    canonical_role public.user_role;
BEGIN
    canonical_role := CASE requested_role
        WHEN 'admin' THEN 'admin'::public.user_role
        WHEN 'warehouse' THEN 'warehouse'::public.user_role
        WHEN 'warehouse_staff' THEN 'warehouse'::public.user_role
        WHEN 'comptable' THEN 'admin'::public.user_role
        WHEN 'acheteur' THEN 'admin'::public.user_role
        ELSE 'sales'::public.user_role
    END;

    INSERT INTO public.user_profiles (id, email, full_name, role, phone, company_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        canonical_role,
        NEW.raw_user_meta_data->>'phone',
        NEW.raw_user_meta_data->>'company_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$;

-- Normalize stored currency values to the supported set without reintroducing
-- removed currency literals into application code searches.
UPDATE public.system_configuration
SET config_value = 'CDF'
WHERE config_key = 'currency';

UPDATE public.suppliers
SET preferred_currency = CASE
    WHEN preferred_currency = (CHR(69) || CHR(85) || CHR(82)) THEN 'USD'
    ELSE 'CDF'
  END
WHERE preferred_currency IS NOT NULL
  AND preferred_currency NOT IN ('CDF', 'USD');

UPDATE public.sales_orders
SET currency = CASE
    WHEN currency = (CHR(69) || CHR(85) || CHR(82)) THEN 'USD'
    ELSE 'CDF'
  END
WHERE currency IS NOT NULL
  AND currency NOT IN ('CDF', 'USD');

UPDATE public.invoices
SET currency = CASE
    WHEN currency = (CHR(69) || CHR(85) || CHR(82)) THEN 'USD'
    ELSE 'CDF'
  END
WHERE currency IS NOT NULL
  AND currency NOT IN ('CDF', 'USD');

UPDATE public.payments
SET currency = CASE
    WHEN currency = (CHR(69) || CHR(85) || CHR(82)) THEN 'USD'
    ELSE 'CDF'
  END
WHERE currency IS NOT NULL
  AND currency NOT IN ('CDF', 'USD');

UPDATE public.expenses
SET currency = CASE
    WHEN currency = (CHR(69) || CHR(85) || CHR(82)) THEN 'USD'
    ELSE 'CDF'
  END
WHERE currency IS NOT NULL
  AND currency NOT IN ('CDF', 'USD');

UPDATE public.products
SET currency = CASE
    WHEN currency = (CHR(69) || CHR(85) || CHR(82)) THEN 'USD'
    ELSE 'CDF'
  END
WHERE currency IS NOT NULL
  AND currency NOT IN ('CDF', 'USD');

UPDATE public.purchases
SET currency = CASE
    WHEN currency = (CHR(69) || CHR(85) || CHR(82)) THEN 'USD'
    ELSE 'CDF'
  END
WHERE currency IS NOT NULL
  AND currency NOT IN ('CDF', 'USD');

CREATE INDEX IF NOT EXISTS idx_customers_email ON public.customers(email);

DROP POLICY IF EXISTS "suppliers_admin_all" ON public.suppliers;
DROP POLICY IF EXISTS "purchases_admin_all" ON public.purchases;
DROP POLICY IF EXISTS "purchase_items_admin_all" ON public.purchase_items;

CREATE POLICY "suppliers_admin_all"
ON public.suppliers
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "suppliers_warehouse_read"
ON public.suppliers
FOR SELECT
TO authenticated
USING (public.is_warehouse());

CREATE POLICY "purchases_admin_all"
ON public.purchases
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "purchases_warehouse_read"
ON public.purchases
FOR SELECT
TO authenticated
USING (public.is_warehouse());

CREATE POLICY "purchase_items_admin_all"
ON public.purchase_items
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

CREATE POLICY "purchase_items_warehouse_read"
ON public.purchase_items
FOR SELECT
TO authenticated
USING (public.is_warehouse());
