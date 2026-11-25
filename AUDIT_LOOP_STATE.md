# Journal de bord LoliExpress ERP

> **Current status — 2026-11-25:** P0.a 5/5 SQL; P0.b 12/13 on provisioned Gate; P1.a 34/34; P1.b 5/5. Nine baseline checks pending. P2/P3 remain unvalidated. See the current release audit; historical iteration labels below are retained. [Current audit](docs/gate_audit_2026-11-25.md).


## État courant — itération 15 · P1.b.2

| Lot | Statut | Preuves |
|---|---|---|
| P0.a | **PRODUIT — à vérifier** | Baseline, diff et contrôles RPC dans le [gate](FINAL_VERIFICATION.md). |
| P0.b élargi | **PRODUIT — à vérifier** | [016](migrations/016_persistent_company_settings.sql), [reprise](audit/restore_p0b_clean.sh), [accès et réglages](audit/verify_p0b.sql). |
| P1.a amendé | **PRODUIT — à vérifier** | [015](migrations/015_avoirs_revendabilite.sql) et [34 assertions](audit/verify_p1a.sql) dont RA1–RA5. |
| P1.b.2 | **PRODUIT — à vérifier** | [017](migrations/017_workspace_setup_progress.sql), [écran par rôle](lib/widgets/role_workspace_panel.dart), [verify_p1b.sql](audit/verify_p1b.sql), [captures attendues](audit/P1B_CAPTURES_ATTENDUES.md). |
| P2/P3 | TODO | Dépendent des résultats du gate final. |

- P1.b.2 démarré après le gate de stabilisation v3. Les espaces commercial, comptable, acheteur et admin ont des raccourcis filtrés par les permissions existantes. L'état de mise en route vient des données réelles. L'état vide Achats ouvre la création pour les rôles autorisés.
- Contrôles statiques de la séquence 000–017, de la couverture des scripts et des routes. Aucun test d'exécution ni capture effective réalisés dans ce workspace sans checkout exploitable.
- **Décision : bascule vers le gate final.** Assembler l'overlay avec le dépôt source, exécuter [FINAL_VERIFICATION.md](FINAL_VERIFICATION.md) sur la pile isolée et enregistrer les résultats. Aucune migration hébergée, commit ou déploiement exécutés.

## Itérations 13–14 — v3, P1.a amendé et P0.b élargi

- Résultat des deux itérations : **P0.a, P0.b élargi et P1.a amendé PRODUIT — à vérifier**. Contrôles statiques validés sur la séquence 000–016, délimiteurs, intégration des assertions RA et des réglages, syntaxe du script de reprise et configuration Free. Le gate de stabilisation G1(a) autorise P1.b.2. SQL et Flutter n'ont pas encore été exécutés au gate final.

- G1 v3 et G11 incorporés au [contrat v3](audit/WORKFLOW_V3.md). Le gate de stabilisation est un état PRODUIT avec artefacts, distinct du gate final exécuté. Le classement de la persistance dans P1.b était une erreur de catégorisation de la v1. L'audit la décrit comme un défaut existant ; sa correction rejoint P0.b. P1.b.2 garde navigation, raccourcis, démarrage guidé et états vides.
- P1.a est passé par **PRODUIT — à vérifier (amendement RA1–RA5 en cours)**. [Migration 015](migrations/015_avoirs_revendabilite.sql), [cinq assertions dédiées](audit/verify_p1a_ra.sql), [diff](audit/P1A_CYCLES_DIFF.md) et [gate](FINAL_VERIFICATION.md) produits. Base active : pas de `invoice_lines`, `return_units_audit` ni `invoice_item_credits`. La RPC d'avoir conserve sa signature, utilise la ligne facturée figée, et refuse les codes P4101/P4104 selon le cas.
- P0.b est passé **EN COURS** sur le périmètre élargi. [Migration 016](migrations/016_persistent_company_settings.sql), [réglages Flutter](lib/presentation/settings_configuration/settings_configuration.dart), [rejeu](audit/restore_p0b_clean.sh), [assertions](audit/verify_p0b.sql) et [gate](FINAL_VERIFICATION.md). Aucune table active `company_settings`. Nouveaux contrats `get_company_settings()` et `update_company_settings(jsonb)`, accès par rôle. Le PDF émis fige la présentation, et les nouvelles ventes, factures et achats chargent la devise par défaut.
- Preuves précédentes conservées : [source des données](INVENTAIRE_DONNEES.md), reprise sans données de démo, RLS par rôle et [OTP/MDP Free](audit/P0B_AUTH_FREE.md).
- P0.a : **PRODUIT — à vérifier**. P1.b.2 : TODO jusqu'à clôture de la production de P0.b et de l'amendement P1.a. Aucun changement sur Supabase hébergé.

