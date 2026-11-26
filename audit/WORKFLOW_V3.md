# LoliExpress ERP — amendement v3

## G1 v3 — Deux niveaux de gate

Le gate de stabilisation exige P0.a et P0.b **PRODUIT — à vérifier**, avec les artefacts G4 et les assertions inscrites dans FINAL_VERIFICATION.md. Dans l'ordre convenu, terminer également l'amendement P1.a avant de démarrer P1.b.2. Le gate final reste l'exécution séparée de FINAL_VERIFICATION.md. Le statut VÉRIFIÉ dépend de cette exécution.

La persistance des réglages était classée par erreur avec l'UX dans P1.b. C'est une réparation identifiée par l'audit. Elle rejoint P0.b et doit être disponible pour les parcours métier. P1.b se limite à l'UX inspirée de Zoho.

## G11 — Avoirs RA1–RA5

- RA1 : quantité revendable nulle, refus serveur identifiable et aucun avoir ligne.
- RA2 : seules les unités explicitement déclarées revendables par l'admin sont créditées. Le delta est tracé dans `return_units_audit` sans mouvement comptable.
- RA3 : prix net remise comprise lu depuis la ligne de facture immuable, par ligne d'origine.
- RA4 : unicité ligne/retour et plafond cumulé sous verrou. Un deuxième crédit sur le même retour est refusé.
- RA5 : frais de livraison hors avoir article. Opération admin séparée avec montant, justification, auteur et horodatage.

## Définitions de fin mises à jour

- **P0.b — Accès, reprise et persistance** : inventaire données ; script restauration ; verify invitations/premier accès/RLS/OTP/protection MDP ; ET persistance profil société, devises, taxes, templates PDF, expéditeur e-mail rechargés après reconnexion ; entrée FINAL_VERIFICATION.md. La décision Free maintient le minimum Auth de huit caractères comme critère appliqué.
- **P1.a — Ventes/achats/stock** : brouillon facture persisté ; PDF généré = PDF partagé ; paiements partiels/complets ; avoirs et retours conformes à RA1–RA5 (5 assertions dédiées) ; achat+lignes transactionnel ; séparation réception/facture/règlement ; verify_p1a.sql avec scénarios vente CDF, vente USD, achat réception partielle, et 5 scénarios RA1–RA5 ; entrée FINAL_VERIFICATION.md.
- **P1.b — UX inspirée de Zoho** : navigation par rôle, raccourcis commercial/comptable/acheteur, démarrage guidé reflétant la config réelle, états vides exploitables. Ne démarre qu'après le gate de stabilisation G1(a). verify_p1b.sql et captures attendues documentées.
