# Assistant IA

> **Current status — 2026-11-25:** Gate HTTP evidence: admin 200, acheteur 403; response accuracy, configured provider and predictive cron remain unverified. Do not expose LLM keys or confidential data. [Current audit](gate_audit_2026-11-25.md).


L’assistant IA est accessible via `/ai-assistant` pour les rôles autorisés.

Toutes les requêtes passent par l’Edge Function `ai_assistant`; aucune clé LLM n’est exposée dans Flutter. La fonction choisit une fonction SQL de reporting pré-agrégée selon la question (`get_admin_sales_report`, `get_admin_finance_report`, `get_admin_operations_report`, `get_admin_total_report`) puis reformate la réponse avec `OPENAI_API_KEY` si configurée.

Variables Edge Function:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `OPENAI_API_KEY` optionnel
- `OPENAI_MODEL` optionnel

La génération d’alertes prédictives simples est assurée par `generate_ai_insights()` et peut être planifiée via cron.
