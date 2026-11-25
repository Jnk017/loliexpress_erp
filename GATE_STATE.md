# Gate final LoliExpress ERP

> **Current status — 2026-11-25:** Current snapshot supersedes older FAIL/NOT_RUN entries: SQL 56 PASS, 1 FAIL, 9 baseline checks pending; web login 7/7; Android and notifications delivery open. [Current audit](docs/gate_audit_2026-11-25.md).


## Moyens de paiement clients et fournisseurs

- Migration 021 appliquée au projet de test. Cash, Mobile Money et virement bancaire sont enregistrés comme moyens distincts. Un portefeuille Mobile Money est un compte de trésorerie catégorisé, avec solde séparé du compte bancaire dans le tableau financier. Aucun compte ni solde initial ajouté.
- Le scénario SQL de trésorerie a enregistré les trois moyens des deux côtés, confirmé la séparation des soldes, refusé un compte de catégorie ou de devise incompatible et annulé toutes les données de test.
- Analyse Flutter : 0 erreur, 0 avertissement. Tests : 18 PASS. Parcours Android restant à vérifier sur un APK récent.

## Achats, ventes, stock et trésorerie

- Migration 020 appliquée au projet de test. L'encaissement client, le règlement fournisseur et le paiement des dépenses exigent désormais une caisse ou une banque active dans leur devise. La dette, la créance ou la dépense et le mouvement de trésorerie sont mis à jour dans une transaction unique. Les anciens appels authentifiés sans compte sont fermés.
- [Scénario réconcilié](audit/verify_operational_treasury.sql) sur données annulées : stock `10 + 8 - 3 = 15`, caisse CDF `100 + 25 - 15 = 110`, banque CDF `200 - 40 + 35 = 195`, caisse USD `10 - 2 = 8`. Refus des comptes d'une autre devise et contrôle des tentatives répétées. Les 13 assertions de remise et retour ainsi que le test transfert/comptage sont repassés.
- Flutter : 18 tests PASS. Sélecteur dans Encaissement, Règlement fournisseur et Paiement de dépense. Soldes par compte et agrégats séparés CDF/USD. Créances nettes des avoirs, dépenses mensuelles selon date de paiement.
- Au contrôle avant migration, aucun compte de caisse ou de banque actif sur le projet de test. Les soldes d'ouverture historiques n'ont pas été imputés. Les parcours sur téléphone nécessitent un nouvel APK et des comptes de test configurés.

## Retour Android — opérations de stock

- Migration 019 appliquée au projet de test gardé. Transfert atomique et inventaire physique par article et entrepôt, avec motif, contrôle serveur du rôle et journalisation. Les options sont disponibles dans Actions rapides pour admin et magasinier.
- Le [test SQL](audit/verify_stock_transfer_and_count.sql) a retourné `stock_workflows_pass=true`. Il couvre conservation des quantités, dépassement du disponible, quantité périmée, comptage sans écart et refus B2B. Les données créées par le test ont été annulées.
- Tests Flutter : 18 PASS. Vérification des deux parcours sur le nouvel APK et le téléphone encore ouverte.

## Retour Android — rapport admin, paramètres et stock

- Sur le projet de test uniquement, la migration 018 accorde EXECUTE sur le rapport agrégé à la session authentifiée. Le contrôle de rôle interne reste actif. Le contrôle HTTPS, sous le rôle PostgreSQL authentifié avec les identités de test, a confirmé `admin_report_ok=true` et `b2b_read_denied=true`. Aucun appel au projet de production.
- Les paramètres réutilisent les couleurs du thème pour les textes, icônes et surfaces. Les commandes fictives de sauvegarde, intégrations et sécurité ont été retirées de cet écran. Les entrepôts et l’accès à la gestion des utilisateurs utilisent les services existants.
- Les trois onglets du stock utilisent les données Supabase. Filtre par identifiant d’entrepôt, réception via Achats, ajustements via `adjust_stock`. Transfert et inventaire physique restent indisponibles en l’absence de parcours transactionnel dédié.
- La vérification du nouvel APK sur téléphone demeure ouverte. Le gate global reste en échec.

## Gate cloud — résultat courant

**ÉCHEC.** Les migrations 000–017 sont appliquées. Les quatre suites SQL ont retourné 57 assertions vraies. Les neuf contrôles de l’état exact après 000 restent à exécuter sur une baseline isolée autorisée. Aucun résultat déduit du schéma à 017. [Matrice](audit/gate/assertions.tsv)

