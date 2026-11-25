# Index des preuves

- [Audit initial](../../docs/gate_audit_2026-11-25.md) à `6a98532`.
- [Assertions SQL ciblées](../../gate_state/current/sql-assertions.json) et [connexions Web](../../gate_state/current/web-login-routes.json) du lot `9ff342b`.
- [Résultats Edge](../../gate_state/current/edge-browser.json) et [rapport du gate](../../FINAL_VERIFICATION.md).
- [Collecteur de drift](collect_drift.py) et [requête du catalogue](catalog.sql). Exécution avec `SUPABASE_PAT` injecté dans l’environnement et un chemin de sortie. Les deux projets sont contrôlés par nom et référence. Le SQL utilise une transaction en lecture seule.
- [Résumé de collecte Gate](gate_catalog_summary.json) et [Advisors Gate après 025](gate_advisors.json). La collecte comparative s’arrête au refus HTTP 403 de Production. L’option `--gate-only` collecte le côté autorisé.
- Migration 025 appliquée sur Gate. [Droits de la file](verify_notification_grants.sql), [lecture et envoi indépendants](../verify_notification_read.sql), [préférences isolées](../verify_notification_center_preferences.sql), [rapprochement](../verify_operational_treasury.sql) et [quatre tables sans accès direct](verify_rpc_only_tables.sql) passés par API HTTPS.
- Flutter 3.35.7, Dart 3.9.2. Analyse sans erreur ni avertissement, quatre remarques antérieures. Tests Flutter 18/18.
- Candidat `ed4b52d`. [Rapport du gate local](release_gate_results.json) et [matrice de trésorerie](RPC_SECURITY_MATRIX.md). Migration 026 appliquée sur Gate. Huit suites SQL, analyse sans remarque, 18 tests Flutter, build Web et 7 tests Deno passés. Sept vérifications restent indiquées `NOT_RUN`.
- Quatre tables protégées. [12 lectures REST](rest_rpc_only.json) sans exposition de données et [inventaire des vues dépendantes](rpc_only_views.json) vide. [Requête reproductible](rpc_only_view_inventory.sql).
- [Rejeu de baseline](replay_baseline.py). Garde testée contre la référence du Gate existant, qui est refusée avant toute connexion. Rejeu réel en attente d’un projet vierge autorisé.
- [Test multisession du transfert](test_concurrent_transfer.py) et [preuve](concurrent_transfer.json) sur le même code applicatif que `ed4b52d`. Deux sessions distinctes et chevauchantes, un refus faute de stock et stock total conservé. Les fixtures du premier essai et du rejeu ont été retirées.
- Migration 027 appliquée au projet Gate. [Frontière livreur](verify_delivery_client_boundary.sql) et [20 assertions ciblées, remise, commande et stock](delivery_boundary_results.json).
- [Double confirmation concurrente](concurrent_handover.json) sur Gate. Deux sessions PostgreSQL distinctes et chevauchantes, deux réponses positives, une seule remise, une sortie de stock, fixturation retirée.
- [Lot 028, file de réception](warehouse_receipt_results.json) et [contrôle SQL reproductible](verify_warehouse_receipt_queue.sql). La file n’expose pas les coûts et vérifie le rôle en base. Les assertions achats, réception et brouillons ont été rejouées sur Gate.
- [Réception fournisseur concurrente](concurrent_receipt.json) à `7350ad2`. Rejouable via `test_concurrent_receipt.py` et le paramètre `--with-gate-fixtures` du gate.
- [Réception réelle depuis Flutter Web](warehouse-web.json), [capture](warehouse_web.png), [script](test_warehouse_receipt_web.py). Compiler le Web en configuration Gate avant le test. Fournir le PAT dans l’environnement, le fichier local ignoré `cloud.env`, et lancer le script avec `--evidence-dir` depuis la racine. Le script crée puis retire un compte et les références jetables sur Gate.
- [Encaissements concurrents](concurrent_payment.json) et [ventes concurrentes](concurrent_sales.json) sur Gate. Sessions distinctes, chevauchement, un succès et un refus par scénario, journaux rapprochés et données jetables retirées.
- [Périmètre commandes et facturation](order_invoice_scope_results.json). Quatre refus attendus et émission par le comptable au tarif du client. La transaction de test est annulée.
