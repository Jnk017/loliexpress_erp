# Rapport de readiness production — Phase 2

**Date de l’évaluation :** 5 juin 2026  
**Commit de départ audité :** `a346dc5` — *Harden transactional ERP operations and production controls*  
**Conclusion :** **NOT READY FOR PRODUCTION**

## Résumé exécutif

La revue de la phase 1 a découvert plusieurs défauts de cohérence suffisamment importants pour bloquer un déploiement immédiat : clients Flutter continuant à écrire directement dans des tables verrouillées, confirmation de livraison incompatible avec le trigger de statut, exposition potentielle de `cost_price`, policies héritées trop permissives sur achats/livraisons/documents, absence de gate d’invitation lors d’une ouverture directe du lien et désynchronisation possible entre le stock initial et son journal de mouvements.

Ces défauts ont été corrigés dans une migration corrective et dans les services Flutter. Les tests SQL ont été étendus aux RPC et aux sept rôles, et la CI exécute désormais un vrai scénario HTTP des Edge Functions contre Supabase local.

Cependant, l’environnement d’exécution fourni pour cette revue ne contient ni Flutter, ni Supabase CLI, ni Docker/PostgreSQL, ni Deno. Les téléchargements GitHub, Google Storage, Docker Hub et les dépôts Ubuntu sont bloqués par le proxy HTTP 403. Il n’a donc pas été possible d’exécuter localement `supabase db reset`, les tests pgTAP, `flutter analyze`, `flutter test`, le build web ou les tests Edge réels. Tant qu’un run CI complet et vert n’existe pas sur le commit final, la release reste **non démontrée** et ne doit pas être déployée.

## Périmètre audité

- Ensemble des changements du commit de phase 1.
- Ordre et interactions des migrations Supabase.
- RPC commandes, stock, livraison et paiements.
- Policies RLS/RBAC et helpers historiques.
- Flux Flutter commandes, stock, livraison, authentification et catalogue.
- Edge Functions `create_user` et `bootstrap_admin`.
- Seeds, workflow GitHub Actions et tests ajoutés.
- Parcours B2B et documents associés aux factures/livraisons.

## Anomalies découvertes et corrections

| Sévérité initiale | Anomalie | Correction |
|---|---|---|
| Critique | Flutter affichait une taxe de 18 % et des remises de palier inventées côté client, alors que la RPC persistait taxe zéro et vérifiait le prix catalogue. | Prévisualisation alignée sur les règles réellement implémentées côté PostgreSQL ; aucune remise/taxe implicite côté client. |
| Critique | `InventoryService` insérait directement dans `stock_movements` alors que les privilèges avaient été révoqués. | Le service appelle `adjust_stock` et traduit entrée/sortie en delta signé. |
| Critique | `DeliveryService` mettait directement `deliveries.status='delivered'`, contournant rôle, affectation et audit. | Le service appelle exclusivement `confirm_delivery`. |
| Critique | `confirm_delivery` acceptait `confirmed`/`processing`, mais le trigger global refusait leur transition directe vers `delivered`. | Seules les commandes `shipped` peuvent être confirmées livrées. |
| Critique | Les policies héritées de `inventory_stock` autorisaient des écritures directes au dépôt. | Droits d’écriture révoqués ; lecture explicitement limitée. |
| Critique | `purchase_items_read USING (true)` exposait les coûts d’achat à tout utilisateur authentifié, y compris B2B. | Policies fournisseurs/achats/lignes d’achat reconstruites par rôles procurement. |
| Critique | La lecture de `products` exposait `cost_price`, car RLS ne filtre pas les colonnes. | Privilège SELECT table révoqué puis accordé seulement aux colonnes catalogue. |
| Élevé | Le chauffeur pouvait lire toutes les commandes/livraisons dans les nouvelles policies. | Helpers `SECURITY DEFINER` sans récursion RLS limitent client, commande et livraison à l’affectation réelle. |
| Moyen | Un échec RLS lors de la création des métadonnées laissait un objet Storage orphelin. | Compensation Flutter supprimant le fichier si l’insertion des métadonnées échoue. |
| Critique | Les métadonnées autorisaient un document B2B, mais Storage refusait le fichier si son owner était un administrateur. | Policies `storage.objects` alignées sur `document_attachments` via le chemin et l’entité autorisée. |
| Élevé | Les documents étaient lisibles par tous les rôles internes sans contrôle d’entité et les uploads pouvaient cibler une entité arbitraire. | `can_access_document_entity` contrôle client, facture, livraison, dépense et achat pour lecture/écriture. |
| Élevé | Une commande commerciale pouvait cibler un client non affecté. | Trigger serveur et policies limitent le commercial à ses clients/commandes. |
| Élevé | `sales_orders` restait directement modifiable, permettant de tenter une altération financière. | UPDATE direct révoqué ; transitions via `transition_order_status` auditée. |
| Élevé | Le changement obligatoire n’était déclenché que depuis le formulaire de login, pas depuis un lien d’invitation ouvrant une session. | Écran de gate dédié utilisé par le login et le splash. |
| Élevé | `must_change_password` pouvait être modifié directement et les anciens helpers de rôle ignoraient ce gate. | RPC `complete_password_setup`, trigger anti-contournement et remplacement de tous les helpers de rôle. |
| Élevé | Le seed écrivait du stock sans mouvement ; le premier mouvement recalculait alors le stock depuis un journal incomplet. | Réconciliation de migration pour l’existant et mouvement baseline dans le seed. |
| Moyen | Un échec d’audit Edge désactivait l’utilisateur mais ne le supprimait pas. | Suppression Auth/profil pour rollback compensatoire. |
| Moyen | Les échecs Edge étaient peu observables. | Logs JSON pour refus, invitation échouée, rollback et tentatives bootstrap. |
| Élevé | Les jobs cron contenaient l’URL d’un projet Supabase en dur. | URL résolue depuis le secret Vault `supabase_url` et jobs replanifiés. |
| Moyen | Les tests Edge ne validaient que deux fonctions pures. | Script HTTP couvrant bootstrap, invitation, refus, audit, journalisation et doublon contre Supabase local. |

