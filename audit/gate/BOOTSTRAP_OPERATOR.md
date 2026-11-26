# Reprise du bootstrap sur un hôte de vérification

GitHub Actions est exclu. Le clone à vérifier est `/workspace/work/loli-verify`, à `5a68a999ca15bde01804185fa884e12d7ca09866`, avec les artefacts de gate assemblés dans l'arbre de travail.

## Vérifier l'hôte

Sur l'hôte Linux de vérification désigné par l'opérateur, avec Docker déjà installé et démarré, exécuter la sonde suivante. Elle contrôle la disponibilité du daemon et les outils Android sans changer les droits.

```bash
bash audit/gate/bootstrap-host-check.sh
```

Pour un Android de test, fournir un émulateur opérationnel ou un appareil visible comme `device` dans `adb devices`. Sur un hôte disposant déjà de Java et des outils de ligne de commande Android, l'opérateur peut accepter les licences puis installer le runtime de vérification.

```bash
sdkmanager --licenses
sdkmanager 'platform-tools' 'emulator' 'platforms;android-35' 'system-images;android-35;google_apis;x86_64'
avdmanager create avd --name loli-qa --package 'system-images;android-35;google_apis;x86_64'
emulator -avd loli-qa
```

Vérifier auparavant l'espace requis par les téléchargements et la disponibilité de l'accélération. Le report mobile explicite reste possible sur décision utilisateur et laisse le gate global incomplet.

## Réaudit dans le workspace

```bash
bash audit/gate/bootstrap-re-audit.sh /workspace/work/loli-verify
```

Pour la pile de gate, conserver le seed historique dans le dépôt comme source documentaire. Le démarrage vierge exige une configuration locale avec `[db.seed].enabled = false` et une séquence de migrations mise de côté jusqu'au contrôle initial de vacuité. Utiliser le port et l'URL loopback de la cible isolée. Les sept comptes E2E et l'expéditeur de test restent à fournir par une voie privée, puis à provisionner uniquement sur cette cible. Ne jamais copier une clé ou un mot de passe dans un rapport.

Les deux sondes limitées ont expiré pendant les téléchargements. Sur la machine disposant du daemon local et d'un débit suffisant, conserver les images téléchargées et retenter le démarrage de la pile **de bootstrap uniquement** avec un délai couvrant le téléchargement de Postgres.

```bash
timeout 900 /workspace/work/tools/bin/supabase --workdir /workspace/work/loli-bootstrap-probe start -x studio,postgres-meta,realtime,storage-api,imgproxy,edge-runtime,logflare,vector,supavisor
```

Ces exclusions servent à la sonde de bootstrap. Le gate nécessite ensuite une pile isolée complète. Contrôler l'API Auth sur `127.0.0.1:54321` et la boîte de réception sur `127.0.0.1:54324` avant de fermer la sonde temporaire.

Après le rejeu de la pile locale, préparer un JSON privé avec `sender_email` et un objet `accounts`. Les clés de cet objet sont `commercial`, `comptable`, `acheteur`, `admin`, `livreur`, `b2b_a` et `b2b_b`. Chaque entrée exige `email` et `password`. Charger `LOLI_E2E_SUPABASE_URL` et `LOLI_E2E_SERVICE_KEY` dans l'environnement par une voie privée et utiliser la clé issue de la pile locale. La commande limite la cible à `http://127.0.0.1:54321`.

```bash
python audit/gate/seed-local-e2e.py --repo /workspace/work/loli-verify --accounts /chemin/prive/qa-accounts.json
```

Le script vérifie les profils puis écrit `.env.test` en mode 0600. Le fichier est ignoré dans le clone. Une adresse donnée pour Inbucket reste une adresse d'essai, sans envoi externe. La liaison des deux clients à leurs données d'essai fait partie des parcours de gate.

## Stockage de l’environnement géré

Le système de fichiers observable du workspace est limité à 7,9 Gio. Le daemon utilise `vfs` et son répertoire privé `/home/dockerd/.local/share/docker` est inaccessible depuis le compte agent. L’opérateur de l’hôte doit agrandir le volume du daemon ou fournir un environnement dont le data-root se trouve sur un volume offrant au moins 15 Gio libres. Conserver les données existantes du daemon pendant toute opération de déplacement.

Sur l’hôte, avec le contexte Docker du gate, contrôler le résultat avec :

```bash
bash audit/gate/check-docker-capacity.sh
# Si le data-root exige les droits du propriétaire rootless et sudo est disponible :
DOCKER_DATA_OWNER=dockerd bash audit/gate/check-docker-capacity.sh
```

Attendre `DOCKER_CAPACITY_OK` avant de reprendre le démarrage de la pile PG17 isolée. Configurer ensuite la route Android depuis le téléphone et la [remise Codemagic](../../CODEMAGIC_HANDOFF.md). Le gate SQL et web peut reprendre dès validation de la pile.
