# Historique exclu du bootstrap propre

Le bundle n’exécute aucun fichier de `supabase/migrations/` historique. Il remplace cet historique uniquement pour les **nouveaux projets vierges**.

- `20251201005123_loliexpress_erp_schema.sql` : comptes Auth et données métier de démonstration avec mots de passe connus.
- `20251219180550` à `20251219201205` : blocs de télémétrie, sécurité, forensic et investigations fictifs.
- `20260531235000_schedule_edge_functions.sql` : ancienne URL de projet codée en dur.
- `20260601014700_final_admin_ai_reporting.sql` : ancien schéma `exchange_rates` et ancien retour `current_user_role()`.
- `20260601023900_update_initial_admin_email.sql` : email personnel codé en dur.
- `20260601034100_password_reset_otp.sql` et `20260601054300_drop_custom_password_reset_otps.sql` : création/suppression sans effet final.
- `supabase/seed.sql` : catalogue et stock de développement.

Ne mélangez jamais l’historique historique et `clean_migrations/` sur la même base.
