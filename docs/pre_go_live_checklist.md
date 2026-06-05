# Checklist avant mise en production

> Cette checklist doit être signée par le responsable technique et le responsable métier. Une case non cochée dans une section **bloquante** interdit le go-live.

## Validation de release — bloquant

- [ ] Le commit candidat est identifié et immuable.
- [ ] Le workflow GitHub Actions `LoliExpress ERP CI` est vert sur ce commit.
- [ ] `flutter pub get`, `flutter analyze` et `flutter test` sont verts.
- [ ] `supabase db reset`, `supabase db lint --local --level warning` et `supabase test db` sont verts.
- [ ] Les tests d’intégration Edge Functions locaux sont verts.
- [ ] Le build web release est vert.
- [ ] Une répétition générale a été effectuée dans un projet Supabase de staging restauré depuis une copie anonymisée de production.

## Supabase — bloquant

- [ ] `SUPABASE_URL` pointe vers le projet de production attendu.
- [ ] La clé anon/publishable de production est configurée côté application.
- [ ] La service-role key existe uniquement dans les secrets serveur/Edge Functions.
- [ ] Aucun secret réel n’est commité dans Git ou inclus dans un artefact Flutter/web.
- [ ] SMTP de production est configuré et un email d’invitation a été reçu et ouvert.
- [ ] `SITE_URL` correspond à l’URL publique canonique.
- [ ] `INVITE_REDIRECT_URL` correspond à une URL autorisée et ouvre l’écran de changement de mot de passe.
- [ ] Les URL mobiles/deep links iOS et Android sont autorisées si les applications mobiles sont distribuées.
- [ ] Les sauvegardes quotidiennes sont activées.
- [ ] Le Point-in-Time Recovery est activé si le RPO métier l’exige.
- [ ] Une restauration a été testée dans un projet isolé et le RTO mesuré.
- [ ] Les secrets Vault `service_role_key` et `supabase_url` sont configurés pour les jobs Edge.
- [ ] Les logs PostgreSQL/Auth/Edge Functions sont conservés selon la politique interne.
- [ ] Les log drains et alertes décrits dans `docs/monitoring_and_alerting.md` sont actifs.

## Sécurité et accès — bloquant

- [ ] `system_configuration.bootstrap_admin_enabled` vaut `false`.
- [ ] `BOOTSTRAP_ADMIN_SECRET` a été supprimé ou renouvelé après initialisation.
- [ ] Aucun compte de démonstration, compte partagé ou compte par défaut n’existe.
- [ ] Tous les administrateurs utilisent une identité nominative.
- [ ] Les comptes inactifs sont désactivés dans Auth et `user_profiles`.
- [ ] Les rôles des utilisateurs ont été revus par leur responsable.
- [ ] Les sept rôles ont passé les tests RLS de lecture et d’écriture.
- [ ] Un client B2B ne peut lire aucun client, commande, facture, paiement, livraison ou document d’un autre client.
- [ ] `cost_price` n’est pas accessible au rôle PostgreSQL `authenticated`.
- [ ] Les écritures directes sur commandes, mouvements de stock, paiements et confirmations de livraison sont refusées.
- [ ] Une invitation impose le changement de mot de passe avant tout accès métier.
- [ ] Les politiques de mot de passe, rotation de session et MFA ont été validées selon la politique de l’entreprise.

## ERP et données — bloquant

- [ ] Un taux USD/CDF actif et daté existe dans `exchange_rates` si les ventes USD sont autorisées.
- [ ] Le plafond de remise `sales_rep_max_discount_percent` est approuvé.
- [ ] L’inventaire physique est réconcilié avec `inventory_stock`.
- [ ] Le total signé de `stock_movements` correspond à chaque ligne `inventory_stock`.
- [ ] Les mouvements `migration_reconciliation` ont été contrôlés et approuvés.
- [ ] Les clients ont un `user_id` B2B correct et, si applicable, un `commercial_id` correct.
- [ ] Les commandes, factures et paiements migrés ont été réconciliés avec la comptabilité.
- [ ] Les documents ont été migrés dans le bucket privé et leurs métadonnées pointent vers la bonne entité.
- [ ] Les policies Storage ont été testées séparément des policies des métadonnées `document_attachments`.
- [ ] Les tournées et livraisons ouvertes ont un chauffeur et un statut cohérents.

## Edge Functions et emails — bloquant

- [ ] `create_user` refuse les mots de passe, les rôles inconnus et les utilisateurs non administrateurs.
- [ ] `create_user` écrit `user_created_by_admin` et supprime l’utilisateur si le profil ou l’audit échoue.
- [ ] `bootstrap_admin` refuse un secret invalide, ne fonctionne qu’une fois et journalise chaque tentative.
- [ ] Les fonctions ne journalisent ni JWT, ni clés, ni mots de passe, ni liens d’invitation.
- [ ] Les limites de débit Auth/email sont adaptées au volume interne prévu.

## Exploitation et métier

- [ ] Authentification : connexion, déconnexion, invitation, changement obligatoire et compte désactivé testés.
- [ ] Ventes : création mono/multi-produits, transition et annulation testées.
- [ ] Stock : entrée, sortie, correction, historique et refus du stock négatif testés.
- [ ] Livraison : affectation, visibilité chauffeur, confirmation et double confirmation testées.
- [ ] Paiement : partiel, complet, dépassement et historique testés.
- [ ] Portail B2B : isolation, commandes, factures, livraisons et téléchargement de documents testés.
- [ ] Le support connaît la procédure d’incident et les contacts d’escalade.
- [ ] Une fenêtre de déploiement, un plan de retour arrière et un responsable de décision sont définis.
