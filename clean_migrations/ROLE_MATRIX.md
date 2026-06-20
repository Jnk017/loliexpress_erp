# Matrice sectorielle des rôles

| Rôle | Secteur | Lecture | Écriture autorisée |
|---|---|---|---|
| `admin` | `all` | Toutes les données | Administration par RPC et opérations métier |
| `commercial_staff` | `sales` | Clients assignés, commandes associées, factures et paiements correspondants | Clients assignés et commandes via RPC |
| `warehouse_staff` | `warehouse` | Stock, mouvements et livraisons de `user_profiles.warehouse_id` | Stock via `adjust_stock`; transitions logistiques autorisées |
| `delivery_agent` | `delivery` | Routes et livraisons où `delivery_agent_id = auth.uid()` | Confirmation via `confirm_delivery` |
| `comptable` | `accounting` | Factures, paiements, dépenses, achats et écritures comptables | Paiements via `record_payment`; workflows financiers |
| `acheteur` | `purchasing` | Fournisseurs et achats créés/assignés à l’utilisateur | Fournisseurs et achats dans son périmètre |
| `client_b2b` | `client` | Données liées au client dont `customers.user_id = auth.uid()` | Commandes de son compte via RPC et documents autorisés |

## Rôles personnalisés

Un administrateur peut ajouter un rôle par `INSERT` dans `roles`. Le nom est immuable et suit `^[a-z][a-z0-9_]{1,63}$`. Un rôle custom n’obtient aucun accès implicite : ses permissions JSON servent à l’UI, mais une policy ou une RPC explicite doit ouvrir chaque capacité serveur.
