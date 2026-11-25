# État de reprise — 25 novembre 2026

**NOT_READY — REMAINING_BLOCKERS**

Gate initial `6a98532ebf5217c802cdab953c2af9201f5afe72`. Main `5a68a99`. PR #13 ouverte, Draft, état de fusion signalé UNSTABLE.

| ID | Priorité | État | Cause / dépendance | Fichiers et correction | Tests et preuves | Commit |
|---|---|---|---|---|---|---|
| DB-001 | P0 | BLOCKED_EXTERNAL | Production refuse la lecture métadonnées HTTP 403 | Collecteur et capture Gate, 2 701 objets sur 20 catégories | [Résumé](gate_catalog_summary.json) | Lot courant |
| DB-002 | P0 | BLOCKED_EXTERNAL | Gate déjà provisionné et cible vierge non confirmée | Rejeu à effectuer sans effacer Gate | 56 réussites, un contrôle à rejouer avant fixtures, neuf historiques non exécutés | `9ff342b` |
| DB-003 | P0 | TODO | Dépend du drift détaillé et d’une copie isolée | Migration à préparer | Répétition requise | — |
| SEC-001 | P0 | IN_PROGRESS | Revue par routine à terminer | Signatures inventoriées | [Catalogue](gate_catalog_summary.json) | Lot courant |
| SEC-002 | P0 | TEST_PASSED | Tables fermées en accès direct | Aucun ajout de privilèges | [Contrôle SQL](verify_rpc_only_tables.sql) sur Gate | Lot courant |
| SEC-003 | P0 | IN_PROGRESS | Matrice multi-rôles incomplète | Migration 025 resserre les droits de notification | [Contrôle SQL](verify_notification_grants.sql), lecture, préférences, trésorerie PASS | Lot courant |
| SEC-004 | P0 | TODO | Inventaire secrets et dépendances à qualifier | Contrôle anti-fuite du lot | Git ignore vérifié avant push | Lot courant |
| SEC-005 | P0 | TEST_PASSED | Advisors actualisés, constats à analyser | Aucun effacement d’alerte | [Advisors Gate](gate_advisors.json) | Lot courant |
| AUTH-001 | P0 | TODO | Boîte et transport de test requis pour la réception réelle | Supabase Auth, fonctions et redirections à vérifier | Connexions existantes, réception non testée | `9ff342b` |
| ERP-001–011 | P0 | TODO | Rejeu depuis l’interface et rapprochement complet à fournir | Services, écrans, migrations 001–024 | Suites transactionnelles partielles | `ad59a4d` |
| EDGE-001–002 | P0 | TODO | Dispatch Gate non configuré | Inventaire Edge et file de notifications | Deux fonctions vérifiées depuis Chromium | `9ff342b` |
| WEB-001 | P0 | TODO | Suite métier à construire | Preuves de connexion conservées | 7 connexions, magasinier et actions métier à couvrir | `9ff342b` |
| MOB-001–003 | P0 | TODO | NDK local interrompu, artefact et téléphone nécessaires | Workflows Appcircle et Codemagic | Voir passation Android | — |
| AI-001, OPS-001, PERF-001–003, UX-001, DOC-001, REL-001 | P0/P1 | TODO | Couverture à compléter selon la matrice | Voir plan maître | Aucune clôture déduite des archives | — |

## Lot de clôture 026

| ID | Priorité | État | Cause, correction et fichiers | Tests et preuves | Commit |
|---|---|---|---|---|---|
| SEC-001-A | P0 | DONE | Privilèges d’écriture directe hérités sur les comptes et journaux. Migration 026. | Six signatures examinées et validées, 49 refus par rôle, deux suites de régression financière. [Matrice](RPC_SECURITY_MATRIX.md) | `ed4b52d` |
| SEC-001-B | P0 | TODO | Revue des 35 signatures restantes, en commençant par commandes et factures. | Tests par RPC à compléter. | — |
| REL-001-A | P0 | DONE | [Orchestrateur](run_release_gate.py) et statuts explicites. | [Rapport](release_gate_results.json) produit, le gate sort en erreur tant que des contrôles restent non exécutés. | `ed4b52d` |
| DB-002-A | P0 | IMPLEMENTED | [Rejeu](replay_baseline.py) de la baseline, du registre numéroté et des suites SQL. | Garde de refus de Gate testée localement. Rejeu complet bloqué sur une cible vierge autorisée. | Lot de preuves 026 |
| SEC-002-A | P0 | TEST_PASSED | Contrôles REST et recherche de vues dépendantes. | 12/12 lectures directes sans données pour trois rôles, zéro vue dépendante. Revue des fonctions indirectes à achever. | Lot de preuves 026 |
| PERF-003-A | P0 | DONE | Deux transferts de six unités sur un stock de dix. Le premier nettoyage a nécessité l’identité d’audit. Le script la définit désormais. | [Preuve multisession](concurrent_transfer.json), un transfert réussi, un refus, solde conservé, nettoyage confirmé. | Lot de concurrence `test_concurrent_transfer.py` |

Les autres scénarios de concurrence sont ouverts. Le test de transfert est raccordé au gate avec `--with-gate-fixtures` sur le projet Gate.

## Lot 027

| ID | Priorité | État | Correction et preuve |
|---|---|---|---|
| SEC-003-B | P0 | DONE | Suppression de la mise à jour directe par le livreur. Lecture affectée, écriture refusée et régressions validées sur Gate. [Résultats](delivery_boundary_results.json) |
| SEC-001-B | P0 | IN_PROGRESS | Six signatures supplémentaires examinées sur les commandes, la livraison et le stock. Les tests d’autorisation individuels restent à compléter. |
| PERF-003-B | P0 | TEST_PASSED | Rejeu séquentiel après une remise réussie et rollback après une tentative avec stock insuffisant. Deux assertions de la [suite de remise](delivery_boundary_results.json). La confirmation multisession reste ouverte. |

| PERF-003-C | P0 | DONE | Confirmation simultanée sur deux sessions distinctes. Le second appel confirme la remise existante sans nouvelle sortie du stock. | [Preuve et nettoyage](concurrent_handover.json), cible Gate et code à `608d751`. |

La reprise de la concurrence porte sur les ventes, encaissements, réceptions fournisseur et avoirs. Le parcours Web transversal reste à exécuter depuis Flutter.

## Lot 028

| ID | Priorité | État | Correction et preuve |
|---|---|---|---|
| WEB-001-A | P0 | TEST_PASSED | La route de réception est autorisée au magasinier et utilise une file RPC sans données financières. [Tests SQL](warehouse_receipt_results.json), analyse et 18 tests Flutter réussis. Test navigateur de réception à confirmer. |
