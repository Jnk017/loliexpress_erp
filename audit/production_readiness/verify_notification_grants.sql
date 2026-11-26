BEGIN;
SELECT set_config('request.jwt.claim.sub', id::text, true)
  FROM public.user_profiles WHERE role = 'comptable' AND is_active LIMIT 1;
SET LOCAL ROLE authenticated;
DO $$
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Profil de test manquant'; END IF;
  IF has_column_privilege('public.notification_queue', 'status', 'UPDATE')
      OR has_column_privilege('public.notification_queue', 'sent_at', 'UPDATE')
      OR has_column_privilege('public.notification_queue', 'recipient_email', 'UPDATE')
      OR NOT has_column_privilege('public.notification_queue', 'read_at', 'UPDATE') THEN
    RAISE EXCEPTION 'Droits de modification trop larges';
  END IF;
  BEGIN
    INSERT INTO public.notification_queue
      (notification_type, recipient_id, recipient_email, channel, subject, message, status)
    VALUES ('low_stock', auth.uid(), 'gate-check@example.invalid', 'push', 'Test', 'Test', 'pending');
    RAISE EXCEPTION 'Création autorisée pour un rôle non administratif';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  IF has_table_privilege('anon','public.notification_queue','SELECT') THEN
    RAISE EXCEPTION 'Lecture anonyme autorisée';
  END IF;
END
$$;
ROLLBACK;
SELECT true AS notification_grants_pass;
