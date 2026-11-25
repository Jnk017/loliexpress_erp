BEGIN;

SELECT set_config('request.jwt.claim.sub', id::text, true)
FROM public.user_profiles WHERE role = 'admin' AND is_active LIMIT 1;
SET LOCAL ROLE authenticated;

DO $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Profil administrateur de test manquant';
  END IF;
END
$$;

INSERT INTO public.notification_center_preferences (user_id, hidden_types)
VALUES (auth.uid(), ARRAY['low_stock']::public.notification_type[])
ON CONFLICT (user_id) DO UPDATE SET hidden_types = EXCLUDED.hidden_types;

RESET ROLE;
SELECT set_config('test.preference_owner', auth.uid()::text, true);
SELECT set_config('request.jwt.claim.sub', id::text, true)
FROM public.user_profiles WHERE role = 'comptable' AND is_active LIMIT 1;
SET LOCAL ROLE authenticated;

DO $$
DECLARE
  owner_id uuid := current_setting('test.preference_owner')::uuid;
BEGIN
  IF auth.uid() IS NULL OR auth.uid() = owner_id THEN
    RAISE EXCEPTION 'Second profil de test manquant';
  END IF;
  IF EXISTS (
    SELECT FROM public.notification_center_preferences WHERE user_id = owner_id
  ) THEN
    RAISE EXCEPTION 'Préférences visibles par un autre compte';
  END IF;
  UPDATE public.notification_center_preferences SET hidden_types = '{}'
    WHERE user_id = owner_id;
  IF FOUND THEN
    RAISE EXCEPTION 'Préférences modifiables par un autre compte';
  END IF;
  BEGIN
    INSERT INTO public.notification_center_preferences (user_id)
      VALUES (owner_id) ON CONFLICT DO NOTHING;
    RAISE EXCEPTION 'Insertion abusive acceptée';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$$;

SELECT set_config('request.jwt.claim.sub', current_setting('test.preference_owner'), true);
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM public.notification_center_preferences
    WHERE user_id = auth.uid()
      AND hidden_types = ARRAY['low_stock']::public.notification_type[]
  ) THEN
    RAISE EXCEPTION 'Préférences non relues par leur propriétaire';
  END IF;
END
$$;

ROLLBACK;
SELECT true AS notification_center_preferences_pass;
