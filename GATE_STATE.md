# Gate final LoliExpress ERP

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
