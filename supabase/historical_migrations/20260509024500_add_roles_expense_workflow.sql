-- ============================================================================
-- MIGRATION: Add accountant + buyer roles, expense approval workflow
-- Applied: 2026-05-09
-- ============================================================================

-- Add new roles
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'comptable';
ALTER TYPE public.user_role ADD VALUE IF NOT EXISTS 'acheteur';

-- Expense approval workflow columns
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected', 'pending_payment', 'paid', 'executed'));
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS requested_by UUID REFERENCES auth.users(id);
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id);
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS paid_by UUID REFERENCES auth.users(id);
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS executed_at TIMESTAMPTZ;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS receipt_url TEXT;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS beneficiary TEXT;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS urgency TEXT DEFAULT 'normal' CHECK (urgency IN ('low', 'normal', 'high', 'urgent'));
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Purchases: track who created and who approved
ALTER TABLE public.purchases ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);
ALTER TABLE public.purchases ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id);
ALTER TABLE public.purchases ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;

-- Expense approval audit trail
CREATE TABLE IF NOT EXISTS public.expense_approval_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id UUID NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('submitted', 'approved', 'rejected', 'paid', 'executed')),
    performed_by UUID REFERENCES auth.users(id),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.expense_approval_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "expense_history_all" ON public.expense_approval_history FOR ALL TO authenticated USING (true) WITH CHECK (true);
