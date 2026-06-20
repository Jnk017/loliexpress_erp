-- Clean bootstrap 012: accounting and purchasing roles; no enum mutation.
INSERT INTO public.roles(name,display_name,description,sector,is_system,permissions) VALUES
('comptable','Comptable','Gestion financière et comptable','accounting',true,'{"finance":"manage","reports":"read"}'),
('acheteur','Acheteur','Gestion des fournisseurs et achats','purchasing',true,'{"suppliers":"manage","purchases":"manage"}')
ON CONFLICT(name) DO UPDATE SET display_name=EXCLUDED.display_name,sector=EXCLUDED.sector,is_system=true;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS requested_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS approved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS approved_at timestamptz;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS paid_by uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE public.expenses ADD COLUMN IF NOT EXISTS paid_at timestamptz;
CREATE TABLE IF NOT EXISTS public.expense_approval_history(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),expense_id uuid NOT NULL REFERENCES public.expenses(id) ON DELETE CASCADE,from_status text,to_status text NOT NULL,performed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,notes text,created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.expense_approval_history ENABLE ROW LEVEL SECURITY;