## État courant — itération 12 · P1.a

- Décision validée : aucun avoir article pour une unité non revendable. Sur un retour mixte, l'admin peut créditer uniquement les unités revendables au prix net d'origine. La décision liée aux frais de livraison reste indépendante.
- P0.a, P0.b et P1.a : **PRODUIT — à vérifier**, fichiers locaux. [Diff P1.a](audit/P1A_CYCLES_DIFF.md), [migrations 013](migrations/013_sellable_return_credits.sql) et [014](migrations/014_supplier_bills_and_payments.sql), [verify_p1a.sql](audit/verify_p1a.sql) et [gate](FINAL_VERIFICATION.md). Réception, facture fournisseur et paiement sont reliés à l'écran Achats. L'encaissement et les avoirs sont reliés à l'écran Factures. Le parcours de vente permet de choisir CDF ou USD.
- Contrôles statiques : séquence 000–014, délimiteurs, contrats Flutter/SQL et 29 assertions P1.a inventoriés. Rejeu, compilation et tests au gate.
- P1.b : TODO. G1 demande que P0 passe le gate avant les fonctions inspirées de Zoho. Le §4 demande que P1.b soit produit avant ce même gate. Il faut résoudre l'ordre pour continuer la navigation, les raccourcis et le démarrage guidé. P2 et P3 : TODO.
- Aucun SQL d'écriture sur Supabase, commit ou déploiement.

## État courant — itération 11 · P1.a

- Décision validée : seules les unités contrôlées et déclarées revendables sont remises en stock. Toute quantité écartée reste tracée sans effet sur le stock disponible.
- [Migration 012](migrations/012_inspected_customer_returns.sql), [service livraison](lib/services/delivery_service.dart), [parcours de contrôle](lib/presentation/delivery_tracking/delivery_tracking.dart), [neuf assertions stock](audit/verify_p1a_handover.sql) et [gate](FINAL_VERIFICATION.md). Retour lié à une remise, plafonné à la quantité vendue par ligne, dépôt d'origine, attribution à l'opérateur et relance protégée.
- Diff : la base active ne contient pas de table d'inspection ni de RPC correspondante. Deux nouveaux contrats : `get_customer_return_lines(text)` et `inspect_customer_return(uuid,integer,integer,text,uuid)`. Le contrôle et le mouvement des unités revendables sont transactionnels.
- P0.a et P0.b : **PRODUIT — à vérifier**. P1.a : **BLOQUÉ (G6, éligibilité d'un retour non revendable à un avoir sur l'article)**. Le remboursement des frais de livraison conserve sa décision admin séparée. Restent aussi le cycle fournisseur et les rapprochements complets CDF/USD.
- Contrôles statiques seulement, aucune écriture en production.

## État courant — itération 10 · P1.a

