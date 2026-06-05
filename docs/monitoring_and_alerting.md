# Monitoring et alerting de production

## Objectifs

La supervision doit détecter rapidement une perte d’intégrité financière, une tentative d’accès répétée, une panne d’invitation ou une indisponibilité des opérations transactionnelles. Les données sensibles ne doivent jamais être copiées dans les logs.

## Sources de télémétrie

| Source | Événements suivis | Rétention minimale conseillée |
|---|---|---:|
| Supabase Edge Function logs | statuts HTTP, latence, `create_user_*`, `bootstrap_admin_attempt` | 90 jours |
| PostgreSQL logs | erreurs RPC, deadlocks, timeouts, violations RLS/permissions | 90 jours |
| Supabase Auth logs | connexions échouées, invitations, resets, comptes désactivés | 180 jours |
| `audit_logs` | commandes, stock, livraisons, paiements, utilisateurs | selon politique comptable, au moins 1 an |
| `security_events` | tentatives bootstrap et événements serveur sans acteur applicatif | 1 an |
| GitHub Actions | migrations, tests, builds et artefacts | 90 jours minimum |

## Format structuré Edge Functions

Les fonctions utilisent des objets JSON sur une ligne. Les champs attendus sont :

- `event` : identifiant stable (`user_created_by_admin`, `create_user_rejected`, `create_user_rollback`, `bootstrap_admin_attempt`) ;
- `success` pour les tentatives bootstrap ;
- `reason` avec une valeur non sensible et bornée ;
- `actor_id` et `user_id` lorsque disponibles ;
- l’identifiant de requête fourni par la plateforme doit être conservé par le log drain.

Ne jamais écrire : header `Authorization`, JWT, service-role key, mot de passe, OTP, lien magic/invitation, contenu de document ou coordonnées bancaires.

## Alertes critiques

### P1 — intervention immédiate

- Échec répété de `supabase db reset` ou des tests RLS sur la branche de release.
- Taux d’erreur des RPC `create_order_with_items`, `adjust_stock`, `confirm_delivery` ou `record_payment` supérieur à 10 % pendant 5 minutes, hors erreurs métier 4xx attendues.
- Détection d’un stock négatif ou divergence entre `inventory_stock.quantity` et le total signé des mouvements.
- Paiement enregistré au-delà du total de facture ou incohérence facture/commande.
- Lecture B2B inter-tenant détectée par test synthétique.
- `bootstrap_admin_attempt` avec `success=true` après le go-live.

### P2 — réponse sous une heure

- Trois tentatives bootstrap échouées en 15 minutes.
- Cinq refus RLS/permission pour le même utilisateur en 10 minutes, après exclusion des erreurs UI connues.
- Trois échecs d’invitation en 15 minutes.
- Une Edge Function dépasse 5 % de réponses 5xx sur 10 minutes.
- Absence de taux USD/CDF actif alors que des commandes USD sont tentées.
- Job cron de notification sans exécution réussie dans deux fenêtres planifiées.

### P3 — traitement ouvré

- Invitation non acceptée après 72 heures.
- Compte inactif continuant à générer des tentatives de connexion.
- Remises refusées anormalement fréquentes pour un commercial.
- Augmentation inhabituelle des corrections manuelles de stock.

## Requêtes de contrôle

### Divergence stock

```sql
SELECT inventory.product_id, inventory.warehouse_id,
       inventory.quantity AS stored_quantity,
       COALESCE(SUM(CASE movement.movement_type
         WHEN 'in' THEN movement.quantity
         WHEN 'return' THEN movement.quantity
         WHEN 'out' THEN -movement.quantity
         WHEN 'adjustment' THEN movement.quantity
       END), 0) AS ledger_quantity
FROM inventory_stock inventory
LEFT JOIN stock_movements movement
  ON movement.product_id = inventory.product_id
 AND movement.warehouse_id = inventory.warehouse_id
GROUP BY inventory.product_id, inventory.warehouse_id, inventory.quantity
HAVING inventory.quantity <> COALESCE(SUM(CASE movement.movement_type
  WHEN 'in' THEN movement.quantity
  WHEN 'return' THEN movement.quantity
  WHEN 'out' THEN -movement.quantity
  WHEN 'adjustment' THEN movement.quantity
END), 0);
```

### Bootstrap encore actif

```sql
SELECT config_value
FROM system_configuration
WHERE config_key = 'bootstrap_admin_enabled';
```

### Échecs d’invitation et rollbacks

Configurer le log drain avec un filtre sur :

```text
event IN (create_user_invitation_failed, create_user_rollback)
```

### Tentatives bootstrap

```sql
SELECT success, metadata->>'reason' AS reason, count(*)
FROM security_events
WHERE event_type = 'bootstrap_admin_attempt'
  AND created_at >= now() - interval '15 minutes'
GROUP BY success, metadata->>'reason';
```

## Tests synthétiques

- Toutes les 15 minutes : authentification d’un compte technique sans privilège puis lecture d’une ressource publique autorisée.
- Quotidiennement en staging : création d’une commande de test, vérification des lignes/audit, puis suppression par réinitialisation de l’environnement.
- Quotidiennement en staging : contrôle B2B croisé avec deux tenants.
- Après chaque déploiement Edge : invitation vers une boîte de test et vérification du lien sans exposer son contenu aux logs.

## Runbook d’alerte

1. Identifier le commit, le projet Supabase et la fenêtre UTC.
2. Préserver les logs avant toute rotation.
3. Suspendre l’opération concernée plutôt que de désactiver RLS.
4. Ne jamais basculer Flutter vers la service-role key.
5. Réconcilier les écritures partielles ; les RPC PostgreSQL doivent normalement garantir leur absence.
6. Corriger par migration avant uniquement, rejouer `supabase db reset` et l’intégralité des tests.
7. Documenter la cause, l’impact, le correctif et les actions préventives.
