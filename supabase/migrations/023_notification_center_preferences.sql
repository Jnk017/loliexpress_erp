CREATE TABLE public.notification_center_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  hidden_types public.notification_type[] NOT NULL DEFAULT '{}',
  CONSTRAINT notification_center_hidden_types_valid
    CHECK (cardinality(hidden_types) <= 5 AND array_position(hidden_types, NULL) IS NULL)
);

ALTER TABLE public.notification_center_preferences ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.notification_center_preferences FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.notification_center_preferences TO authenticated;

CREATE POLICY notification_center_preferences_select
  ON public.notification_center_preferences FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY notification_center_preferences_insert
  ON public.notification_center_preferences FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY notification_center_preferences_update
  ON public.notification_center_preferences FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));
