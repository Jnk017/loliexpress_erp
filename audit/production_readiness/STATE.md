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
