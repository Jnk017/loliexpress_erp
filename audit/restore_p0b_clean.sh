#!/usr/bin/env bash
# P0.b — reconstruire le schéma sans importer les données de démonstration.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
unset PGSERVICE PGSERVICEFILE PGHOSTADDR PGOPTIONS
psql_args=(-X --no-password -v ON_ERROR_STOP=1 --host=127.0.0.1
    --port="${LOLIX_TEST_PGPORT:-54322}" --username=postgres --dbname=postgres)
preflight="$(psql "${psql_args[@]}" -Atc "
    SELECT CASE WHEN to_regclass('auth.users') IS NOT NULL
      AND to_regclass('storage.objects') IS NOT NULL
      AND to_regclass('public.customers') IS NULL
    THEN 'ready' ELSE 'stop' END")"
if [[ "$preflight" != ready ]]; then
    echo 'Le rejeu exige une pile Supabase locale vierge.' >&2
    exit 1
fi
if [[ "$(psql "${psql_args[@]}" -Atc 'SELECT count(*) FROM auth.users')" != 0 ]]; then
    echo 'La pile locale contient déjà des comptes Auth.' >&2
    exit 1
fi
for migration in "$root"/migrations/00[0-5]_*.sql "$root"/migrations/016_*.sql; do
    psql "${psql_args[@]}" -f "$migration"
done