## Résultats de validation

### Migrations Supabase

**État : non exécuté dans cet environnement.**

Contrôles statiques réussis :

- ordre chronologique des migrations vérifié ;
- délimiteurs PL/pgSQL équilibrés ;
- migration corrective ajoutée après la phase 1 ;
- seed aligné avec le ledger de stock ;
- workflow configuré pour exécuter `supabase start`, `supabase db reset`, `supabase db lint --local --level warning` et `supabase test db`.

Blocage : absence de Supabase CLI, Docker et PostgreSQL locaux ; installation impossible à cause du proxy 403.

### RPC critiques

**État : couverture automatisée écrite, exécution réelle en attente de CI.**

Le test pgTAP couvre désormais :

- `create_order_with_items` : mono-produit, multi-produits, numéro, montants, audit, produit absent, prix manipulé, remise excessive, taux invalide, client non affecté et rollback ;
- `adjust_stock` : entrée, sortie, correction, stock négatif, écriture directe et rôle interdit ;
- `confirm_delivery` : succès affecté, double confirmation, chauffeur non affecté, statut invalide, audit et écriture directe ;
- `record_payment` : partiel, complet, historique, dépassement, devise et rôle interdit ;
- `transition_order_status` et le gate du premier mot de passe.

### RLS/RBAC

**État : matrice et tests étendus, exécution réelle en attente de CI.**

Des identités simulées sont préparées pour `admin`, `sales_rep`, `warehouse_staff`, `comptable`, `acheteur`, `delivery_agent` et deux tenants `b2b_customer`. Les assertions couvrent les tables demandées et les dépendances sensibles `inventory_stock`, `suppliers`, `purchase_items`, `invoices` et `delivery_routes`.

Points renforcés :

- isolation B2B sur clients, commandes, lignes, factures, paiements, livraisons et documents ;
- restriction du chauffeur à sa tournée ;
- restriction commerciale aux clients affectés ;
- coûts produits et achats non exposés aux clients B2B ;
- refus des écritures directes critiques.

### Edge Functions

**État : syntaxe vérifiée ; intégration réelle en attente de CI.**

Le script d’intégration local ajouté couvre :

- premier bootstrap, secret invalide, second bootstrap désactivé et événements de sécurité ;
- configuration d’un mot de passe admin et finalisation du gate ;
- invitation valide, payload avec password, rôle interdit et appel non-admin ;
- présence de l’audit `user_created_by_admin` ;
- invitation dupliquée sans profil dupliqué.

Limite structurelle : une invitation email déjà remise ne peut pas être « désenvoyée ». Le rollback compensatoire supprime néanmoins l’identité Auth et rend le lien inutilisable si le profil ou l’audit échoue.

### Flutter

