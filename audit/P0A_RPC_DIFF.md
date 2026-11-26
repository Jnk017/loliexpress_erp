# P0.a — Diff des RPC et tarification client

**Definition of Done.** Baseline `000_baseline_active.sql` capturant les 117 versions + 4 RPC actives ; migrations `001_*` à `004_*` corrigeant `create_order_with_items`, `adjust_stock`, `transition_order_status`, `complete_password_setup` ; adaptations Flutter correspondantes ; `verify_p0a.sql` avec une assertion par RPC (signature + comportement) ; entrée FINAL_VERIFICATION.md listant les 4 assertions + rejeu complet baseline+fixes depuis zéro.

| RPC | Actif | Cible et changement de corps |
|---|---|---|
| Commande | `(uuid,jsonb,text)` | [001](../migrations/001_order_customer_prices.sql), `(uuid,jsonb,text,text,numeric,text,numeric)`. Le prix unitaire est résolu par client, produit et devise. Le serveur refuse une remise non admin et un prix soumis qui diffère du prix courant, puis persiste en une transaction. La correction conserve le déclencheur de notification et lui permet de fonctionner avec zéro agent de dépôt. |
| Stock | `(uuid,uuid,integer,text)`, `p_adjustment_quantity` | [002](../migrations/002_adjust_stock.sql), `(uuid,uuid,integer,text,uuid,text)`, `p_quantity_delta`. Verrou stock, validation du registre, écriture du mouvement et audit. Le déclencheur existant calcule la quantité finale. |
| Statut | Absente | [003](../migrations/003_transition_order_status.sql), `(uuid,order_status,text)`. Verrou de commande, contrôle client/rôle et graphe de transitions repris du dépôt. Le déclencheur d'audit existant journalise l'UPDATE. |
| Premier accès | Absente | [004](../migrations/004_complete_password_setup.sql), `()`. Profil actif et mot de passe Auth requis. Le changement direct du drapeau est protégé. Le test complet de l'invitation relève de P0.b. |

Corps et signatures d'origine dans [la capture](p0a_active_dependencies.json). Les auxiliaires actifs remplacés dans `001` et `004` sont reproduits dans la baseline. [Contrôles exécutables](verify_p0a.sql) · [Gate final](../FINAL_VERIFICATION.md)

Flutter ajoute `order_unit_price(p_customer_id, p_product_id, p_currency)` avant d'afficher un prix dans le panier. Les signatures d'appel des quatre RPC principales sont déjà celles visées par les migrations au commit audité. Le panier envoie le prix affiché comme assertion de concurrence. Seul le serveur détermine la valeur enregistrée.

La décision du 23 novembre fixe à 0 % la remise manuelle du commercial. L'admin peut définir un prix fixe par couple client–article et le retirer pour revenir au catalogue. L'exemple 4 000 / 3 850 / 3 565 CDF est réservé au test. L'action d'administration est exposée par RPC, sans écran d'administration livré dans ce lot.
