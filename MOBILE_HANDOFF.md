# LoliExpress ERP — tests sur Android

## Build demandé

Le workflow `build-android-apk` est limité à `gate/final-verification`. Le push de déclenchement est demandé par Codex. Dans [Codemagic](https://codemagic.io/), vérifier le groupe `loliexpress-gate-local` avec `MOBILE_SUPABASE_URL` sur le projet de test et `SUPABASE_ANON_KEY` avec sa clé publique. Si aucun build n’apparaît, vérifier le webhook dans la [checklist](CODEMAGIC_HANDOFF.md). L’état du build et la disponibilité de l’APK doivent être confirmés dans Codemagic.

1. Préparer le projet cloud et le build depuis les guides [Supabase](CLOUD_HANDOFF.md) et [Codemagic](CODEMAGIC_HANDOFF.md). Codex déclenche le build après confirmation des variables.
2. Dans Codemagic, ouvrir le build de `gate/final-verification`, relever son SHA et télécharger `app-debug.apk` dans **Artifacts** ou depuis la notification si elle est configurée.
3. Ouvrir l’APK sur le téléphone. Si Android le demande, autoriser temporairement l’installation depuis le navigateur, puis désactiver cette autorisation après installation.
4. Exécuter les parcours suivants avec les comptes de test transmis par Codex.

| Rôle | Contrôles à documenter |
|---|---|
| `commercial` | Client créé, commande et statut contrôlés. |
| `comptable` | Brouillon et facture, PDF, paiement partiel, créance et avoir de retour. |
| `acheteur` | Achat, réception partielle, dette puis règlement. |
| `admin` | Décision séparée sur les frais de livraison. |
| `livreur` | Tournée affectée, livraison confirmée à la remise. |
| `client_a` | Commandes propres et isolation vis-à-vis de B. |
| `client_b` | Commandes propres et isolation vis-à-vis de A. |

5. Capturer les étapes clés (connexion réussie, action et confirmation) sans afficher les mots de passe ni les clés. Nommer les images `e2e_<role>_<etape>.png`.
6. Depuis [GitHub mobile](https://github.com/Jnk017/loliexpress_erp/upload/gate/final-verification/gate_state/e2e_mobile), choisir les fichiers et les publier sur la branche du gate. Si le formulaire ne fonctionne pas, joindre les images dans un commentaire de la [PR #13](https://github.com/Jnk017/loliexpress_erp/pull/13).
7. Signaler à Codex que les captures sont disponibles et indiquer le SHA du build. Codex vérifie les preuves et calcule leurs empreintes.
