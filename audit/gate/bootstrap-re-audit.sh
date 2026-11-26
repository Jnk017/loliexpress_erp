#!/usr/bin/env bash
# Inventaire local du bootstrap. Ne démarre aucun service et ne lit aucun secret.
set -u
repo="${1:-/workspace/work/loli-verify}"
tools_root="${LOLI_BOOTSTRAP_TOOLS:-/workspace/work/tools}"
export PATH="$tools_root/flutter/bin:$tools_root/bin:$PATH"
export PUB_CACHE="$tools_root/pub-cache"
export XDG_CACHE_HOME="$tools_root/xdg-cache"
export XDG_CONFIG_HOME="$tools_root/xdg-config"
probe() {
  printf '\n[%s]\n' "$1"
  if command -v "$1" >/dev/null; then
    timeout 15 "$@" 2>&1
    printf 'exit=%s\n' "$?"
  else
    printf 'introuvable dans PATH\n'
  fi
}
probe git --version
git -C "$repo" rev-parse HEAD 2>&1
test ! -f "$repo/pubspec.yaml" || printf 'pubspec.yaml présent\n'
probe flutter --suppress-analytics --version
probe dart --version
probe supabase --version
probe psql --version
probe docker version
probe deno --version
probe playwright --version
probe chromium --version
probe adb version
probe emulator -version
if command -v adb >/dev/null; then
  timeout 10 adb devices | awk 'NR>1 && NF {print "appareil ADB: " $2}'
fi
printf '\n[Configuration E2E, état seulement]\n'
for key in E2E_BASE_URL E2E_SUPABASE_URL; do
  if [[ -n "${!key:-}" ]]; then
    printf '%s présente\n' "$key"
  else
    printf '%s absente\n' "$key"
  fi
done
test ! -f "$repo/.env.test" || printf '.env.test présente, non lue\n'
if test -f "$repo/supabase/config.toml"; then
  python - "$repo/supabase/config.toml" <<'PY'
import sys
import tomllib
with open(sys.argv[1], "rb") as file:
    print("inbucket.enabled =", tomllib.load(file).get("inbucket", {}).get("enabled", False))
PY
fi
