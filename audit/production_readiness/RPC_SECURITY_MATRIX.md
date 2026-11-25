# Matrice de sécurité des RPC

Le [catalogue live de référence](gate_catalog_summary.json) recense 41 signatures publiques `SECURITY DEFINER` exécutables par `authenticated`. Les signatures surchargées sont comptées séparément. Sur les 41 signatures de référence, 26 sont validées, 6 ont été examinées avec des contrôles individuels encore ouverts et 9 ont passé les contrôles de grants et de refus ciblés. Les deux nouvelles signatures de réception et de choix produit sont validées séparément.

| Signature dans public | Appelant | Autorisation et périmètre | Validation et écritures | Verdict du lot |
|---|---|---|---|---|
| `receive_invoice_payment(uuid,numeric,text,text,text,uuid,uuid,text)` | Flutter, écran de facturation | Admin et comptable actifs, mot de passe configuré, via `can_read_finance`. Portée Finance sur les factures de l’ERP. | Verrou facture, devise, montant net et méthode. Écrit règlement, facture, commande et journal atomiquement via `record_payment` et `post_operational_treasury`. | Vérifié |
| `receive_invoice_payment(uuid,numeric,text,text,text,uuid,uuid)` | Contrat client antérieur | Délègue à la signature avec méthode. | Délègue validation et écritures. Déduit espèces ou virement. | Vérifié |
| `pay_supplier_bill_from_account(uuid,numeric,text,text,uuid,text,uuid,text)` | Flutter, service achats | Admin et comptable actifs. Portée Finance sur les dettes fournisseurs de l’ERP. | Vérifie la méthode avant `record_supplier_bill_payment`, qui contrôle la devise, le montant et l’idempotence. Écrit dette, règlement et journal via `post_operational_treasury`. | Vérifié |
| `pay_supplier_bill_from_account(uuid,numeric,text,text,uuid,text,uuid)` | Contrat client antérieur | Délègue à la signature avec méthode. | Délègue validation et écritures. Déduit espèces ou virement. | Vérifié |
| `pay_expense_from_account(uuid,text,uuid)` | Flutter, service dépenses | Admin et comptable actifs. Portée Finance sur les dépenses de l’ERP. | Verrou dépense, approbation préalable, compte et devise contrôlés. Écrit mouvement, dépense et historique. | Vérifié |
| `open_treasury_account(uuid,text,text,text,text,numeric)` | Flutter, formulaire de trésorerie | Admin actif. Portée administrative sur les comptes de l’ERP. | Contrôle méthode, devises, précision et concurrence du même identifiant. Écrit compte, solde d’ouverture et audit. | Vérifié |

Pour ces six signatures, le propriétaire effectif dans le catalogue Gate est `postgres`, le mode est `SECURITY DEFINER`, le `search_path` est vide et `authenticated` seul des deux rôles clients a `EXECUTE`. Aucun appel Edge repéré dans le dépôt. Les helpers de paiement et de comptabilisation sont utilisés depuis ces fonctions. L’identité métier provient d’`auth.uid()` et du profil actif, via `current_user_role`. Les droits privilégiés permettent d’appliquer les écritures multi-tables dans la même transaction. Le modèle actuel autorise Finance à gérer l’ensemble des factures, dettes et dépenses de l’ERP.

**Correction.** La migration 026 retire les droits d’écriture directe du client sur les deux tables de comptes et les deux journaux associés. Le droit de lecture soumis à RLS est conservé. Le contrôle vérifie les six grants et les refus par rôle, y compris les profils inactifs, sans profil, ou devant configurer leur mot de passe. Les deux suites de régression vérifient l’ouverture, les paiements, les trois moyens, les devises CDF et USD, les doublons et le rapprochement.

[Contrôle des droits](verify_treasury_rpc_boundary.sql) · [Ouverture des comptes](../verify_operational_setup.sql) · [Paiements et rapprochement](../verify_operational_treasury.sql) · [Résultats](release_gate_results.json)

Le verdict du lot couvre les permissions et la régression séquentielle sur Gate. Les tests multisession et les parcours UI relèvent de leurs exigences P0 respectives.

## Livraison et stock, lot 027