| Contrôle | Résultat |
|---|---|
| Comptes Auth et profils E2E | 7/7 |
| Flutter pub get | PASS |
| Tests Flutter | 16/16 après deux corrections ciblées |
| Analyse et build web | Bloqués par le dossier personnel en lecture seule, même après une demande d’accès aux deux répertoires Dart |
| Edge Functions | 7/7 tests unitaires Deno. Intégration déployée NOT_RUN |
| Playwright API Auth et profils | 7/7 |
| Playwright E2E interface web | 0/7 exécuté. Aucun build web ni capture |
| Android | Déclenchement demandé via push. APK et captures à confirmer |

[Résultats Flutter](gate_state/flutter-rerun-status.txt) · [Tests Edge](gate_state/edge-verify.log) · [Sonde Playwright](gate_state/playwright-auth-smoke.json) · [Passation Android](MOBILE_HANDOFF.md)

## Comptes E2E cloud

Sept comptes Auth de test créés et sept profils applicatifs vérifiés via la cible gardée. Deux fiches B2B liées aux comptes correspondants. Le fichier local `.env.test` est en mode 0600 et ignoré. Ce commit contient uniquement la preuve de provisionnement.

## Assertions cloud — 57/66 PASS

Les quatre groupes ont été exécutés via l’API Management officielle avec PAT et garde de référence. P0.a : 5/5 après déplacement de l’identifiant JWT de l’administrateur avant l’insertion de la fixture auditée. P0.b : 13/13. P1.a : 34/34. P1.b : 5/5. Les scripts conservent le rollback. HTTP 201 avec résultats booléens explicites. Les neuf assertions sur l’état exact après `000` restent `NOT_RUN`, car la cible autorisée est déjà à `017`. Le rapport ne déduit aucun résultat de ces neuf assertions depuis le schéma final.

## Rejeu 000–017 — API Supabase officielle et PAT

Le projet `loliexpress-gate-test` (`muzbwqxvamcbfiuehxro`) a été vérifié par son nom et son identifiant, avec zéro table publique avant rejeu. La CLI en mode `--include-all --dry-run` a rencontré un refus TCP du pooler. Les 18 migrations ont ensuite reçu HTTP 200 sur l’API officielle, avec PAT et vérification de la référence avant chaque requête. Les quatre RPC clés sont présentes après rejeu. [Empreintes et statuts](audit/gate/cloud-pat-migrations.tsv)

L’essai antérieur via le connecteur avait été refusé. La baseline contient notamment des instructions conditionnelles de remplacement de politiques et triggers. Aucune commande autonome de suppression de données n’a été lancée. Les assertions SQL et les parcours restent `NOT_RUN`. Aucun appel à la production ni à GitHub Actions.

## Gate G0.8 — reprise via Supabase HTTPS

- Connecteur Supabase existant, limité au projet de test `muzbwqxvamcbfiuehxro`. Le jeton communiqué n’a été ni utilisé ni stocké.
- Migration `000_baseline_active`, SHA-256 `9fc6282beeb67df5e1aba44c452a494a184988ca819e283ae0b4843bd899d54a`. Réponse du connecteur : `status=declined`, « Migration was declined. » Aucun motif détaillé. Contrôle après refus : toujours zéro table publique. Aucun contournement utilisé. Migrations 001–017, 66 assertions et provisionnement E2E `NOT_RUN`.
- Flutter : `pub get` PASS. Analyse et build web interrompus par le home en lecture seule. Tests Flutter : 14 PASS, deux échecs (initialisation Supabase dans le widget d’invitation et signature `exchangeRate` du fake de dépôt).
- Deno : 7/7 tests unitaires Edge PASS. Déploiement Edge, intégration cloud, parcours web/mobile et APK `NOT_RUN`.
- Verdict : **ÉCHEC**. Étape suivante côté cloud : donner suite à la demande d’approbation de la migration 000 si elle est présentée. GitHub Actions exclu.

### Empreintes des journaux locaux

