# Gate final — LoliExpress ERP

> **Current status — 2026-11-25:** Current authoritative snapshot: 56/66 SQL PASS, 1 FAIL after fixture provisioning, 9 NOT_RUN. Full Web/Android business flows, real invitations and dispatch, production parity and final SHA evidence remain open. Older entries below are historical. [Current audit](docs/gate_audit_2026-11-25.md).


## Gate cloud — 25 novembre 2026

**Validation partielle.** Le projet testé est `loliexpress-gate-test`. Le frontend compilé correspond à `ad59a4de9462b4074da59b6efc3a0c0ac15571ae`. Les fonctions Edge ont ensuite été redéployées avec le correctif CORS de cette branche.

| Contrôle | Résultat |
|---|---|
| Assertions SQL du gate | 56 PASS, 1 contrôle de base vierge faux sur cette base provisionnée, 9 contrôles intermédiaires après 000 à exécuter sur un projet neuf autorisé |
| SQL des parcours opérationnels | Rapprochement stock et trésorerie, achats, ventes, dépenses, transferts et inventaire PASS. Préférences et lecture des notifications PASS. |
| Flutter | Build web release PASS. Dernière analyse sans erreur ni avertissement et 18/18 tests Flutter à `ad59a4d`. |
| Chromium | 7/7 connexions réelles avec formulaire Flutter, HTTP Auth 200 et écran attendu. Les opérations métier complètes depuis l’interface restent à exécuter. |
| Edge | 7/7 tests unitaires, deux fonctions déployées sur le test, 2/2 prévols CORS 204, 4/4 réponses attendues depuis Chromium. Invitation réelle et réception d’e-mail en attente. |
| Android | Aucune preuve du SHA actuel. Compilation locale interrompue pendant l’installation du NDK 27.0.12077973. Appcircle peut produire l’APK de test. |
| Livraison des notifications | La cible et la clé de dispatch sont absentes de Vault. Aucun envoi e-mail, push ou SMS validé. |

- [Résultats SQL du rejeu](gate_state/current/sql-assertions.json) · [Connexion et captures par rôle](gate_state/current/web-login-routes.json)
- [Prévols CORS](gate_state/current/edge-cors.json) · [Réponses Edge depuis Chromium](gate_state/current/edge-browser.json) · [Passation Android](MOBILE_HANDOFF.md)

## Traçabilité