**État : non exécuté dans cet environnement.**

Corrections statiques réalisées :

- commandes, stock, statut de commande et livraison alignés sur les RPC ;
- écran obligatoire de définition du mot de passe accessible depuis login et splash ;
- compte désactivé déconnecté avant routage ;
- sélections produits explicites sans `cost_price` ;
- tests widgets/services ajoutés pour les gates et les contournements directs.

Commandes encore obligatoires avant release :

```bash
flutter pub get
flutter analyze
flutter test
flutter create --platforms web .
flutter build web --release --dart-define-from-file=env.json
```

### CI/CD

**État : configuration renforcée, run final non observé.**

Le workflow comporte : Flutter, Supabase reset/lint/pgTAP, tests Deno, intégration HTTP Edge Functions et build web. Le go-live reste bloqué tant que ces trois jobs ne sont pas verts sur le commit final.

## Tests métier manuels

Aucune application n’a pu être lancée dans ce conteneur faute de SDK Flutter et de backend Supabase local. Les scénarios suivants sont donc **NON EXÉCUTÉS** et doivent être consignés dans une session de recette de staging :

| Domaine | Scénarios | État |
|---|---|---|
| Auth | connexion, déconnexion, invitation, gate mot de passe, compte désactivé | Non exécuté |
| Ventes | commande mono/multi, transition, annulation | Non exécuté |
| Stock | entrée, sortie, correction, historique | Non exécuté |
| Livraison | affectation, visibilité chauffeur, confirmation | Non exécuté |
| Paiements | partiel, complet, historique | Non exécuté |
| B2B | isolation multi-tenant et téléchargement de documents | Non exécuté |

Les opérations de paiement ne disposent pas actuellement d’un parcours Flutter clairement relié à `record_payment`. Cette absence doit être confirmée comme choix opérationnel (paiements via outil administratif/SQL) ou traitée dans une phase métier distincte ; aucune nouvelle interface n’a été ajoutée pendant cette phase de stabilisation.

## Risques restants

### Critique

1. **Aucune preuve d’un `supabase db reset` réussi sur le commit final.** Une erreur SQL ou d’extension reste possible jusqu’au run CI réel.
2. **Aucune preuve d’un `flutter analyze`/`flutter test` réussi sur le commit final.** Une erreur de compilation ou de test reste possible.
3. **Aucune recette B2B multi-tenant exécutée contre une instance réelle.** Le déploiement est interdit avant ce test.

### Élevé

1. Les policies Storage corrigées doivent encore être rejouées manuellement avec les sept rôles et un téléchargement réel.
2. Le rollback d’une invitation est compensatoire : un email peut déjà avoir été émis avant une erreur ultérieure, même si le compte est supprimé.
3. La migration de réconciliation stock crée des mouvements `migration_reconciliation`. Leur volume et leur valeur doivent être revus avant production.
4. L’absence d’un parcours Flutter identifié pour `record_payment` empêche la recette métier de paiement dans l’application.

### Moyen

1. Les helpers et policies historiques hors périmètre critique restent nombreux ; `supabase db lint` et Security Advisor doivent être revus après migration.
2. Les secrets Vault `supabase_url` et `service_role_key` doivent être configurés avant la première exécution cron.
3. Les alertes nécessitent une configuration externe Supabase/log drain ; la documentation seule ne les active pas.

### Faible

1. Des lints de style historiques peuvent subsister même si aucun warning critique n’est présent.
2. Les messages d’erreur applicatifs mélangent français et anglais dans certaines vues historiques.

## Conditions de passage à READY

La conclusion peut devenir **READY WITH MINOR RISKS** uniquement après :

1. workflow CI totalement vert sur le commit final ;
2. `supabase db reset` et tests pgTAP verts deux fois consécutivement ;
3. recette staging signée pour Auth, ventes, stock, livraison, paiement et B2B ;
4. test Storage B2B réel avec deux tenants ;
5. revue des mouvements de réconciliation stock ;
6. configuration SMTP, URLs, taux de change, backups et alertes ;
7. bootstrap désactivé et secret supprimé.

## Recommandation finale

# NOT READY FOR PRODUCTION

Les corrections nécessaires sont présentes, mais la validation exécutable exigée n’a pas pu être produite dans l’environnement courant. Le risque principal n’est plus un défaut connu non corrigé ; c’est l’absence de preuve qu’un reset complet, les tests RLS/RPC, Flutter et la recette de staging passent ensemble sur le commit final.
