# Bootstrap Supabase propre — LoliExpress ERP

Ce bundle est réservé à un projet Supabase **vierge**. Il remplace l’historique de migrations existant; il ne constitue pas une migration in-place d’une production existante.

## Ordre

1. Groupe A : `001`–`010` — cœur ERP, GED, audit, sécurité et forensic.
2. Groupe B : `011`–`015` — achats, finance et remédiations.
3. Groupe C : `016`–`018` — `pg_cron`, `pg_net`, Security Advisor et livraison.
4. Groupe D : `019` — taux USD/CDF initial 2500, finance et rapports admin.
5. Groupe E : `020`–`022` — insights, RPC transactionnelles et frontière de privilèges.
6. Groupe F différé : `023`–`024` après déploiement des Edge Functions et secrets Vault.

Chaque fichier est une migration distincte. N’assemblez pas tout dans une transaction SQL Editor unique.

## Déploiement recommandé

Le projet étant lié, utilisez `./clean_migrations/apply.sh`. Le script construit un workdir Supabase temporaire afin que seuls ces 24 fichiers soient considérés, puis appelle `supabase db push`. Par défaut le groupe F est différé.

```bash
export SUPABASE_DB_PASSWORD='...'
export SUPABASE_DB_URL='postgresql://...'
./clean_migrations/apply.sh
```

Le script exige une base sans données métier et demande confirmation avant le push. Pour le groupe F :

1. déployer les huit Edge Functions;
2. créer manuellement dans Vault `supabase_url` et `service_role_key`;
3. lancer `./clean_migrations/apply.sh --group-f`.

Ne placez jamais la service-role key dans Flutter, Git ou une commande conservée dans l’historique shell.

## Administrateur initial

Déployez `bootstrap_admin`, configurez `BOOTSTRAP_ADMIN_SECRET`, `SITE_URL` et `INVITE_REDIRECT_URL`, puis invoquez la fonction une fois. `bootstrap_admin.sql` vérifie seulement la préparation DB; il ne crée aucun utilisateur et ne contient aucun mot de passe.

## Utilisateurs et rôles

`user_profiles.role_id` est la source d’autorité. `user_profiles.role` et `sector` sont des caches synchronisés par trigger pour la compatibilité Flutter. L’admin attribue un rôle via `update_user_role(p_target_user,p_new_role)`; l’Edge Function utilise `provision_invited_user_profile`, accordée uniquement à `service_role`.

Ajout d’un rôle custom :

```sql
INSERT INTO public.roles(name,display_name,sector,permissions,is_system,created_by)
VALUES('regional_sales_manager','Responsable commercial régional','sales','{"orders":"regional"}',false,auth.uid());
```

Aucun accès n’est accordé automatiquement à un rôle custom; ajoutez une policy/RPC explicite.

## Taux de change

```sql
SELECT public.update_exchange_rate('USD','CDF',2550);
```

L’ancien taux est clôturé et chaque changement est audité.

## Rapports

Les RPC `get_*_report()` vérifient `has_role('admin')`. Les cinq vues matérialisées sont rafraîchies automatiquement par les jobs installés dans `023`. Rafraîchissement manuel :

```sql
REFRESH MATERIALIZED VIEW public.admin_daily_report;
```

## Vérification

`verify_migration.sql` contrôle RLS, RPC, rôles, taux, absence de comptes démo, base métier vide, rapports, masquage de `cost_price` et triggers d’audit. Le script simule aussi des JWT `authenticated` avec quatre profils transactionnels et vérifie l’isolation client/commercial/admin; toutes les fixtures sont annulées par `ROLLBACK`. Les tests HTTP avec de vrais JWT restent exécutés en CI.

Voir `ROLE_MATRIX.md` et `EXCLUDED_FILES.md`.
