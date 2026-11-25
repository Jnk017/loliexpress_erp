# Matrice de sécurité des RPC

Le [catalogue live de référence](gate_catalog_summary.json) recense 41 signatures publiques `SECURITY DEFINER` exécutables par `authenticated`. Les signatures surchargées sont comptées séparément. Les lignes ci-dessous couvrent le lot atomique SEC-001-A. Les 35 autres signatures restent à examiner individuellement.

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