| Signature | Scope et comportement vérifiés | Preuve |
|---|---|---|
| `assign_delivery_warehouse(uuid,uuid)` | Admin ou magasinier actif. Entrepôt actif, livraison encore en attente. Écrit l’affectation sans mouvement de stock. | Handover CDF/USD. |
| `confirm_delivery(uuid,text,text)` | Admin ou livreur de la tournée. Verrous sur livraison, commande et quantités. Contrôle du journal, de la quantité et du statut. Écrit remise, mouvements, statuts et audit. | Remise et reprise séquentielle, une seule sortie, rollback après échec. |
| `transition_order_status(uuid,order_status,text)` | Admin, magasinier, commercial affecté, ou client B2B propriétaire pour son annulation avant confirmation. L’ordre des statuts est vérifié par trigger. | Vérification P0.a et garde de remise. |
| `adjust_stock(uuid,uuid,integer,text,uuid,text)` | Admin ou magasinier. Contrôle du produit, de l’entrepôt, du delta et de la concordance avec le journal. | Vérifications P0.a, transfert et comptage. |
| `transfer_stock(uuid,uuid,uuid,integer,text)` | Admin ou magasinier. Valide les deux entrepôts et verrouille dans un ordre stable. Deux écritures opposées via `adjust_stock`. | Test positif, refus B2B, conservation sous concurrence. |
| `record_physical_stock_count(uuid,uuid,integer,integer,text)` | Admin ou magasinier. Vérifie la quantité attendue sous verrou et audite le comptage, même sans mouvement. | Tests positif, quantité périmée et refus B2B. |

Ces six fonctions sont privilégiées avec un `search_path` vide. L’audit direct des rôles et privilèges n’est pas terminé pour chaque signature. La migration 027 retire la politique de mise à jour directe du livreur. Sa lecture sur les tournées affectées et la confirmation via RPC sont conservées. [Résultats Gate](delivery_boundary_results.json)

## Réception du magasinier, lot 028

`public.list_warehouse_purchase_receipts()` est une nouvelle RPC `SECURITY DEFINER` en lecture, à `search_path` vide. Flutter appelle cette fonction depuis le raccourci de réception. La RPC vérifie le profil actif et le rôle magasinier via `current_user_role`, refuse les comptes sans profil et ne renvoie que le numéro d’achat, la ligne, le nom du produit et le restant à réceptionner. Elle n’écrit aucune donnée. La réception utilise la RPC existante `receive_purchase_item`, verrouillée et idempotente sur l’identifiant de requête. Le test Gate confirme une réception répétée sans double mouvement ni lecture directe des données d’achat. [Preuves](warehouse_receipt_results.json)

## Commandes, prix et émission

| Fonction | Contrôle et impact | Vérification Gate |
|---|---|---|
| `set_customer_product_price(uuid,uuid,numeric,text)` | Administrateur actif. La devise est soumise à la contrainte de la table et le tarif est audité. | Écriture administrateur, refus du commercial. |
| `order_unit_price(uuid,uuid,text)` | Administrateur, commercial affecté ou propriétaire B2B. Produit actif, devise et taux contrôlés. Lecture seule. | Deux prix distincts, refus de lecture croisée B2B. |
| `create_order_with_items(uuid,jsonb,text,text,numeric,text,numeric)` | Administrateur, commercial affecté ou propriétaire B2B. Le serveur recalcule les prix et réserve les remises à l’administration. Écrit la commande et ses lignes. | Commande B2B au tarif propre, refus d’un client non affecté au commercial. |
| `issue_order_invoice(uuid,timestamptz,boolean,numeric)` | Administrateur ou comptable. Commande confirmée, paramètres de livraison vérifiés, verrou et unicité des conditions. Écrit la facture et fige les lignes. | Refus B2B et émission comptable de 12 CDF conformément au tarif affecté. |

Propriétaire `postgres`, `search_path` vide et exécution client réservée à `authenticated` selon le catalogue de référence. Les quatre signatures sont appelées depuis les services Flutter. [Preuve de périmètre](order_invoice_scope_results.json)

La nouvelle RPC `public.list_procurement_product_choices()` est réservée à l’administration et à l’acheteur actifs. Elle lit le catalogue actif et retourne deux champs, l’identifiant et le nom. Elle ne modifie aucune table. Le test vérifie le rôle acheteur, la dissimulation des coûts et des produits inactifs, et le refus d’un magasinier. [Tests](procurement_choices_results.json)

## Prédicats RLS et configuration

