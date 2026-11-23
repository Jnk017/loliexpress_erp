# LoliExpress ERP — remise Android pour le gate

## État de la remise

Cible confirmée : téléphone Android physique, avec parcours manuels. Le mode prioritaire est le build APK local. Attendre un APK et une preuve de connexion provenant du téléphone avant de commencer les parcours. Le journal [GATE_STATE.md](GATE_STATE.md) porte le statut courant.

## Connexion à la pile de test

- Avec un téléphone USB attaché à l'ordinateur qui peut joindre la pile isolée sur le port 54321, exécuter `adb reverse tcp:54321 tcp:54321`. L'APK doit alors utiliser `http://127.0.0.1:54321`. Si la pile est sur l'environnement Cloud, un transfert privé vers cet ordinateur doit d'abord être établi et contrôlé.
- Sur un LAN de test commun, valider le point d'accès depuis le téléphone. L'APK doit être compilé avec cette URL. Une réponse depuis l'exécuteur Cloud ne prouve pas l'accès depuis le téléphone.
- Pour toute URL distante, vérifier la provenance, l'accès depuis Android et le périmètre de la pile isolée avant le build. L'APK ne reçoit que la clé publique/anon de test.

## Installer et vérifier

### Secours Codemagic

La compilation de diagnostic locale a échoué dans Gradle. Le workflow [build-only](codemagic.yaml) est prêt pour une reprise par l'opérateur quand une URL de test aura été vérifiée depuis le téléphone.

1. Connecter `Jnk017/loliexpress_erp` dans Codemagic et connecter la branche `gate/final-verification` et activer le webhook Codemagic pour les pushes.
2. Ajouter le groupe Codemagic `loliexpress-gate-local` avec `MOBILE_SUPABASE_URL` et `SUPABASE_ANON_KEY`. Utiliser uniquement l'URL et la clé publique de la pile isolée.
3. Après configuration du groupe de variables, un push sur la branche du gate déclenche `build-android-apk` si le webhook est actif. Télécharger `app-debug.apk` depuis les artefacts du build. La configuration livre l'APK via les artefacts. Aucun destinataire de notification n'a été fourni.
4. Exécuter les parcours ci-dessous sur le téléphone et déposer les captures dans le dossier convenu.

### Appareil physique

Installer l'APK fourni par `adb install -r app-debug.apk` ou le transférer vers Android et ouvrir le paquet. Utiliser les comptes locaux de test remis par une voie privée. Les sept scénarios attendus sont les suivants.

| Rôle | Contrôles à documenter |
|---|---|
| `commercial` | Client créé, commande et statut contrôlés. |
| `comptable` | Brouillon et facture, PDF, paiement partiel, créance et avoir de retour. |
| `acheteur` | Achat, réception partielle, dette puis règlement. |
| `admin` | Décision séparée sur les frais de livraison. |
| `livreur` | Tournée affectée, livraison confirmée à la remise. |
| `client_a` | Commandes propres et isolation vis-à-vis de B. |
| `client_b` | Commandes propres et isolation vis-à-vis de A. |

Déposer au moins deux preuves PNG par rôle dans `E2E_MOBILE_ARTIFACTS_DIR` ou `~/e2e_mobile_artifacts/`, avec le nom `e2e_<role>_<etape>.png`. Écarter les écrans affichant des mots de passe et des clés. Le gate associe les captures aux parcours et calcule leurs SHA-256 avant d'enregistrer un résultat.
