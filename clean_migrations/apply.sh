#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="$ROOT/clean_migrations"
GROUP_F=false
YES=false
for arg in "$@"; do case "$arg" in --group-f) GROUP_F=true;; --yes) YES=true;; *) echo "Unknown option: $arg" >&2; exit 2;; esac; done
for cmd in supabase psql mktemp; do command -v "$cmd" >/dev/null || { echo "Missing prerequisite: $cmd" >&2; exit 1; }; done
[[ -n "${SUPABASE_DB_URL:-}" ]] || { echo "SUPABASE_DB_URL is required for preflight and verify_migration.sql" >&2; exit 1; }
[[ -f "$ROOT/supabase/.temp/project-ref" ]] || { echo "Project is not linked: run supabase link first" >&2; exit 1; }
PROJECT_REF="$(tr -d '[:space:]' < "$ROOT/supabase/.temp/project-ref")"
[[ -n "$PROJECT_REF" ]] || { echo "Empty linked project ref" >&2; exit 1; }
CUSTOMERS_TABLE="$(psql "$SUPABASE_DB_URL" -Atqc "select to_regclass('public.customers') is not null")"
if [[ "$CUSTOMERS_TABLE" == "t" ]]; then
  COUNT="$(psql "$SUPABASE_DB_URL" -Atqc "select count(*) from public.customers")"
  [[ "$COUNT" == "0" ]] || { echo "Refusing bootstrap: customers table is not empty ($COUNT rows)" >&2; exit 1; }
fi
if ! $YES; then read -r -p "Apply clean bootstrap to linked project $PROJECT_REF? Type APPLY: " answer; [[ "$answer" == APPLY ]] || exit 1; fi
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/supabase/migrations" "$WORK/supabase/.temp"
cp "$ROOT/supabase/config.toml" "$WORK/supabase/config.toml"
cp -R "$ROOT/supabase/.temp/." "$WORK/supabase/.temp/"
printf '%s' "$PROJECT_REF" > "$WORK/supabase/.temp/project-ref"
if $GROUP_F; then files=("$BUNDLE"/[0-9][0-9][0-9]_*.sql); else files=("$BUNDLE"/0{01..22}_*.sql); fi
for file in "${files[@]}"; do [[ -f "$file" ]] || { echo "Missing migration $file" >&2; exit 1; }; number="$(basename "$file" | cut -d_ -f1)"; cp "$file" "$WORK/supabase/migrations/20260606${number}000_$(basename "$file" .sql).sql"; done
echo "Pushing $(find "$WORK/supabase/migrations" -type f | wc -l) clean migrations..."
supabase --workdir "$WORK" db push --include-all
if ! $GROUP_F; then psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f "$BUNDLE/post_bootstrap_config.sql"; fi
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f "$BUNDLE/verify_migration.sql"
echo "Bootstrap verification completed. Behavioral JWT/RLS tests must run in staging CI."
