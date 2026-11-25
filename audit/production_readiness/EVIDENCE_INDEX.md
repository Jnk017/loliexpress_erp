# Index des preuves

- [Audit initial](../../docs/gate_audit_2026-11-25.md) à `6a98532`.
- [Assertions SQL ciblées](../../gate_state/current/sql-assertions.json) et [connexions Web](../../gate_state/current/web-login-routes.json) du lot `9ff342b`.
- [Résultats Edge](../../gate_state/current/edge-browser.json) et [rapport du gate](../../FINAL_VERIFICATION.md).
- [Collecteur de drift](collect_drift.py) et [requête du catalogue](catalog.sql). Exécution avec `SUPABASE_PAT` injecté dans l’environnement et un chemin de sortie. Les deux projets sont contrôlés par nom et référence. Le SQL utilise une transaction en lecture seule.
- [Résumé de collecte Gate](gate_catalog_summary.json) et [Advisors Gate après 025](gate_advisors.json). La collecte comparative s’arrête au refus HTTP 403 de Production. L’option `--gate-only` collecte le côté autorisé.
- Migration 025 appliquée sur Gate. [Droits de la file](verify_notification_grants.sql), [lecture et envoi indépendants](../verify_notification_read.sql), [préférences isolées](../verify_notification_center_preferences.sql), [rapprochement](../verify_operational_treasury.sql) et [quatre tables sans accès direct](verify_rpc_only_tables.sql) passés par API HTTPS.
- Flutter 3.35.7, Dart 3.9.2. Analyse sans erreur ni avertissement, quatre remarques antérieures. Tests Flutter 18/18.
