# P1.a — cycles de vente et d'achat

**Definition of Done.** Brouillon facture persisté ; PDF généré = PDF partagé (template unique) ; paiements partiels/complets/avoirs/retours ; achat+lignes transactionnel ; séparation réception/facture fournisseur/règlement ; `verify_p1a.sql` avec scénario vente CDF, scénario vente USD, scénario achat réception partielle, chaque scénario réconcilié jusqu'aux créances/dettes.

Les scénarios sont répartis en [ventes et avoirs](verify_p1a_handover.sql), [facturation](verify_p1a_invoice_delivery.sql), [avoir de livraison](verify_p1a_admin_delivery_credit.sql) et [achats](verify_p1a_drafts_and_purchases.sql). Le [registre du gate](../FINAL_VERIFICATION.md) ordonne leur lancement.

| Existant actif | Cible dans le lot |
|---|---|
| Pas de table d'avoir article ni RPC | `record_return_item_credit(uuid) → invoice_item_credits` pour un contrôle contenant des unités revendables. Refus si la quantité revendable est nulle. L'avoir couvre les seules unités revendables et conserve la devise et le prix net de la facture. |
| Paiement à signature existante | `record_payment(uuid,numeric,text,text,text,text) → jsonb` conserve le contrat. L'encaissement tient compte de l'avoir article et de l'avoir de livraison, et peut être relancé avec la même référence. |
| État d'achat, sans facture fournisseur ni règlement dédiés | `register_supplier_bill(uuid,text,date,numeric)`, `record_supplier_bill_payment(uuid,numeric,text,text,uuid)` et `cancel_unreceived_purchase(uuid)` séparent dette, règlement et annulation. La réception utilise `receive_purchase_item(uuid,uuid,integer,uuid)`. |

En attendant une règle d'autorisation distincte pour les avoirs article, leur enregistrement est réservé à l'admin. Un avoir peut réduire la créance ou créer un montant à rembourser. Il n'exécute pas un décaissement. Le remboursement des frais reste une décision admin séparée. Les taux CDF/USD de test sont des fixtures et ne sont pas repris en production.

**Amendement v3 — RA1–RA5.** [015](../migrations/015_avoirs_revendabilite.sql) crée les lignes immuables à l'émission, trace les quantités rejetées dans `return_units_audit`, exige une déclaration admin pour toute quantité revendable et applique le plafond avec contrainte unique et trigger sous verrou. [Cinq assertions dédiées](verify_p1a_ra.sql) couvrent les refus `P4101` et `P4104`, le cas 3/2, le prix net figé et la décision admin distincte pour les frais.
