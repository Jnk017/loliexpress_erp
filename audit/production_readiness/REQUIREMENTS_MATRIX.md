# Matrice des exigences

| ID | Priorité | Exigence | Preuve de clôture |
|---|---|---|---|
| DB-001 | P0 | Drift catalogue Gate–Production | Collecte live reproductible et limites documentées |
| DB-002 | P0 | Baseline et suites supplémentaires | 66/66 et rejeu depuis zéro |
| DB-003 | P0 | Réconciliation forward-only | Copie de production migrée, réconciliée et restaurée |
| SEC-001–005 | P0 | RPC, RLS, RBAC, secrets et Advisors | Tests négatifs et zéro risque élevé ou critique ouvert |
| AUTH-001 | P0 | Cycle Auth | Invitation et OTP reçus, restrictions, sessions et deep links validés |
| ERP-001–011 | P0 | Commercial, facturation, achats, stocks, livraison, retours, trésorerie, comptabilité, dépenses, B2B, paramètres | Chaînes interface–base vérifiées, opérations rapprochées et règles approuvées |
| EDGE-001–002 | P0 | Fonctions et notifications | Tests HTTP et livraison effective sur les canaux retenus |
| AI-001 | P1 | IA et rapports | Vérification des accès, des agrégats et du repli |
| OPS-001 | P0 | Observabilité, alertes, sauvegarde et restauration | Exercices exécutés et RPO/RTO mesurés |
| PERF-001–003 | P1 | SQL, Flutter et concurrence | Mesures avant/après et vérification sous concurrence |
| UX-001 | P1 | UI et accessibilité | Revue et preuves sur les tailles et thèmes pris en charge |
| WEB-001 | P0 | Parcours Playwright | Sept rôles et deux identités B2B avec données distinctes |
| MOB-001–003 | P0 | Compilation, artefacts et Android | APK identifié, preuves sur appareil et signature de diffusion |
| DOC-001 | P1 | Documentation actuelle | Guide d’installation, d’exploitation et d’usage vérifiés |
| REL-001 | P0 | Candidat de release | Preuves liées au SHA et certificat interne validé |

| ID | Priorité | Exigence atomique | Preuve de clôture |
|---|---|---|---|
| SEC-001-A | P0 | Six signatures financières et frontière d’écriture des journaux | Matrice RPC, refus par rôle et rapprochement en CDF et USD |
| SEC-001-B | P0 | Autres signatures privilégiées | Revue et tests des 35 signatures restantes |
| REL-001-A | P0 | Orchestrateur local indépendant | Rapport machine-readable qui distingue les tests réussis, en échec et non lancés |
| DB-002-A | P0 | Script de rejeu de baseline | Refus des cibles existantes et rejeu réel sur une cible autorisée |
| SEC-002-A | P0 | Quatre tables à accès indirect | Contrôles REST, vues et fonctions indirectes |
| PERF-003-A | P0 | Transferts concurrents sur un stock limité | Sessions distinctes, chevauchement, quantité et journal rapprochés, fixtures retirées |
| SEC-003-B | P0 | Livraison affectée accessible en lecture avec confirmation par RPC | Mise à jour directe refusée et régression de remise réussie |
| PERF-003-C | P0 | Confirmations concurrentes de la même remise | Deux sessions chevauchantes, une remise et une sortie, nettoyage confirmé |
| WEB-001-A | P0 | Réception magasinier depuis le raccourci Stock | Connexion magasinier, liste opérationnelle en lecture limitée, réception et réconciliation PostgreSQL |
| PERF-003-D | P0 | Réceptions concurrentes avec la même clé de requête | Deux sessions chevauchantes, un reçu, un mouvement et stock rapproché |
| PERF-003-E | P0 | Encaissements concurrents sur une même créance | Un paiement accepté, un refus, un seul mouvement, solde rapproché |
| PERF-003-F | P0 | Remise concurrente de deux commandes sur stock limité | Une remise, une commande reste expédiée, aucun stock négatif |
| SEC-001-C | P0 | Prix, commandes et émission selon l’identité | Tests positifs par acteur, refus hors affectation et accès B2B croisé |
| WEB-001-B | P0 | Création d’achat depuis Flutter Web | Choix fournisseur et produit autorisés, achat persisté, puis réception vérifiée |
| SEC-001-D | P0 | Onze prédicats de rôle | Matrice de dix états de profil et grants vérifiés |
| SEC-001-E | P0 | Réglages, progression et rapport administrateur | Refus, accès légitime et régressions métier |
| SEC-001-F | P0 | Dix signatures du dernier groupe | Privilèges effectifs, refus et tests positifs individuels |
| SEC-001-F1 | P0 | Annulation d’achat | Annulation autorisée et idempotente, refus après réception ou facturation |
| SEC-001-B1 | P0 | Limiter les opérations de stock et de transition du livreur | Cinq refus et régression du parcours de remise |
| SEC-004-A | P0 | Exclure le coût du catalogue REST | Projections publiques acceptées et coût refusé sous les rôles clients |
| WEB-001-C | P0 | Commande commerciale avec tarif et stock réels | Stock lu et tarif appliqué depuis Flutter, commande persistée sans sortie avant remise |
| SEC-001-F2 | P0 | Recherche de retour avec le rôle magasinier | Positif après remise, reliquat mis à jour, déclaration de revendabilité refusée |

**ERP-005-PLAN** — P0 · TEST_PASSED · Planifier une livraison depuis une commande expédiée. Le serveur contrôle le rôle, l’entrepôt et le livreur. Tests Gate positifs et négatifs réussis. Validation Chromium réussie sur Gate. Recette Android en attente. [Preuve Web](delivery-web.json). [Preuve SQL](delivery_planning_results.json).
