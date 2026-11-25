BEGIN;
SELECT set_config('request.jwt.claim.sub', id::text, true)
  FROM public.user_profiles WHERE role = 'comptable' AND is_active LIMIT 1;
DO $$
DECLARE
  notification_id uuid;
  original public.notification_queue%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Profil de test manquant'; END IF;
  INSERT INTO public.notification_queue
    (notification_type, recipient_id, recipient_email, channel, subject, message, status)
  VALUES ('low_stock', auth.uid(), 'test@loliexpress.test', 'push', 'Test', 'Test', 'pending')
  RETURNING * INTO original;
  notification_id := original.id;
  SET LOCAL ROLE authenticated;
  UPDATE public.notification_queue SET read_at = now()
    WHERE id = notification_id AND recipient_id = auth.uid() AND read_at IS NULL;
  IF NOT EXISTS (
    SELECT FROM public.notification_queue WHERE id = notification_id
      AND read_at IS NOT NULL AND status = original.status
      AND sent_at IS NOT DISTINCT FROM original.sent_at
  ) THEN RAISE EXCEPTION 'La lecture ne doit modifier ni statut ni date d’envoi'; END IF;
END
$$;
ROLLBACK;
SELECT true AS notification_read_pass;
