-- Flutter reads the ledgers through finance RLS. Every balance or movement
-- change must go through the authorised, atomic posting functions.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER
  ON public.cash_registers, public.bank_accounts,
     public.cash_movements, public.bank_transactions
  FROM PUBLIC, anon, authenticated;
