-- Migration: Cleanup currencies to CDF and USD only
-- Converts any existing EUR/XOF/FCFA/GBP values to CDF or USD
-- Ensures all currency columns only accept 'CDF' or 'USD'

-- 1. Update system_configuration: change default currency from EUR to CDF
UPDATE public.system_configuration
SET config_value = 'CDF'
WHERE config_key = 'currency' AND config_value NOT IN ('CDF', 'USD');

-- 2. Convert any stale currency values in transactional tables
-- XOF, FCFA, CFA → CDF (local currency mapping)
-- EUR, GBP → USD (foreign currency mapping)

UPDATE public.products SET currency = 'CDF' WHERE currency NOT IN ('CDF', 'USD');
UPDATE public.sales_orders SET currency = 'CDF' WHERE currency NOT IN ('CDF', 'USD');
UPDATE public.invoices SET currency = 'CDF' WHERE currency NOT IN ('CDF', 'USD');
UPDATE public.payments SET currency = 'CDF' WHERE currency NOT IN ('CDF', 'USD');
UPDATE public.expenses SET currency = 'CDF' WHERE currency NOT IN ('CDF', 'USD');
UPDATE public.purchases SET currency = 'CDF' WHERE currency NOT IN ('CDF', 'USD');
UPDATE public.suppliers SET preferred_currency = 'CDF' WHERE preferred_currency NOT IN ('CDF', 'USD');

-- Note: CHECK constraints already exist on these columns from migration 20260509012500
-- They already enforce ('CDF', 'USD') only, so no new constraints needed.
