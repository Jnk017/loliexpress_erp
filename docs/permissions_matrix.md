# Matrice de permissions ERP

Cette matrice décrit les autorisations **serveur**. Les contrôles Flutter servent uniquement à l’ergonomie : PostgreSQL/RLS et les RPC restent l’autorité.

| Module / opération | admin | sales_rep | warehouse_staff | comptable | acheteur | delivery_agent | b2b_customer |
|---|---:|---:|---:|---:|---:|---:|---:|
| Profils utilisateurs — lecture globale / gestion | G | — | — | — | — | — | propre profil |
| Clients — lecture | G | affectés | L | L | L | affectés aux tournées | propre société |
| Clients — création/modification | G | G | — | — | — | — | — |
| Produits — lecture catalogue sans coût | L | L | L | L | L | L | actifs |
| Produits/prix — gestion | G | — | — | — | — | — | — |
| Commandes — lecture | G | affectées | G | G | — | affectées aux tournées | propres commandes |
| Commandes — création RPC | G | G | — | — | — | — | propre société |
| Remise commande | 0–100 % | plafond configuré | — | — | — | — | interdite |
| Stock/mouvements — lecture | G | — | G | L | — | — | — |
| Stock — ajustement RPC | G | — | G | — | — | — | — |
| Achats — lecture | G | — | L | L | G | — | — |
| Achats — gestion | G | — | — | — | G | — | — |
| Dépenses — lecture/validation | G | propres | propres | G | propres | propres | — |
| Documents — lecture | G | entités affectées | logistique | finance | achats | livraisons affectées | propres entités via portail |
| Documents — ajout | G | G | G | G | G | G | propre compte |
| Livraisons — lecture | G | L | L | — | — | assignées | propres commandes |
| Livraison — confirmation RPC | G | — | — | — | — | assignées | — |
| Paiements — lecture | G | — | — | G | — | — | propres factures |
| Paiements — enregistrement RPC | G | — | — | G | — | — | — |
| Taux de change — gestion | G | — | — | — | — | — | — |
| Audit / événements sécurité | G | — | — | — | — | — | — |

**Légende :** G = gestion, L = lecture, — = aucun accès direct.

## Principes appliqués

- Les créations de commande, ajustements de stock, confirmations de livraison et paiements passent exclusivement par des RPC `SECURITY DEFINER` validant le rôle, l’état courant et les données.
- Le client ne décide jamais des totaux ni du prix effectif. `create_order_with_items` relit les produits et calcule chaque ligne, le sous-total, la remise et le total.
- Un client B2B est relié à `customers.user_id` et ne voit que les données de sa société.
- Les écritures critiques produisent une entrée `audit_logs`; les tentatives de bootstrap produisent un `security_events` même sans utilisateur authentifié.
- Les noms canoniques des rôles en base sont `admin`, `sales_rep`, `warehouse_staff`, `comptable`, `acheteur`, `delivery_agent`, `b2b_customer`.

## Données confidentielles

- `products.cost_price` n’est pas accordé au rôle PostgreSQL `authenticated`; les fonctions serveur de reporting conservent leur accès via `SECURITY DEFINER`.
- Les lignes d’achat et fournisseurs ne sont jamais lisibles par `b2b_customer`, `sales_rep` ou `delivery_agent`.
- Les helpers `can_read_customer`, `can_read_order`, `can_read_delivery` et `can_access_document_entity` centralisent l’isolation sans sous-requêtes RLS récursives.