- `is_admin`, `is_admin_from_auth`, `is_system_admin`, `is_acheteur`, `is_comptable`, `is_sales_rep`, `is_warehouse_staff`, `is_delivery_agent`, `is_b2b_customer` sont les prédicats des politiques PostgreSQL. Ils ne révèlent que le résultat du test de rôle pour l’appelant. Les profils inactifs, sans mot de passe configuré ou absents sont refusés via `current_user_role`.
- `can_read_finance` et `can_read_procurement` composent les prédicats précédents. Le premier couvre admin et comptable. Le second ajoute acheteur. Aucune écriture et aucun paramètre pour ces onze fonctions. [110 évaluations](role_predicates_results.json)
- `get_company_settings()` lit la configuration interne pour les rôles internes actifs. `update_company_settings(jsonb)` valide les clés et valeurs modifiables et audite l’écriture par un administrateur. `get_workspace_setup_progress()` renvoie uniquement la progression liée à l’appelant et à son rôle. `get_admin_total_report(timestamptz,timestamptz)` agrège les données à la demande d’un administrateur. Les écrans Flutter et l’assistant appellent ces fonctions selon leur rôle. [Accès et régressions](admin_reporting_results.json)

Les propriétaires et configurations de chemins sont inventoriés dans le catalogue de référence. Les droits exécutables sont retestés en base. [Référence](gate_catalog_summary.json)

## Refus et grants supplémentaires

`cancel_unreceived_purchase`, `complete_password_setup`, `create_purchase_with_items`, `get_customer_return_lines`, `inspect_customer_return`, `receive_purchase_item`, `record_delivery_fee_credit`, `record_return_item_credit`, `register_supplier_bill` et `save_invoice_draft` passent le contrôle d’exécution anonyme/authentifiée et les refus B2B ou sans identité, selon le contrat. La clôture individuelle de ce groupe exige encore de lier les tests positifs et tous les cas d’isolement à chaque signature. [Preuve](remaining_rpc_grants_results.json)

## Vérifications complémentaires des frontières stock et achats

Les cinq refus du livreur couvrent l’affectation d’entrepôt, la transition de commande, l’ajustement, le transfert et le comptage. La lecture affectée, l’entrée dans le contrôle de confirmation pour le livreur affecté et le refus du profil absent restent testés. Les suites positives de stock et de remise ont été rejouées. [Résultats](rpc_boundary_followup.json)

`cancel_unreceived_purchase(uuid)` est une fonction transactionnelle du schéma `public`, propriétaire `postgres`, `SECURITY DEFINER` et `search_path` vide. Le service achats Flutter l’appelle avec une session authentifiée. Elle exige un acheteur ou administrateur actif. Sous verrou de l’achat, elle refuse les achats avec réception ou facture, écrit le statut annulé et accepte la répétition d’une annulation valide. Le contrôle précédent couvre le refus B2B et les grants. Le nouveau test couvre l’acheteur, l’annulation, sa répétition et les deux interdictions. [Test](verify_purchase_cancellation.sql)

| Fonction | Contrôle serveur et preuve positive associée |
|---|---|
| `complete_password_setup` | Écrit uniquement le profil actif de l’appelant avec un mot de passe Auth. Les assertions `password_setup` et `password_flag_cleared` repassent dans le suivi P0.a. |
| `create_purchase_with_items` | Admin ou acheteur. Écrit en une transaction l’achat et les lignes. Les cas d’achat valide et d’annulation de la transaction à la ligne invalide repassent. |
| `get_customer_return_lines` | Admin ou magasinier. Retourne les lignes ayant fait l’objet d’une remise et dont le reliquat est non nul. Le test sur un retour épuisé repasse. La liste positive par magasinier reste à documenter séparément. |
| `inspect_customer_return` | Admin ou magasinier. Borne la quantité à celle remise, enregistre le retour et ne réintègre que les unités revendables. Retours mixtes, plafond et répétition repassent. |
| `receive_purchase_item` | Admin, acheteur ou magasinier. Verrouille achat et ligne, exige un entrepôt actif, trace une réception idempotente et met à jour le stock. La réception partielle et le test Web magasinier couvrent les cas positifs. |
| `record_delivery_fee_credit` | Admin. Plafonne l’avoir aux frais facturés, sous verrou. Refus du comptable, répétition et plafond repassent. |
| `record_return_item_credit` | Admin. Contrôle la revendabilité, le montant net et les avoirs déjà émis. Les cinq cas RA repassent. Le double avoir en sessions simultanées reste ouvert. |
| `register_supplier_bill` | Admin, acheteur ou comptable. Vérifie le numéro et le plafond d’achat sous verrou. L’enregistrement distinct de la réception repasse. |
| `save_invoice_draft` | Admin, comptable ou commercial affecté. Restreint le client et l’écriture au brouillon autorisé. Création et mise à jour sans créance repassent. |

Les contrôles de rôle, les cas P0.a et les retours/remises se trouvent dans le [suivi des frontières](rpc_boundary_followup.json). Les [régressions achats et avoirs](purchase_return_rpc_regression.json) identifient les résultats détaillés.
