# Gate cloud — depuis Android

> **Current status — 2026-11-25:** Gate already contains migrations 000–024. Do not reset it for baseline testing; use a separate authorized environment. Never transmit service-role keys or DB passwords in chat or GitHub; use a private secret store. No new credentials are required for this read-only audit. [Current audit](docs/gate_audit_2026-11-25.md).


Le projet de test existe déjà, dans l’organisation Nexa Inc. Ouvrir [loliexpress-gate-test](https://supabase.com/dashboard/project/muzbwqxvamcbfiuehxro). LoliExpress Management System et LoliExpress Staging Go-Live sont déjà en pause.

1. Dans **Settings → Database**, réinitialiser le mot de passe du projet de test. Choisir un mot de passe unique, car celui proposé initialement figure dans la conversation.
2. Dans [API Keys](https://supabase.com/dashboard/project/muzbwqxvamcbfiuehxro/settings/api-keys), récupérer la clé publique `anon` et, dans l’onglet des clés historiques, la clé `service_role`.
3. Dans **Connect → Session pooler**, copier la chaîne de connexion complète. Remplacer le mot de passe fictif par celui du projet. Le mode Session utilise généralement le port `5432`. Copier l’hôte exact affiché.
4. Transmettre les quatre valeurs à Codex par le canal privé prévu. Utiliser des secrets de l’environnement Codex si disponibles. Éviter les commentaires GitHub, les captures et Codemagic pour les deux dernières valeurs.

| Clé | Valeur attendue |
|---|---|
| `CLOUD_SUPABASE_URL` | `https://muzbwqxvamcbfiuehxro.supabase.co` |
| `CLOUD_SUPABASE_ANON_KEY` | Clé publique `anon` |
| `CLOUD_SUPABASE_SERVICE_ROLE_KEY` | Clé serveur du projet jetable |
| `CLOUD_SUPABASE_DB_URL` | Chaîne complète du pooler Session |

Codex vérifie la cible et conduit les vérifications cloud et web. La [passation Codemagic](CODEMAGIC_HANDOFF.md) et le [guide Android](MOBILE_HANDOFF.md) couvrent l’installation et les preuves mobiles.