- `cloud-flutter-status.log` — SHA-256 `91b8274f99844f98d90ecc69c64ca984689bff3b40571d7213f42ffa009726d3`.
- `cloud-flutter-analyze.log` — SHA-256 `7151905058327b18964eb5d65b88980e0d5147673409bc629988a993371da537`.
- `cloud-flutter-test.log` — SHA-256 `b91efa8ce2beeb081138cc33e088b9eae96d862630cb0e200a9eaa93c5b8a60a`.
- `cloud-flutter-build.log` — SHA-256 `9e417b2ed67762ace0d2c263b887822b9faf2e91a19dc1c5361c1a636f3df0ad`.
- `cloud-edge-unit.log` — SHA-256 `dba5803c30ae48b9ce7ab30d8e67f496b6ed01238c4806937e19c2f5013e10d9`.

## Reprise G0.8 — diagnostic de connexion cloud

- Cible confirmée : projet de test `muzbwqxvamcbfiuehxro`. Auth HTTPS renvoie 200 avec la clé publique. Le connecteur Supabase confirme PostgreSQL 17.12 et zéro table applicative dans `public`, en lecture seule.
- La connexion `psql` par le pooler Session échoue avant authentification avec `Connection refused`. Le mot de passe et la clé serveur restent à valider. Les quatre paramètres sont stockés dans `cloud.env`, mode 0600, dans le checkout puisque le home est en lecture seule. Le fichier est ignoré par Git.
- Arrêt à la vérification de connexion demandée. Aucun SQL de migration ni assertion exécuté, aucun compte créé. Prochaine décision : rétablir l’accès TCP au pooler depuis l’hôte, ou autoriser le connecteur HTTPS Supabase comme transport du gate SQL.

## Amendements G0

### G0.8 — Pivot cloud strict (23 novembre 2026)

- Validation humaine explicite. L’hôte disposait de 340 Mio libres, sans sudo, et l’opérateur utilise exclusivement Android.
- Supabase cloud dédié pour SQL, Edge et backend E2E. Codemagic réservé à la compilation APK. Flutter, Playwright, psql et Deno restent exécutés sur l’hôte Codex. GitHub Actions reste exclu.
- La purge a supprimé six images Supabase inutilisées. Docker annonce 1,066 Go récupérés. Espace libre observé après purge : 3,9 Gio. Journal local `audit/gate/cloud-pivot-prune.log`.
- Inventaire de gestion Supabase : LoliExpress Management System et LoliExpress Staging Go-Live sont déjà `INACTIVE`. Le projet dédié `muzbwqxvamcbfiuehxro` est `ACTIVE_HEALTHY` à `eu-west-1`. Aucun doublon créé, aucun changement à `loliexpress_erp`.
- Attente des paramètres du projet de test. Aucune connexion PostgreSQL, migration, assertion ni compilation lancée pendant cette étape. [Passation Android](CLOUD_HANDOFF.md)

## Bootstrap — Step −1.5, capacité Docker et remise mobile

- **ATTENDRE HUMAIN** pour le stockage géré. Cas A sur le système observable : `/`, `/workspace`, `/home` et `/tmp` affichent 7,9 Gio au total et 340 Mio disponibles. Le daemon rootless utilise `vfs` et `/home/dockerd/.local/share/docker`. Le compte agent ne peut pas mesurer ce chemin directement et `sudo` est absent.
- Docker affiche six images pour 1,066 Go récupérables et zéro conteneur, volume ou cache de build. Un prune du cache réutilisable ne permettrait pas d'atteindre les 15 Gio exigés. Aucune purge ou relocalisation effectuée. [Procédure opérateur](audit/gate/BOOTSTRAP_OPERATOR.md) · [Contrôle de capacité](audit/gate/check-docker-capacity.sh)
- Journal local `audit/gate/bootstrap-step-minus-1-5-storage.log`, code 2 (data-root inaccessible), SHA-256 `0306daf2a63dfef35c1772deea724b8afef2c2ec3d37d026743bcbfc17f3eb45`.
- Pile, quatre sondes, rejeu, 66 assertions et parcours web/mobile `NOT_RUN` à cette itération. Les options ADB/LAN/tunnel attendent la pile. Le gate web pourra reprendre indépendamment du téléphone dès que la pile sera validée.
- Checklist webhook, groupe de variables et déclenchement humain documentés. Codemagic reste build-only. Webhook, variables et APK non confirmés. [Remise Codemagic](CODEMAGIC_HANDOFF.md)
- GitHub Actions exclu. Aucune connexion à Supabase actif.

## Publication de l’assemblage — 23 novembre 2026

