# Audit de release — 25 novembre 2026

## Verdict : NO GO / validation partielle
Référence code auditée : `9ff342b400f27fafa2f142613eb0986d59fc31cc`. Main : `5a68a999ca15bde01804185fa884e12d7ca09866`. Gate : 28 commits en avance, 0 en retard au moment de l'audit. PR [#13](https://github.com/Jnk017/loliexpress_erp/pull/13) ouverte, draft, mergeable ; branche Gate non protégée. Dernier commit contient skip-checks: true. Aucun merge ni changement Supabase effectué par cet audit. Les résultats d'exécution ci-dessous proviennent des preuves versionnées ; ils n'ont pas été rejoués intégralement lors de cette revue.

## Preuves et couverture
- [SQL](../gate_state/current/sql-assertions.json) : 56 PASS, 1 FAIL (empty_demo_data après provisionnement), 9 NOT_RUN (baseline seule). P0.a 5/5 ; P0.b accès 7/8, réglages 5/5 ; P1.a 34/34 ; P1.b 5/5. Refaire le test base vierge avant fixtures sans effacer la base Gate.
- [Web](../gate_state/current/web-login-routes.json) : 7/7 connexions, HTTP 200 et routes attendues. Deux comptes B2B ont une capture de même empreinte : cela ne prouve pas l'isolation en interface. Magasinier non couvert par ces sept connexions. Parcours métier complets non démontrés.
- Flutter : 18/18 tests, analyse sans erreur ni avertissement, build web release sur ad59a4d selon FINAL_VERIFICATION ; à répéter sur le candidat final.
- Edge : 7/7 tests unitaires documentés, [CORS](../gate_state/current/edge-cors.json) 2/2, [HTTP navigateur](../gate_state/current/edge-browser.json) 4/4 ; create_user acheteur 403, admin payload invalide 400, ai_assistant acheteur 403/admin 200. Invitation réelle et reset OTP non démontrés.
- Android : build debug sur SHA actuel non attesté ; NDK 27.0.12077973 interrompu localement. Appcircle et Codemagic configurés, Flutter 3.35.7. Un succès FlutLab sans APK ni SHA ne suffit pas à certifier la release. iOS non validé.

## Fonctionnalités
| Lot | État et preuve | Reste |
|---|---|---|
| Ventes/prix/stock/RPC | 001–005, verify_p0a : prix par client, contrôles serveur, transactions, statuts | UI réelle, concurrence |
| Auth/RLS/Storage | 005, 016, verify_p0b : isolation B2B/livreurs, bucket privé, réglages | invitation/reset, magasinier, matrice négative complète |
| Achats et factures | 006–015, verify_p1a : réception partielle, dette, paiement, brouillon, PDF, avoirs | UI, PDF partagé, remboursement effectif |
| Remise/retours | 011–015 : sortie à remise, retour revendable seul, avoir article au prix net figé, frais sur décision admin | parcours livreur, retour mixte réel |
| Démarrage et rapports | 016–018 : réglages persistants, workspace, reporting admin | UI et données réelles |
| Stock et trésorerie | 019–022, verify_stock_transfer_and_count et verify_operational_treasury : transferts, inventaire, caisse/banque/mobile money CDF/USD, paiements atomiques | comptes d'ouverture, UI et rapprochement réel |
| Notifications | 023–024, verify_notification_center_preferences et verify_notification_read : préférences et lecture | cible/clé Vault, envoi réel, supervision |
| IA/audit/sécurité | code et tables présents, 2 fonctions Edge testées sur Gate | qualité IA, toutes fonctions et workflows d'incidents non démontrés |