- Branche de gate [gate/final-verification](https://github.com/Jnk017/loliexpress_erp/tree/gate/final-verification).
- SHA de référence [`5a68a999ca15bde01804185fa884e12d7ca09866`](https://github.com/Jnk017/loliexpress_erp/commit/5a68a999ca15bde01804185fa884e12d7ca09866).
- SHA du commit d’assemblage [`4dedf468cd6c009e0d2c77b53661c0ab6945333c`](https://github.com/Jnk017/loliexpress_erp/commit/4dedf468cd6c009e0d2c77b53661c0ab6945333c).
- Draft PR [#13](https://github.com/Jnk017/loliexpress_erp/pull/13).
- Dernière tentative de gate le 23 novembre 2026. Verdict `ÉCHEC (prérequis)`. Les contrôles SQL, les parcours et les captures restent `NOT_RUN`.
- APK Codemagic en attente. Consigner le lien et le SHA-256 de l’APK, le SHA complet du commit vérifié et le SHA-256 de chaque capture avec leurs résultats.

## Rejeu 000–017 — API Supabase officielle et PAT

Le projet `loliexpress-gate-test` (`muzbwqxvamcbfiuehxro`) a été vérifié par son nom et son identifiant, avec zéro table publique avant rejeu. La CLI en mode `--include-all --dry-run` a rencontré un refus TCP du pooler. Les 18 migrations ont ensuite reçu HTTP 200 sur l’API officielle, avec PAT et vérification de la référence avant chaque requête. Les quatre RPC clés sont présentes après rejeu. [Empreintes et statuts](audit/gate/cloud-pat-migrations.tsv)

L’essai antérieur via le connecteur avait été refusé. La baseline contient notamment des instructions conditionnelles de remplacement de politiques et triggers. Aucune commande autonome de suppression de données n’a été lancée. Les assertions SQL et les parcours restent `NOT_RUN`. Aucun appel à la production ni à GitHub Actions.

## Verdict — reprise HTTPS

**ÉCHEC.** Le connecteur Supabase a refusé la baseline `000` et la base de test est restée vierge. Les 66 assertions ainsi que les parcours web et mobile restent `NOT_RUN`. Flutter a signalé deux échecs de test. Le build et l’analyse ont été bloqués par l’environnement. Les sept tests unitaires Edge sont verts. [Journal et empreintes](GATE_STATE.md)

## Cible de reprise — G0.8

Le gate reprend sur le projet Supabase cloud dédié `muzbwqxvamcbfiuehxro` pour PostgreSQL, Edge Functions et le backend E2E. Flutter, Deno et Playwright restent sur l’hôte Codex. Codemagic compile l’APK Android. GitHub Actions reste exclu. Les références à la pile locale ci-dessous décrivent le protocole antérieur. Aucune assertion cloud exécutée à ce stade. [Passation Android](CLOUD_HANDOFF.md)

## Résultat d'exécution — Step 0, 23 novembre 2026 UTC

**Verdict : ÉCHEC (prérequis).** Le checkout et plusieurs outils requis manquent. Le client Docker ne peut pas joindre le daemon. La sonde Chromium échoue au lancement. Aucun test ni assemblage n'a été exécuté. Le détail et les preuves sont consignés dans le [journal du gate](GATE_STATE.md).

| Composant | PASS | FAIL | NOT_RUN |
|---|---:|---:|---:|
| P0.a avec baseline | 0 | 0 | 14 |
| P0.b élargi | 0 | 0 | 13 |
| P1.a amendé | 0 | 0 | 34 |
| P1.b.2 | 0 | 0 | 5 |
| Parcours authentifiés web | 0 | 0 | 7 |
| Parcours authentifiés mobile | 0 | 0 | 7 |

La [matrice par ID](audit/gate/assertions.tsv) annote les 66 assertions SQL. Compilation, tests Flutter, build web et Edge Functions sont `NOT_RUN`. Aucune capture, aucun hash de commit testé et aucune connexion à l'instance active. La vérification reste locale et GitHub Actions est exclu.

## Séquence du gate

1. Assembler les fichiers du workspace avec le dépôt au commit `5a68a99`. Dans une pile Supabase PostgreSQL 17 vierge, exécuter `000`, contrôler la baseline, puis appliquer `001` à `017` dans l'ordre avec arrêt sur erreur. Les 27 migrations historiques restent hors de ce rejeu consolidé.
2. Exécuter dans l'ordre les contrôles P0.a, P0.b, P1.a et P1.b. Attendre **66 assertions vraies** en incluant les neuf contrôles de baseline. Enregistrer les sorties et les versions d'outils.
3. Exécuter `flutter pub get`, `flutter analyze`, `flutter test`, les tests Edge Functions et le build web sur la version assemblée. Effectuer les parcours Auth et métier authentifiés et réaliser les captures attendues.
4. Reporter les résultats par lot dans le journal. Les actions destructrices sur l'instance active et le déploiement nécessitent leur propre exécution planifiée.

## P0.a — Code↔base réconciliés

**Definition of Done.** Baseline `000_baseline_active.sql` capturant les 117 versions + 4 RPC actives ; migrations `001_*` à `004_*` corrigeant `create_order_with_items`, `adjust_stock`, `transition_order_status`, `complete_password_setup` ; adaptations Flutter correspondantes ; `verify_p0a.sql` avec une assertion par RPC (signature + comportement) ; entrée FINAL_VERIFICATION.md listant les 4 assertions + rejeu complet baseline+fixes depuis zéro.

### Rejeu de la baseline

1. Partir d'une pile Supabase PostgreSQL 17 isolée, avec Auth, Storage et les rôles Supabase provisionnés, sans les migrations applicatives historiques. Exécuter [000_baseline_active.sql](migrations/000_baseline_active.sql) avec arrêt à la première erreur SQL.
2. Exécuter [verify_p0a_baseline.sql](audit/verify_p0a_baseline.sql) dans cet environnement. Les neuf lignes doivent toutes retourner `passed = true` : 61 tables publiques, 61 tables RLS, 222 index, 135 politiques publiques et Storage, deux empreintes de fonctions, deux absences attendues et bucket privé.
3. Rejouer `000` sur ce même état isolé et relancer les neuf assertions. Vérifier aussi la concordance des privilèges, contraintes et triggers avec les captures du catalogue. Le total de politiques inclut le schéma Storage et doit être interprété sur une pile équivalente.
4. Réinitialiser une seconde pile vierge, rejouer `000` puis `001` à `004` dans l'ordre et exécuter [verify_p0a.sql](audit/verify_p0a.sql). Les cinq lignes doivent toutes retourner `passed = true`. Les données de test sont isolées, et le script annule la transaction.
5. Rejouer `001` à `004` sur la même pile, puis relancer les cinq assertions. Vérifier également dans Flutter qu'une nouvelle sélection de client vide le panier, qu'un tarif indisponible affiche une erreur et qu'un ancien tarif est refusé si l'admin le modifie avant validation.

### Assertions embarquées dans verify_p0a.sql

| RPC | Résultat attendu après les correctifs |
|---|---|
| `create_order_with_items` | Signature Flutter à sept paramètres. Le catalogue de test vaut 4 000 CDF, les tarifs A et B valent 3 850 et 3 565 CDF. Deux unités pour A donnent 7 700 CDF. Refus d'une remise commerciale, de la modification non admin et d'un prix périmé. |
| `adjust_stock` | Signature Flutter avec `p_quantity_delta` et référence. Variation attendue enregistrée une seule fois. Stock négatif refusé et opération annulée. |
| `transition_order_status` | Signature avec statut et motif facultatif. Transition autorisée et auditée. Transition interdite sans écriture. |
| `complete_password_setup` | Signature sans paramètre. L'appel authentifié ne finalise le profil qu'après la mise en place du mot de passe. Tentative d'écriture directe refusée. |

### Périmètre de la capture

La baseline consolide le schéma applicatif observé. Les identifiants historiques sont conservés comme provenance et ne sont pas réinsérés dans la table de suivi Supabase. Les deux RPC absentes sont des assertions d'absence avant les correctifs. Les captures n'incluent aucune donnée métier ni commande cron sortante. Les métadonnées cron et les privilèges par défaut sont inventoriés séparément. La compatibilité du schéma managé et la parité de ces configurations hors migration doivent être contrôlées séparément avant l'utilisation sur un environnement réel.

## Lots en attente

- P1.a : après le rejeu complet sur une pile vierge, exécuter [verify_p1a.sql](audit/verify_p1a.sql). Les 34 assertions doivent retourner `passed = true`, dont [cinq assertions RA1–RA5](audit/verify_p1a_ra.sql) après `015`. [Diff P1.a](audit/P1A_CYCLES_DIFF.md)
- P1.a remise, retour et avoir : après `015`, exécuter [les treize assertions vente et stock](audit/verify_p1a_handover.sql). Vérifier les ventes CDF/USD jusqu'au solde de la créance, le refus d'un avoir pour un retour non revendable, le montant net d'un avoir sur retour mixte et la sortie unique à la remise. Dans Flutter, contrôler aussi le choix CDF/USD, le prix affiché, les deux quantités de retour, l'autorisation d'avoir et l'encaissement.

- P0.b : [inventaire validé](INVENTAIRE_DONNEES.md), [rejeu local sans données](audit/restore_p0b_clean.sh), [assertions SQL d'accès et de persistance](audit/verify_p0b.sql), [validation Auth sur Free](audit/P0B_AUTH_FREE.md). Le script de reprise local rejoue `000` à `005`, puis `016`. Attendre 13 lignes `passed = true`. Tester l'invitation réelle, le minimum Auth de huit caractères et le trajet OTP. Après reconnexion Flutter, vérifier le profil société, la devise dans les nouveaux documents, la TVA 0 %, le modèle PDF, le pied de page et l'expéditeur. Vérifier qu'une facture déjà émise conserve le modèle figé. L'expéditeur est chargé en configuration. La vérification du domaine et la configuration du service d'envoi restent requises avant tout envoi réel.
- P1.a achats : après `014`, exécuter [les huit assertions brouillon et cycle fournisseur](audit/verify_p1a_drafts_and_purchases.sql). Une réception de 1 sur 2 produit une seule entrée de stock. L'enregistrement de la facture fournisseur crée la dette sans mouvement de stock. Le paiement partiel et le solde règlent la facture sans simuler la réception restante. Vérifier le PDF Flutter pour les mêmes données.
- P1.a facturation : après `008`, exécuter [les trois assertions livraison et créance](audit/verify_p1a_invoice_delivery.sql). Attendre un total TTC de 4 350 CDF pour 3 850 + 500 CDF, puis une créance de 500 CDF après paiement de 3 850 CDF et aucune créance ouverte après le solde. La fixture USD vérifie qu'une livraison peut être gratuite. Dans Flutter, vérifier la facture émise par admin/comptable, le refus de mélanger les devises, puis la génération et le partage du PDF portant le numéro, les lignes et les montants émis.
- P1.a avoir de livraison : après `009`, exécuter [les cinq assertions d'avoir](audit/verify_p1a_admin_delivery_credit.sql). Attendre le refus pour un comptable, le plafond cumulé, une seule écriture en cas de relance, la créance nette et le remboursement à effectuer si la facture avait déjà été payée. Dans Flutter, vérifier que l'action est réservée à l'admin et que le motif est obligatoire.
- P1.b.2 : après `017`, exécuter [verify_p1b.sql](audit/verify_p1b.sql) et attendre cinq lignes `passed = true`. Contrôler les [captures attendues](audit/P1B_CAPTURES_ATTENDUES.md). Les réglages persistants sont traités en P0.b selon G1 v3.

La CI historique et les contrôles Flutter, Supabase, Edge Functions et build web restent à exécuter au gate final.

## Reprise — candidat ed4b52d

La migration 026 est appliquée sur Gate. Le lot de sécurité de la trésorerie vérifie six signatures et 49 refus. Le [gate local](audit/production_readiness/release_gate_results.json) confirme l’analyse Flutter sans remarque, les 18 tests Flutter, le build Web, les huit suites SQL ciblées et les sept tests Deno. Les sept étapes marquées `NOT_RUN` ne constituent pas des preuves de validation. Verdict **NOT_READY — REMAINING_BLOCKERS**.

## Lots livraison et concurrence — Gate

Migration 027 appliquée. La lecture d’une livraison affectée reste disponible pour le livreur, et la modification directe est refusée. Les suites remise, commandes et stock passent. La confirmation concurrente d’une même livraison conserve une seule remise et une seule sortie de stock. [Frontière du livreur](audit/production_readiness/delivery_boundary_results.json) · [Concurrence de remise](audit/production_readiness/concurrent_handover.json)

Sur Flutter Web à `7350ad2`, le magasinier a exécuté la réception depuis le raccourci Stock, avec HTTP 200 et rapprochement PostgreSQL. La [preuve de réception](audit/production_readiness/warehouse-web.json) couvre une étape du cycle transversal. Le cycle complet reste ouvert.

Le [contrôle des encaissements](audit/production_readiness/concurrent_payment.json) et le [contrôle des ventes](audit/production_readiness/concurrent_sales.json) ont réussi sur deux sessions simultanées chacun. Les écritures et quantités ont été rapprochées, puis les données jetables retirées.
