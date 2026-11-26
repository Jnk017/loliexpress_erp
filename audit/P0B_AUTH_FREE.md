# P0.b — Auth sur Supabase Free

**DoD adaptée.** Source de reprise validée et restauration testable. Invitations, premier accès, RLS B2B, livreurs et documents contrôlés. Anciennes fonctions OTP auditées. Vérifier une politique minimale de mot de passe compatible Free. La protection native contre les mots de passe compromis, réservée à Pro et supérieur, est hors critère.

Le dépôt fixe un minimum de huit caractères dans la configuration Auth locale, aligné sur l'écran de premier accès. Le réglage du projet hébergé reste à contrôler au gate. [Documentation Supabase](https://supabase.com/docs/guides/auth/password-security)

Les fonctions de référence `create_user` et `bootstrap_admin` utilisent l'invitation Supabase Auth et écrivent `must_change_password` sur le profil. Au gate, vérifier sur une cible isolée qu'un invité ne peut accéder aux données métier avant la définition de son mot de passe, qu'un mot de passe trop court est rejeté, puis que la finalisation libère les accès autorisés.

## Anciennes fonctions OTP

| Fonction | Observation active | Recherche GitHub | Invocations sur la fenêtre lue |
|---|---|---|---|
| `request_password_reset_otp` | Active, version 3 | Aucun résultat | 0 |
| `verify_password_reset_otp` | Active, version 2 | Aucun résultat | 0 |

Fenêtre glissante de 24 heures au 23 novembre 2026, deux requêtes Edge visibles, agrégées par chemin sans exposer de données personnelles. Confirmer au gate le trajet de réinitialisation sur le build réellement distribué et consulter les journaux de la période disponible avant une éventuelle suppression des anciennes fonctions.
