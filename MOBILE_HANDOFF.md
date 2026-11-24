# LoliExpress ERP — tests sur Android

## Compiler dans Appcircle

1. Dans **Workflows → New**, importe [appcircle.yml](appcircle.yml) et enregistre-le sous un nom distinct, par exemple **LoliExpress Gate Debug**. Le workflow importé doit contenir **Build Flutter Debug APK**.
2. Dans la configuration du build, associe le groupe de variables `SUPABASE_URL` et `SUPABASE_ANON_KEY` du [projet de test](CLOUD_HANDOFF.md). Ouvre **Start Build**, choisis la branche `gate/final-verification`, son dernier commit, puis le workflow **LoliExpress Gate Debug**. Le journal doit afficher `Gate SDK verified: Flutter 3.35.7`. Les étapes **Flutter Install** et **Flutter Build for Android** du workflow par défaut indiquent que le workflow importé n’a pas été sélectionné. Récupère `app-debug.apk` dans **Artifacts** après réussite.
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
