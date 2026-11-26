# P0.b — Inventaire de reprise LoliExpress ERP

**Definition of Done v3.** Inventaire, restauration testable, contrôles invitations/premier accès/RLS/OTP/mot de passe compatibles Free, profil société, devises, taxes, modèle PDF et expéditeur persistants et rechargés après reconnexion. [Contrat v3](audit/WORKFLOW_V3.md) · [Gate final](FINAL_VERIFICATION.md)

**Décision validée le 23 novembre 2026.** `loliexpress_erp` est la seule référence. Son schéma est repris et ses données actuelles sont des données de démonstration à écarter. Le volume ci-dessous est celui constaté en lecture seule.

| Projet | Référence | Disponibilité et volumes |
|---|---|---|
| loliexpress_erp | `lvzdlmojjoqrwxwluvih` | Actif. 5 comptes Auth, 1 client, 8 articles, 8 lignes de stock, 1 commande et 1 facture. Aucun paiement, achat ou fichier dans les tables interrogées. |
| LoliExpress Staging Go-Live | `ygvjxtkwxjactcesafvv` | En pause. Requête de comptage refusée car la base est inaccessible. |
| LoliExpress Management System | `jbehswrimmmlzhvbquyi` | En pause. Requête de comptage refusée car la base est inaccessible. |

Le [script de reprise](audit/restore_p0b_clean.sh) reconstruit le schéma de référence sur une pile Supabase locale vierge. Aucun utilisateur Auth, article, client, stock, mouvement, commande, document ou paramètre métier actuel n'est importé. Le nettoyage ou remplacement de l'instance active est à planifier au gate, avec un plan de retour arrière et l'amorçage d'un premier admin autorisé. Les projets en pause sont hors reprise. Les exemples tarifaires restent des données de test.
