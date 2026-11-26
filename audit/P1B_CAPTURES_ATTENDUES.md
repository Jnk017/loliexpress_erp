# P1.b.2 — Contrôles visuels au gate final

**Definition of Done.** Navigation par rôle, raccourcis commercial/comptable/acheteur, démarrage guidé reflétant la config réelle, états vides exploitables. Ne démarre qu'après le gate de stabilisation G1(a). `verify_p1b.sql` et captures attendues documentées.

Les captures sont à prendre sur une installation de vérification, avec un viewport mobile puis un viewport web. Comparer aux critères suivants.

| Capture | État attendu |
|---|---|
| Commercial, avant activité | Nouvelle commande, Clients, Catalogue et Scanner. Mise en route à 0/2 sans client ni commande et menu sans règlement fournisseur. |
| Commercial, après création | Client attribué et première commande cochés à son retour sur le tableau de bord. |
| Comptable | Factures et encaissements, Dépenses, Rapports et Achats. Le compteur dépend du profil société et de la présence de factures et paiements. |
| Acheteur, liste vide | Nouvel achat ouvre directement le formulaire. Catalogue et Stock accessibles. Le bouton de l'état vide ouvre le même formulaire. Aucun raccourci d'encaissement. |
| Acheteur, après création | La mise en route actualise le premier achat et la fiche apparaît dans la liste. |
| RPC de progression indisponible | Les raccourcis restent utilisables. La progression indique l'erreur et fournit une relance. |

Vérifier aussi que les expertises métier existantes gardent leurs routes et que le filtre d'accès sert à la présentation. L'autorisation des opérations reste contrôlée par les RPC et RLS.
