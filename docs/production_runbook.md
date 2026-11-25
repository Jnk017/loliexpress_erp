# Runbook de production LoliExpress ERP

> **Current status — 2026-11-25:** Before any production action: reconcile existing schema and migration history with 000–024, test forward-only migration on restored isolated copy, verify backup/rollback, obtain approval. Do not run db reset against production. Validate dispatch secrets and Edge inventory; bootstrap only if needed. [Current audit](gate_audit_2026-11-25.md).


## 1. Pré-déploiement

1. Exécuter `flutter analyze`, `flutter test`, `supabase db reset` puis `supabase test db`.
2. Vérifier les secrets Supabase : `SUPABASE_SERVICE_ROLE_KEY`, SMTP, `SITE_URL`, `INVITE_REDIRECT_URL`, et `BOOTSTRAP_ADMIN_SECRET` temporaire.
3. Configurer SMTP, les URL de redirection Auth, la rotation des refresh tokens et une politique de mot de passe forte.
4. Créer dans Vault les secrets `service_role_key` et `supabase_url` utilisés par les jobs cron Edge Functions.
5. Insérer un taux USD/CDF actif dans `exchange_rates`; ne jamais laisser le taux fourni par un client faire autorité.
6. Examiner `docs/permissions_matrix.md` avec les responsables métier.

## 2. Bootstrap initial

1. Déployer `bootstrap_admin`, définir un secret long et à usage unique, puis appeler une seule fois la fonction avec l’adresse de l’administrateur.
2. L’administrateur reçoit une invitation Supabase et choisit son mot de passe; aucun mot de passe temporaire ne transite par l’ERP.
3. Vérifier que `system_configuration.bootstrap_admin_enabled` vaut `false` après succès.
4. Supprimer `BOOTSTRAP_ADMIN_SECRET` des secrets du projet ou le faire tourner immédiatement.
5. Contrôler `security_events` pour toute tentative ultérieure. Une fonction désactivée répond HTTP 410.

## 3. Supervision

- Créer des alertes sur les erreurs 5xx et la latence des Edge Functions, les événements `bootstrap_admin_attempt`, les échecs Auth et les erreurs PostgreSQL des RPC critiques.
- Centraliser les logs structurés JSON de `create_user` et `bootstrap_admin`; ne jamais journaliser JWT, service-role key, mot de passe ou lien d’invitation.
- Alerter sur les remises refusées, écarts de prix, taux de change périmés, stock négatif refusé et transitions de statut invalides.
- Examiner périodiquement `audit_logs`, les utilisateurs inactifs et les politiques RLS avec `supabase db lint`.

## 4. Sauvegarde et restauration

- Activer les sauvegardes quotidiennes et, selon le plan Supabase, le Point-in-Time Recovery. Conserver une copie chiffrée hors projet selon la politique de rétention interne.
- Faire un export logique régulier avec `supabase db dump --linked -f backup.sql` et sauvegarder séparément la configuration Storage/Edge Functions et les secrets dans un coffre.
- Tester trimestriellement la restauration dans un projet isolé : restaurer le schéma, les données, les objets Storage, appliquer les migrations, puis exécuter les tests RLS/RPC.
- Après restauration, faire tourner toutes les clés, vérifier les webhooks/cron, réconcilier commandes-paiements-stock et documenter RPO/RTO réels.

## 5. Incident et rollback

1. Désactiver l’Edge Function ou révoquer son secret si elle est impliquée; ne pas contourner RLS avec la clé service-role depuis Flutter.
2. Préserver les journaux et l’heure UTC de début. Exporter les lignes `audit_logs`/`security_events` concernées.
3. Pour une migration, préférer une migration corrective avant uniquement. Restaurer un snapshot lorsque l’intégrité transactionnelle ne peut pas être garantie.
4. Après correction, rejouer les tests RPC/RLS et réconcilier les agrégats financiers avec les lignes source.

## 6. Contrôles périodiques

- Hebdomadaire : erreurs Edge Functions, invitations en attente, taux de change actif, tâches cron.
- Mensuel : revue des rôles, utilisateurs désactivés, remises, paiements et ajustements de stock.
- Trimestriel : restauration de sauvegarde, rotation des secrets, audit RLS et test du plan d’incident.