## Supabase — constat live en lecture seule
Gate contient les 25 migrations 000–024 enregistrées par noms avec versions horodatées serveur ; production conserve son historique ancien sans cette série. Toutes les tables publiques inventoriées ont RLS activée. La base Gate contient notamment les nouvelles tables customer_product_prices, invoice_drafts, invoice_delivery_fee_credits, purchase_receipts, stock_handovers, customer_return_inspections, invoice_item_credits, supplier_bills, supplier_bill_payments, invoice_lines, return_units_audit, company_settings, operational_treasury_postings, notification_center_preferences ; absentes de l'inventaire production. Gate : 7 profils, 2 clients, 1 réglage société, pas de transactions métier dans l'inventaire ; production : aucune ligne dans les tables métier inventoriées et 317 ai_insights. Ne pas assimiler estimation de lignes à preuve de sauvegarde.
Gate : 2 Edge actives (ai_assistant, create_user, JWT requis). Production : 10 actives (les deux précédentes, bootstrap_admin, invoice-reminder, forensic-export, track-failed-login, stock-alert, request_password_reset_otp, send-email-notification, verify_password_reset_otp). Les trois bootstrap/track/reset-request et verify-reset OTP (quatre au total) n'exigent pas JWT au gateway ; vérifier leur authentification interne, limitation de débit et nécessité ; ne pas les désactiver sans analyse.
Ne jamais appliquer 000 à l'aveugle sur la production existante. Construire une migration de réconciliation avant uniquement à partir du catalogue réel, tester sur copie isolée, sauvegarder et restaurer avant déploiement. Les versions horodatées du registre Gate ne correspondent pas aux préfixes locaux : réconcilier explicitement, ne pas utiliser migration repair sans preuve.

## Advisors live
| Finding | Gate | Production |
|---|---:|---:|
| RLS sans policy (INFO) | 4 | 0 signalé |
| SECURITY DEFINER exécutable authenticated (WARN) | 41 | 0 signalé |
| Protection mots de passe compromis désactivée (WARN) | 1 | 1 |
| FK non indexées | 45 | 22 |
| RLS initplan | 39 | 38 |
| Index inutilisés | 128 | 147 |
| Policies permissives multiples | 83 | 83 |
| Index dupliqués | 8 | 8 |

Quatre tables sans policy : company_settings, customer_product_prices, operational_treasury_postings, stock_handovers. Peut être intentionnel via RPC ; vérifier grants et refus directs, ne pas ouvrir d'accès par défaut. Les 41 RPC ne constituent pas 41 failles démontrées : vérifier rôle, tenant, search_path, privilèges et tests négatifs individuellement. Index inutilisés sur base presque vide : ne pas les supprimer sans observation en charge. Références : [RLS](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy), [RPC](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable), [mot de passe](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection), [performance](https://supabase.com/docs/guides/database/database-linter).

## Priorités de sortie
1. P0 : rejeu 000 puis 001–024 sur environnement vierge autorisé ; 66/66, plus suites 018–024 ; confirmer registre, grants, Storage et cron.
2. P0 : figer SHA candidat, Flutter analyze/test/build web, Edge tests, APK Android avec SHA-256 ; parcours métiers web et mobile de tous les rôles, ajouter magasinier et tests B2B croisés.
3. P0 : invitation et OTP réels, changement obligatoire, bootstrap, secrets Vault et dispatch réellement reçu ; confirmer toutes Edge nécessaires et éliminer endpoints obsolètes après analyse.
4. P0 : revue RPC/RLS, protection mots de passe, sauvegarde/restauration, plan de réconciliation production testé sans perte, configuration réelle société/stock/taux/comptes d'ouverture.
5. P1 : performances (FK, RLS, index dupliqués), tests de charge, observabilité et alertes, signature Android release.
6. P2/P3 : audit fonctionnel approfondi des modules sécurité/forensique/automatisation, IA, comptabilité générale et clôtures, iOS si cible retenue.
7. Gate de décision : preuves liées au même SHA, approbation métier et technique, PR #13 sortie de draft puis fusion uniquement après accord. GitHub Actions reste exclu du protocole Gate actuel ; équivalent externe documenté exigé.

## Limites
Audit documentaire et inventaire live, pas un pentest, pas une revue ligne à ligne exhaustive ni un rejeu. Aucun secret lu ou publié, aucune écriture DB, aucun test d'email ni APK exécuté ici. Les phases historiques restent archivées et ne doivent pas être interprétées comme état courant.