- Étape 1 assemblée sur `gate/final-verification` au commit `4dedf468cd6c009e0d2c77b53661c0ab6945333c`. Push confirmé, `main` vérifiée à `5a68a999ca15bde01804185fa884e12d7ca09866`. [PR brouillon #13](https://github.com/Jnk017/loliexpress_erp/pull/13)
- `.env.test` vérifié par `git check-ignore`. Le commit d’assemblage laisse les workflows GitHub existants inchangés et porte `skip-checks: true` pour la PR. Les logs bruts restent dans le workspace.
- Le déclencheur Codemagic est limité aux pushes de la branche du gate. L’activation du webhook, les variables isolées et l’APK restent à confirmer. Les résultats SQL, web et mobile restent `NOT_RUN`. Les obstacles de stockage Docker et de joignabilité mobile persistent.
- Les entrées « aucun push » ci-dessous décrivent les itérations antérieures à cette publication.

## Bootstrap — reprise B7/B8, téléphone physique

**Décision de continuité — ATTENDRE HUMAIN.** Le gate v4.1 n'a pas repris. Prérequis de reprise : davantage de stockage pour la pile Docker locale, et une route privée vers le téléphone (ADB reverse sur un poste qui rejoint la pile, ou un LAN de test vérifié depuis le téléphone).

| Vérification | Résultat et preuve |
|---|---|
| B7 — SDK et build local | SDK Android 36, build-tools et ADB installés. Gradle 8.11.1 chargé. La compilation de diagnostic échoue sur l'écriture de la dépendance Kotlin dans le cache, puis la relance automatique atteint le délai de 180 s (124). Aucun APK. La modification automatique de `minSdkVersion` par Flutter a été annulée, diff Android vide. [Build](audit/gate/bootstrap-b7-apk.log) |
| B7 — Codemagic | Configuration build-only préparée et contrôlée statiquement. Aucun job lancé, APK absent, aucune capture (0/7 parcours). Pas de destinataire de notification configuré. [Remise mobile](MOBILE_HANDOFF.md) |
| B8 — Supabase PG17 | Six images déjà disponibles. Démarrage local interrompu volontairement pendant un téléchargement Docker (289,5/353,1 MB) lorsque le workspace a atteint 100 % affichés, avec environ 58 Mo disponibles. Sortie 143. [Démarrage](audit/gate/bootstrap-b8-pg17.log) |
| B8 — quatre contrôles | Auth, boîte Mailpit et PostgreSQL : connexions loopback refusées. Réception de courriel : `NOT_RUN`, serveur de messagerie indisponible. [Sondes](audit/gate/bootstrap-b8-probes.log) |
| B8 — authentification | Sept identifiants générés en privé. 0/7 comptes Auth créés, 0/7 rôles assignés, `.env.test` absent. Le seed doit suivre le démarrage de la pile et le chargement du schéma applicatif permettant l'affectation des rôles. |
| B8 — URL mobile | Cible ADB non fournie, démarrage ADB local bloqué par le home en lecture seule. Aucun service sur les deux adresses LAN candidates. Aucun outil de tunnel détecté. Pas d'URL embarquée. [ADB](audit/gate/bootstrap-b7-adb.log) |

66 assertions, tests Flutter/Edge et parcours web/mobile `NOT_RUN`. Aucun appel à Supabase actif, aucun commit ou push, aucun déploiement. GitHub Actions exclu.

### Exceptions G0

- Codemagic build-only préparé le 23 novembre 2026 après l'échec de la compilation locale avec SDK installé. Périmètre validé par l'utilisateur : résolution des dépendances et `flutter build apk --debug` uniquement. Aucune exécution Codemagic pendant cette itération.

- G0 : GitHub Actions exclu. Codemagic éventuel uniquement après tentative locale de compilation, réservé au build, jamais lancé par Codex.
- Checkout assemblé confirmé à `5a68a999ca15bde01804185fa884e12d7ca09866`. Aucun commit ni push.
- B7 : aucun `B7_ADB_TARGET`, aucune surcharge de mode et aucune chaîne Android initialement prête. Priorité donnée à l'installation locale du SDK Android, en cours. Flutter 3.35.7 compile contre Android 36 selon `FlutterExtension.kt`. [Journal Android](audit/gate/bootstrap-b7-android-install.log)
- B8 : sept jeux d'identifiants de test générés localement, fichier privé mode 0600. Clés de profils : `commercial`, `comptable`, `acheteur`, `admin`, `livreur`, `b2b_a`, `b2b_b`. Aucun mot de passe, clé de service ou jeton dans le journal. Création Auth et affectation des rôles en attente de la pile et du schéma.
- La configuration de la sonde initiale épinglait Postgres 15. Démarrage remplacé par une pile indépendante `loli-gate-local` avec Postgres 17, dossier de migrations vide et seeds désactivés. [Log filtré de la pile](audit/gate/bootstrap-b8-pg17.log)
- Route mobile : aucun accès ADB explicite. Le portail Cloud annonce SSH uniquement, aucun portail HTTP configuré pour le service et aucun binaire cloudflared/ngrok détecté. La joignabilité depuis le téléphone reste à prouver.

## Bootstrap — reprise Step −1.0 et Step −1.2

- **B1 RÉSOLU**. Clone HTTPS de `main` dans `/workspace/work/loli-verify`. Première tentative arrêtée par le proxy local ; clone réussi avec l'accès réseau autorisé. [Log du clone](audit/gate/bootstrap-clone-network.log).
- Cas A : commit objet de Git et ancêtre de `main`. Branche locale `gate/final-verification` au SHA `5a68a999ca15bde01804185fa884e12d7ca09866`. `pubspec.yaml`, fonctions Edge et tests présents. [Log du checkout](audit/gate/bootstrap-checkout.log).
- Overlay : 18 migrations copiées octet pour octet depuis `/workspace/migrations` vers `supabase/migrations`, historique de 27 migrations conservé séparément dans `supabase/historical_migrations`. Alias local `migrations` vers la séquence active pour les scripts existants. Entrées de vérification et preuves depuis `/workspace/audit`, modifications Flutter depuis `/workspace/lib`, configuration depuis `/workspace/supabase/config.toml`, rapports depuis `/workspace`. Les fonctions Edge et tests viennent du clone officiel.
- B2 en cours. Installation épinglée à `3.29.3`, version indiquée dans `AGENTS.md`. Cache par défaut non inscriptible, puis démarrage avec `PUB_CACHE=/workspace/work/tools/pub-cache` et caches XDG locaux. Flutter 3.29.3/Dart 3.7.2 s'exécutent, mais `flutter pub get` échoue sur `pdf ^3.12.0` (vector_math 2.2.0) contre le verrou Flutter 2.1.4. [Log de la résolution](audit/gate/bootstrap-b2-flutter-local-cache.log).
- Le manifeste public `flutter_test` des tags 3.35.7, 3.38.9 et 3.41.9 fixe vector_math 2.2.0. **B2 résolu** avec Flutter 3.35.7 et Dart 3.9.2. La première résolution a actualisé le verrou mais quitté avec le code 1. La relance locale `flutter --suppress-analytics --verbose pub get` a donné le code 0. `pubspec.yaml` est intact, `pubspec.lock` modifié par le solveur dans le clone. [Vérification des tags](audit/gate/bootstrap-b2-sdk-compatibility.log) · [Versions et résolution](audit/gate/bootstrap-b2-flutter-3.35.7.log) · [Relance](audit/gate/bootstrap-b2-pub-retry.log).
- Aucun commit, push, appel à Supabase actif ni accès à GitHub Actions.

### Classification et remédiations

| Blocage | Catégorie constatée | Action et preuve |
|---|---|---|
| B2 Flutter/Dart | Installable, réseau nécessaire au téléchargement | 3.35.7 / 3.9.2, cache workspace et `pub get` code 0. |
| B5 Deno | Installable | Archive Linux officielle extraite dans `work/tools/bin`, version 2.9.8. [Log](audit/gate/bootstrap-b5-deno.log) |
| B3 Supabase CLI / psql | Installable sans root | La CLI latest essayait de créer un dossier dans le home en lecture seule. Version Go 2.79.0 fonctionnelle. `psql 17.12` extrait d'un paquet Debian sans apt install. Les URL et SHA-256 figurent aux [logs CLI](audit/gate/bootstrap-b3-supabase-pinned.log) et [psql](audit/gate/bootstrap-b3-psql.log). |
| B6 Chromium | Installable / configuration locale | Playwright 1.62.0 et Chromium 156.0.8078.79 présents. Le test avec flags demandés et accès réseau autorisé lance le navigateur. La politique refuse `data:` ; la [sonde HTTP loopback](audit/gate/bootstrap-chromium-smoke.cjs) renvoie `ok`. [Log](audit/gate/bootstrap-b6-loopback.log) |
| B4 Docker | Installable / accès réseau autorisé dans le sandbox | Client et daemon rootless 29.9.2 joignables. Le refus initial disparaît avec le profil réseau autorisé. Aucun changement root ou de groupe. [Log](audit/gate/bootstrap-b4-docker.log) |
| B7 Mobile | Matériel / reportable sur décision | Ni ADB, ni sdkmanager, ni émulateur, ni KVM. Seulement 5,5 Go libres au contrôle. [Log](audit/gate/bootstrap-b7-mobile.log) |
| B8 E2E | Nécessite réseau et données de test | `.env.test`, URL opérationnelle et identifiants de test absents. Sonde séparée `loli-verify-bootstrap`, sans migrations ni seed. Deux démarrages ont atteint leurs délais (240 s et 150 s, code 124) pendant les pulls. Auth et Inbucket non vérifiés en fonctionnement. [Premier essai](audit/gate/bootstrap-b8-stack.log) · [Relance](audit/gate/bootstrap-b8-stack-retry.log) |

- [Nouvel audit Step 0](audit/gate/bootstrap-step0-recheck.log) : les binaires, le SHA et le daemon sont confirmés sous profil réseau autorisé. Android et URL/identifiants E2E restent absents.
- Scripts prêts : [sonde de l'hôte](audit/gate/bootstrap-host-check.sh), [réaudit](audit/gate/bootstrap-re-audit.sh), [seed local E2E](audit/gate/seed-local-e2e.py). Syntaxes contrôlées ; seed en attente des valeurs privées et d'une pile ayant rejoué les migrations. Les instructions opérateur sont dans [BOOTSTRAP_OPERATOR.md](audit/gate/BOOTSTRAP_OPERATOR.md).
- **Décision de continuité : ATTENDRE HUMAIN**. Choisir une cible Android (émulateur sur hôte adapté, appareil ADB ou report explicite) et fournir les sept comptes et l'expéditeur de test par une voie privée. Après préchargement des images, revalider le démarrage local d'Auth et Inbucket. L'assemblage Git est disponible, mais le gate n'a pas repris. Les 66 assertions restent `NOT_RUN`.

## Bootstrap — Step −1.0 · Source du dépôt

- Décision de continuité : **ATTENDRE HUMAIN — B1 non résolu**.
- Recherche effectuée sous `/home`, `/workspace`, `/app`, `/srv` et `/opt`. Aucun `pubspec.yaml` trouvé. Le seul candidat, `/workspace/.git`, ne constitue pas un checkout exploitable. Git 2.56.1 est installé et ne peut pas lire le commit `5a68a99` dans ce candidat. `supabase/migrations/`, `supabase/functions/` et `test/` y sont absents.
- Preuve : [journal de recherche](audit/gate/bootstrap-step-minus-one-source.log), SHA-256 `b082def72ec65710c616a16a3101625311fa6f61a8b81740d3104cc583a32faf`.
- Prochaine action : obtenir l'URL et la branche à cloner, ou la confirmation du dépôt d'audit `Jnk017/loliexpress_erp` et de sa branche `main`, puis vérifier le checkout à `5a68a99` avant la classification B2–B8.
- B2–B8 et le réaudit Step 0 ne sont pas lancés dans cette itération. Le verdict du gate reste `ÉCHEC (prérequis)`. GitHub Actions est exclu. Aucune connexion à Supabase.

## Doctrine GitHub Actions

- Statut : **INDISPONIBLE — exclu du gate**.
- Application de la doctrine : Step 0 du 23 novembre 2026 UTC. Aucun accès aux workflows ni relance.
- Équivalents locaux : Git client disponible, checkout absent ; Flutter ✗ ; Dart ✗ ; Supabase CLI ✗ ; psql ✗ ; Docker client disponible, daemon inaccessible ; Deno ✗ ; Playwright et Chromium installés, lancement bloqué ; émulateur et ADB ✗.
- Contournements par émulateur Actions, runner ou workflow ad hoc : exclus.
- Dépendance cloud résiduelle : aucune utilisée. La cible E2E attendue est une pile isolée en loopback avec messagerie locale Inbucket.

## Step 0 — 2026-11-23

**Verdict : ÉCHEC (prérequis).** Les étapes 1 à 8 restent fermées.

| Prérequis | Statut | Version observée | Bloquant ? |
|---|---|---|---|
| Git et checkout `5a68a99` | Client disponible. `git rev-parse` et `git cat-file` signalent l'absence de dépôt exploitable. | Git 2.56.1 | Oui, checkout |
| Flutter et Dart | Exécutables absents du PATH et des emplacements contrôlés. `pubspec.yaml` absent du workspace. | — | Oui |
| Supabase CLI et psql | Absents du PATH. | — | Oui |
| Docker | Client présent. `docker version` échoue sur l'accès au daemon, malgré la présence du socket. | Client 29.9.2 | Oui |
| Deno | Absent du PATH. Aucun runtime Edge local vérifiable avec la pile indisponible. | — | Oui |
| Playwright et Chromium | Outils présents. La sonde locale de lancement Chromium s'arrête sur `Crashpad setsockopt: Operation not permitted` (SIGTRAP). | Playwright 1.62.0, Chromium 156.0.8078.79 | Oui pour le web |
| Appareil ou émulateur mobile | Ni `adb`, ni `emulator`, ni SDK Android dans les emplacements contrôlés. | — | Oui pour le verdict global ; mobile reporté |
| Comptes, messagerie et URL E2E | Aucun des sept comptes ni URL locale fournis par les mécanismes détectés. `inbucket.enabled=true` dans la configuration, service non démarré. | — | Oui |

### Preuves et résultats

- [Log des prérequis](audit/gate/step0-prerequisites.log), SHA-256 `035bbf5d5ad75f9e80667cc19992ec5a1f4b849d491feeca480b84c6b602ff69`.
- [Sonde Chromium sur une page data locale](audit/gate/step0-chromium-smoke.log), SHA-256 `066e12472e2e240767d4a500fd55e7ed58dd2bbfbed554cd39391d89b1d31efb`.
- [Matrice des 66 assertions](audit/gate/assertions.tsv), SHA-256 `f35ea33871c76d9ffcab7cb2a97c796178fe0dbe986122a118818dc31adf88cd`. Toutes `NOT_RUN`, aucune preuve SQL d'exécution.
- Compilation, analyse, build web, tests Flutter et tests Edge : `NOT_RUN`.
- Parcours authentifiés web et mobile : 0/7 par cible, `NOT_RUN`. Aucune capture ni binaire produit.
- Aucune connexion à l'instance Supabase active ou tentative de démarrage de pile. Aucun commit ni déploiement.

### Reprise attendue

Rendre disponible un checkout exploitable du dépôt privé à `5a68a99` avec son `pubspec.yaml` et ses tests, Flutter/Dart compatibles, Supabase CLI, psql, un daemon Docker joignable et Deno compatible. Fournir un environnement capable de démarrer Chromium headless avec Playwright, ainsi qu'un SDK Android avec ADB et un émulateur ou appareil. Préparer, sur l'instance isolée seulement, son URL loopback, les sept comptes de test et un expéditeur de test pour Inbucket. Reprendre au Step 0 et réenregistrer les preuves avant tout assemblage.

## Câblage des comptes de trésorerie et des références achats

- Projet SQL vérifié : `loliexpress-gate-test`, ref `muzbwqxvamcbfiuehxro`. Migration 022 appliquée via l’API Management HTTPS.
- L’ouverture d’un compte par un administrateur couvre les espèces, Mobile Money et le virement bancaire. Le solde est saisi explicitement et une relance identique ne double pas l’écriture.
- Création d’un entrepôt depuis les paramètres et d’un fournisseur depuis un achat, avec sélection immédiate du fournisseur. Les raccourcis financiers ouvrent les écrans existants.
- `audit/verify_operational_setup.sql` : ouverture, références et contrôles de rôle PASS. `audit/verify_operational_treasury.sql` : rapprochement stock et trésorerie PASS. Les données de ces vérifications sont annulées en fin de transaction.
- Tests Flutter : 18/18 PASS. Vérification des nouveaux écrans sur téléphone en attente.

## Câblage du tableau financier et du partage des documents

- Les actions des créances utilisent la facture sélectionnée. L’encaissement passe par le RPC existant et le tableau se rafraîchit au retour. Le rappel ouvre un brouillon dans la messagerie du téléphone.
- Les options financières ouvrent les rapports, les alertes de sécurité et le journal d’audit. Le partage CSV produit un fichier. Les documents privés sont récupérés avec la session Supabase de l’utilisateur avant partage.
- Les lectures REST `invoices` avec le contact client et `invoice_open_balances` répondent HTTP 200 avec le compte admin sur le projet de gate. Aucun enregistrement de facture disponible pendant cette sonde. Tests Flutter 18/18.
- À valider sur Android : ouverture de la messagerie, encaissement sur facture réelle du gate et partage des fichiers. Les préférences de notification ne sont pas encore enregistrées côté serveur et les canaux de livraison restent à qualifier.

## Préférences du centre de notifications

- Migration 023 appliquée à `loliexpress-gate-test` via l’API Management HTTPS après confirmation du projet.
- Chaque compte choisit les types affichés dans son centre. Les préférences sont relues depuis Supabase et le filtre est appliqué avant la limite de résultats.
- `audit/verify_notification_center_preferences.sql` : persistance et isolation entre deux comptes PASS, transaction annulée. Analyse Flutter sans erreur ni avertissement, quatre remarques de style préexistantes. Tests Flutter 18/18.
- La livraison externe par e-mail, push et SMS est hors de ce réglage. Parcours Android à vérifier.

## Lecture des notifications et rejeu ciblé des parcours

- Migration 024 appliquée sur `loliexpress-gate-test`. Les deux écrans de notifications utilisent `read_at`. Les anciens statuts d’envoi ne déterminent pas l’état de lecture.
- Le déclencheur e-mail lit l’URL de son projet dans Vault. En l’absence de configuration valide, les notifications restent en attente.
- SQL via API Management : lecture sans altération de l’envoi, isolation des préférences, droits sur la configuration opérationnelle, rapprochement achats/ventes/dépenses et trésorerie, transferts et inventaire PASS. Les contrôles utilisent des transactions annulées.
- Flutter : 18 tests PASS, analyse sans erreur ni avertissement avec quatre remarques de style existantes. Tests depuis l’APK et livraison externe en attente.

## Reprise de validation de bout en bout — 25 novembre 2026

- Frontend vérifié à `ad59a4de9462b4074da59b6efc3a0c0ac15571ae`. Compilation Flutter Web release réussie avec l’environnement CI. Chromium a utilisé CanvasKit local et ignoré l’erreur de certificat du proxy dans son seul contexte de test. Sept authentifications par formulaire et routes d’accueil conformes.
- API Management test : 56 assertions PASS, 1 écart attendu sur la base déjà provisionnée, 9 assertions historiques NOT_RUN. Cinq suites SQL opérationnelles complémentaires PASS.
- `create_user` et `ai_assistant` déployées via API Management sur le projet de test avec JWT activé. Correctif CORS confirmé par deux prévols et quatre requêtes réelles depuis Chromium. Aucun e-mail déclenché par les requêtes de validation.
- Appcircle reste le chemin Android après l’interruption de Gradle pendant l’installation du NDK sur l’hôte. Aucun APK récent ni capture Android vérifiés.
- Voir [le rapport courant](FINAL_VERIFICATION.md) pour les liens vers les preuves et les contrôles encore ouverts.

## Reprise production readiness — lot 025

La [machine d’état](audit/production_readiness/STATE.md) porte les exigences de sortie. Le catalogue Gate et les Advisors sont relevés après durcissement de la file de notifications. Production refuse la lecture par l’API Management avec le PAT disponible. La PR #13 reste Draft. Les tests SQL ciblés et Flutter sont passés sur le lot 025.

## Reprise — lot 026

Le [lot trésorerie](audit/production_readiness/RPC_SECURITY_MATRIX.md) ferme l’écriture directe dans les journaux et les comptes, tout en conservant les opérations via les six signatures financières. Le [suivi de reprise](audit/production_readiness/STATE.md) distingue ce lot des contrôles de concurrence, des parcours UI et des autres RPC.

Le premier scénario multisession du lot passe sur Gate. Deux transferts simultanés ont donné une seule sortie de six unités, un refus faute de stock et un journal rapproché. [Preuve](audit/production_readiness/concurrent_transfer.json)

La migration 027 ferme la mise à jour directe des livraisons par le livreur. La lecture affectée et les régressions de remise, commande et stock ont réussi sur Gate. [Preuves](audit/production_readiness/delivery_boundary_results.json)