- Décision métier : sortie du stock à la remise effective au client. Confirmation de commande et expédition sans sortie.
- [Migration 011](migrations/011_stock_at_customer_handover.sql) et parcours Flutter livraison produits. `confirm_delivery(uuid,text,text) → jsonb` conserve signature et réponse. Le corps actif marquait seulement la livraison. Le nouveau corps verrouille la livraison, la commande et le stock, écrit le mouvement et marque la livraison ainsi que la commande livrées atomiquement. Une nouvelle RPC attribue l'entrepôt explicitement, sans entrepôt par défaut.
- [Scénarios SQL](audit/verify_p1a_handover.sql) : stock intact après expédition, statut protégé, sortie unique en cas de relance, stock insuffisant avec annulation, même règle CDF/USD.
- P0.a et P0.b : **PRODUIT — à vérifier**. P1.a : **BLOQUÉ (G6, remise en stock des articles retournés)**. Décider du traitement d'un article endommagé ou non revendable. Cycle fournisseur, raccordement de l'écran de réception et rapprochement complet encore ouverts. P1.b et suivants : TODO.
- Contrôles statiques uniquement. Aucune migration appliquée à l'instance active.

## État courant — itération 9 · P1.a

- Décision métier : les frais de livraison peuvent être crédités uniquement sur décision explicite de l'admin. Le retour ne déclenche aucun avoir de frais.
- [Migration 009](migrations/009_admin_delivery_fee_credits.sql), écran d'administration des avoirs de livraison, [cinq assertions](audit/verify_p1a_admin_delivery_credit.sql) et [gate](FINAL_VERIFICATION.md) produits. Les avoirs conservent un motif, l'approbateur, une clé de relance et un plafond cumulé égal aux frais facturés. Le flux d'avoir identifie la somme à rembourser mais ne déclenche aucun mouvement bancaire.
- Diff sur la base active : aucune table d'avoir ou RPC équivalente. `record_delivery_fee_credit(uuid,numeric,text,uuid)` est nouvelle. `record_payment(uuid,numeric,text,text,text,text)` garde sa signature et sa réponse JSON. Le corps calcule la créance après avoir. Empreinte active du corps comparé : `eb33e677fd5101721e09fd15ea31c359`.
- Réception fournisseur : [migration 010](migrations/010_receive_purchase_item.sql) et méthode Flutter ajoutées. L'ancienne base ne contient ni la table de réception ni cette RPC. Insertions et mises à jour atomiques, test de relance et de réception partielle préparé. Raccordement à l'écran d'achat et cycle de dette fournisseur à compléter.
- P0.a et P0.b : **PRODUIT — à vérifier**. P1.a : **BLOQUÉ (G6, moment de sortie du stock lors d'une vente)**. Suite indépendante : retours d'articles et cycle de facture fournisseur, puis rapprochements CDF/USD. P1.b et suivants restent TODO.
- Aucune écriture sur l'instance active. Rejeu SQL et compilation Flutter au gate final.

## État courant — itération 8 · P1.a

- Décision confirmée : prix catalogue et préférentiels TTC, taux 0 %, aucune exonération. Frais facultatifs appliqués uniquement à certaines livraisons à domicile. Le taux de démonstration est écarté.
- P0.a et P0.b : **PRODUIT — à vérifier**. Correction de la baseline : la vue `receivables_aging` avait une liste d'options vide invalide `WITH ()`. Elle est retirée. La migration 008 rend la vue utilisatrice des permissions de l'appelant.
- P1.a : **BLOQUÉ (G6, traitement des frais dans les avoirs)**. Émission, PDF et créance préparés. Les avoirs et retours nécessitent une règle sur le remboursement des frais à domicile. Réceptions partielles et rapprochements de bout en bout restent à produire.
- Diff : la base active n'a ni `issue_order_invoice` ni les trois colonnes de livraison/remise. [008](migrations/008_issue_order_invoice.sql) ajoute `issue_order_invoice(uuid,timestamptz,boolean,numeric) → invoices`, conserve la signature de `record_payment` et expose une vue de créances. Le service Flutter appelle le nouveau contrat.
- Le brouillon conserve le mode et les frais. L'admin ou le comptable émet depuis une commande confirmée, avec le prix déjà autorisé par la commande. Le même PDF sert aux actions de téléchargement et de partage. [Assertions](audit/verify_p1a_invoice_delivery.sql) · [Gate](FINAL_VERIFICATION.md)
- Pas d'écriture en production. Rejeu et compilation en attente du gate final.

## État courant — itération 7 · P1.a

- P0.a et P0.b : **PRODUIT — à vérifier**.
- P1.a : **BLOQUÉ (G6, fiscalité des factures à émettre)**. Le seul `tax_rate` observé vaut 20 dans la base de démo. Les données de cette base sont hors reprise. Aucun taux réel retenu.
- Artefacts partiels : [achat transactionnel](migrations/006_create_purchase_with_items.sql), [service Flutter achats](lib/services/purchase_service.dart), [brouillons](migrations/007_invoice_drafts.sql), [écran facture et PDF commun](lib/presentation/invoice_generation/invoice_generation.dart), [quatre assertions](audit/verify_p1a_drafts_and_purchases.sql), [gate](FINAL_VERIFICATION.md).
- Contrats ajoutés, absents dans la base active : `create_purchase_with_items(uuid,jsonb,text,numeric,text) → purchases` et `save_invoice_draft(uuid,uuid,text,jsonb) → uuid`. Le client appelle les nouveaux contrats. Les brouillons sont persistés séparément des créances.
- Prochaine action : confirmer les règles fiscales réelles (taux par catégorie et prix TTC/HT), puis compléter l'émission officielle, paiements/avoirs/retours, réception partielle et réconciliation CDF/USD. P1.b, P2 et P3 restent TODO.

## État courant — itération 6 · P0.b

- Décision utilisateur : maintien sur Supabase Free. La protection native Pro sort de la DoD, remplacée par la vérification du minimum de huit caractères et du parcours d'invitation. Aucun paramètre hébergé modifié.
- P0.a et P0.b : **PRODUIT — à vérifier**. [Inventaire](INVENTAIRE_DONNEES.md), [rejeu](audit/restore_p0b_clean.sh), [assertions](audit/verify_p0b.sql), [audit Auth et OTP](audit/P0B_AUTH_FREE.md), [gate](FINAL_VERIFICATION.md).
- Les anciennes fonctions OTP restent déployées. Pas de référence dans la recherche GitHub, zéro invocation sur deux appels Edge visibles sur 24 heures.
- P1.a : TODO, prochain lot. P1.b, P2 et P3 : TODO.

## État courant — itération 5 · P0.b

- Source confirmée : uniquement `loliexpress_erp`. Les données actuelles sont de démonstration et exclues de la reprise. [Inventaire](INVENTAIRE_DONNEES.md)
- P0.a : **PRODUIT — à vérifier**.
- P0.b : **BLOQUÉ (G6, décision de plan)**. [Rejeu local](audit/restore_p0b_clean.sh), [migration 005](migrations/005_access_role_predicates.sql) et [huit assertions](audit/verify_p0b.sql) préparés. P1 et lots suivants : TODO.
- Le plan de l'organisation est Free. La [protection native Supabase des mots de passe compromis](https://supabase.com/docs/guides/auth/password-security) exige Pro ou supérieur. Obtenir la décision sur le plan ou une modification explicite de la DoD P0.b avant le gate.
- Diff : les neuf prédicats de rôle à zéro argument gardent leur signature `() → boolean`. Ils s'appuient sur le rôle interne du profil actif et le premier accès. `is_admin_from_auth()` utilisait précédemment, entre autres, des métadonnées éditables par l'utilisateur. Aucun privilège d'exécution public ou anonyme n'est accordé.
- OTP inventoriés sur la cible : `verify_password_reset_otp` v2 et `request_password_reset_otp` v3, actifs, `verify_jwt=false`. Leur usage reste à établir avant retrait. L'invitation réelle reste à exercer au gate.
- Vérifications : `bash -n` et contrôles des définitions SQL effectués. Les assertions, le rejeu et la suppression des données de démonstration sur l'instance active n'ont pas été exécutés.

## Historique — itérations 3 et 4

| Lot | Statut | Preuves |
|---|---|---|
| P0.a | **PRODUIT — à vérifier** | [Diff](audit/P0A_RPC_DIFF.md), migrations `000` à `004`, adaptations de l'écran de vente et du service commandes, [assertions](audit/verify_p0a.sql), [gate](FINAL_VERIFICATION.md). |
| P0.b | **BLOQUÉ (G6)** | [Inventaire](INVENTAIRE_DONNEES.md). Les deux projets en pause refusent la lecture SQL. La source métier de reprise reste à désigner. |
| P1.a, P1.b, P2 et P3 | TODO | Dépendances P0 et gate différé. |

### Itération 3 — P0.a.2

- Décision utilisateur : 0 % de remise manuelle pour les commerciaux. Seul l'admin peut accorder une remise ou définir un tarif client–article. Le serveur applique le prix catalogue lorsqu'aucun tarif spécifique n'existe.
- Migrations locales `001` à `004` et scénario SQL transactionnel produits. Les montants d'exemple restent réservés aux fixtures. Aucun SQL d'écriture exécuté sur Supabase.
- Contrôle statique effectué sur les signatures, les dépendances capturées, la séquence des fichiers, les délimiteurs SQL et l'appel du tarif dans Flutter. La base active présente 8 lignes de stock, toutes réconciliées avec leurs mouvements lors du comptage.
- Déclencheur de notification de commande corrigé pour accepter zéro agent de dépôt. L'appel Flutter de tarif est nouveau, les quatre RPC principales gardent les signatures d'appel attendues par le dépôt audité.
- Limites : artefacts locaux dans un workspace sans checkout Git exploitable. Rejeu, CI, compilation et comportement en attente. Aucun écran d'administration des tarifs fourni dans ce lot.

### Itération 4 — P0.b.1

- Statut des projets recontrôlé. L'ERP actif est lisible, les deux projets secondaires sont toujours en pause et leurs volumes restent inconnus.
- Prochaine action : obtenir la source de données métier validée, puis préparer le script de restauration et les assertions d'accès P0.b. Aucune restauration n'a été lancée.

## Itération 2 — P0.a.1

- Statut à cette itération : **BLOQUÉ (G6)**. La baseline applicative était produite. Le lot atomique P0.a restait à livrer.
- État recontrôlé : `main` à `5a68a99`, branche Supabase `main` à `MIGRATIONS_FAILED`. L'arrêt CI de l'itération 1 est levé par le contrat différé. Git est installé, mais le dépôt n'est pas extrait localement.
- Capture : [catalogue](audit/p0a_active_catalog.json), [dépendances et corps actifs](audit/p0a_active_dependencies.json), [baseline](migrations/000_baseline_active.sql), [assertions de baseline](audit/verify_p0a_baseline.sql), [gate final](FINAL_VERIFICATION.md).
- Contrôle statique : 61 instructions de création de table, 66 définitions de routine, 117 versions de provenance, 135 politiques et 46 triggers. Les index isolés et les index de contraintes sont distingués. Le rejeu et les assertions sont différés.
- Écarts supplémentaires : les deux RPC actives n'accordent pas EXECUTE à authenticated. La colonne `user_profiles.must_change_password` est absente. Le modèle de taux actif utilise `currency_pair` et `effective_at`, alors que le dépôt attend un autre modèle.
- Blocage métier : aucune ligne active ne définit `sales_rep_max_discount_percent`. Le dépôt contient un repli à 10 %, sans validation métier consignée. Décision requise sur le plafond commercial avant de rendre la nouvelle RPC de vente utilisable.
- Prochaine action : reprendre P0.a.2 avec la règle de remise confirmée, produire 001 à 004 et leurs scénarios de contrôle, puis traiter P0.b. P0.b, P1.a, P1.b, P2 et P3 restent TODO.

## Historique

## Itération 1 — P0.a

- Date UTC : 2026-11-23.
- Tâche : diagnostic des quatre RPC et vérification de la possibilité de rejouer la CI.
- Statut : **BLOQUÉ** (G4). Diagnostic lecture seule réalisé. Comparaison sur copie isolée et rejeu de migrations en attente.
- Commit main : `5a68a999ca15bde01804185fa884e12d7ca09866`.
- PR nº 12 : ouverte, non fusionnée. Tête `1baa105436ea211f2d4c007953a9e6c4c61c7918`.
- Base active : `lvzdlmojjoqrwxwluvih`. 117 versions enregistrées, 27 fichiers dans Git, zéro version commune.

### Preuves

| Fonction | Base active | Dépôt et différence de comportement |
|---|---|---|
| `create_order_with_items` | `(p_customer_id uuid, p_items jsonb, p_notes text default null)`. Empreinte MD5 `e46de76027ef6bfdf6530a9262fba5f0`. | Quatre paramètres supplémentaires : devise, taux, type de paiement, remise. Le corps du dépôt vérifie le prix catalogue, le taux et la remise, et prévoit le périmètre B2B. |
| `adjust_stock` | `(p_product_id uuid, p_warehouse_id uuid, p_adjustment_quantity integer, p_reason text default 'manual_adjustment')`. Empreinte MD5 `dbd1979b5b2312b85b0ad0b1194e11ad`. | `p_quantity_delta` remplace `p_adjustment_quantity`. `p_reason` est requis. Ajout de `p_reference_id` et `p_reference_type`. Le corps du dépôt rejette un delta nul, valide l’emplacement et journalise le mouvement avec sa référence. |
| `transition_order_status` | Absente de `public`. | `(p_order_id uuid, p_new_status public.order_status, p_reason text default null)`. Le corps verrouille la commande, vérifie le droit, met à jour et journalise. |
| `complete_password_setup` | Absente de `public`. | `()`. Le corps vérifie l’identité et l’existence d’un mot de passe avant la mise à jour du profil. |

- [Commit audité](https://github.com/Jnk017/loliexpress_erp/commit/5a68a999ca15bde01804185fa884e12d7ca09866)
- [CI de main](https://github.com/Jnk017/loliexpress_erp/actions/runs/27041589488) — échec à `flutter pub get` et `supabase start`, build web ignoré. Relance tentée et rejetée par GitHub (HTTP 403, run de plus d’un mois). Le workflow n’a pas de déclencheur manuel.
- [PR nº 12](https://github.com/Jnk017/loliexpress_erp/pull/12) · [CI de la PR](https://github.com/Jnk017/loliexpress_erp/actions/runs/27864626070)
- [Base active](https://supabase.com/dashboard/project/lvzdlmojjoqrwxwluvih) — seule branche recensée : `main`, même référence que la base active, statut de migration `MIGRATIONS_FAILED`.

### Blocages et écarts

- Workspace sans checkout Git exploitable, Flutter absent, CLI Supabase absente, socket Docker inaccessible et authentification GitHub CLI invalide.
- Pas d’écart sur les quatre RPC par rapport à l’audit initial. Le statut de migration de la branche Supabase est un constat supplémentaire.
- Le journal est la seule écriture de cette itération. Aucun changement SQL, commit, déploiement ni PR.

### État des lots

| Lot | Statut |
|---|---|
| P0.a | BLOQUÉ |
| P0.b | TODO |
| P1.a et P1.b | TODO |
| P2.a et P2.b | TODO |
| P3 | TODO, sur décision utilisateur |

### Prochaine action

Reprendre P0.a quand un déclenchement de CI sur le code existant est disponible. Obtenir les journaux frais pour diagnostiquer Flutter et Supabase, puis préparer une copie isolée pour la comparaison et le rejeu. La validation exige les six contrôles demandés, l’alignement des quatre RPC et une résolution explicite de la PR nº 12.
