-- ============================================================================
-- MIGRATION: Add purchases/suppliers system + dual currency + receivables aging
-- Applied: 2026-05-09
-- ============================================================================

-- Suppliers table
CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    contact_person TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    country TEXT DEFAULT 'RDC',
    payment_terms_days INTEGER DEFAULT 30,
    preferred_currency TEXT DEFAULT 'CDF' CHECK (preferred_currency IN ('CDF', 'USD')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Purchases table
CREATE TABLE IF NOT EXISTS public.purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_number TEXT UNIQUE,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
    purchase_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD')),
    exchange_rate DECIMAL(10,4) DEFAULT 1,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'received', 'partial', 'cancelled')),
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'partial')),
    notes TEXT,
    received_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Purchase items
CREATE TABLE IF NOT EXISTS public.purchase_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES public.purchases(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL,
    unit_cost DECIMAL(15,2) NOT NULL,
    total_cost DECIMAL(15,2) NOT NULL,
    received_quantity INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Add currency columns to existing tables
ALTER TABLE public.sales_orders ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD'));
ALTER TABLE public.sales_orders ADD COLUMN IF NOT EXISTS exchange_rate DECIMAL(10,4) DEFAULT 1;
ALTER TABLE public.sales_orders ADD COLUMN IF NOT EXISTS payment_type TEXT DEFAULT 'cash' CHECK (payment_type IN ('cash', 'credit'));
ALTER TABLE public.sales_orders ADD COLUMN IF NOT EXISTS due_date TIMESTAMPTZ;
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD'));
ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS exchange_rate DECIMAL(10,4) DEFAULT 1;
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD'));
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD'));
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'CDF' CHECK (currency IN ('CDF', 'USD'));

-- Receivables aging view (credit sales not fully paid)
CREATE OR REPLACE VIEW public.receivables_aging AS
SELECT 
    c.id as customer_id,
    c.company_name,
    c.contact_person,
    c.email,
    c.phone,
    so.id as order_id,
    so.order_number,
    so.total_amount,
    so.currency,
    so.payment_type,
    so.created_at as order_date,
    so.due_date,
    so.payment_status,
    EXTRACT(DAY FROM (NOW() - so.created_at)) as days_outstanding,
    CASE 
        WHEN EXTRACT(DAY FROM (NOW() - so.created_at)) <= 30 THEN '0-30 jours'
        WHEN EXTRACT(DAY FROM (NOW() - so.created_at)) <= 60 THEN '31-60 jours'
        WHEN EXTRACT(DAY FROM (NOW() - so.created_at)) <= 90 THEN '61-90 jours'
        ELSE '90+ jours'
    END as aging_bracket
FROM public.sales_orders so
JOIN public.customers c ON so.customer_id = c.id
WHERE so.payment_type = 'credit' 
  AND so.payment_status != 'paid';

-- RLS
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.purchase_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "suppliers_admin_all" ON public.suppliers FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "purchases_admin_all" ON public.purchases FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "purchase_items_admin_all" ON public.purchase_items FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE SEQUENCE IF NOT EXISTS purchase_number_seq START 1;
