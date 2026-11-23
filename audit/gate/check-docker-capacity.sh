#!/usr/bin/env bash
set -euo pipefail

# Run with the Docker context used by the gate. On an inaccessible rootless
# data-root, pass the verified Unix owner with DOCKER_DATA_OWNER.
minimum_kib=$((15 * 1024 * 1024))
data_root=$(docker info --format '{{.DockerRootDir}}')
[[ "$data_root" = /* ]] || { echo 'Docker data-root unavailable' >&2; exit 2; }
docker info --format 'Docker data-root={{.DockerRootDir}} driver={{.Driver}}'
docker system df

if space=$(df -Pk -- "$data_root" 2>/dev/null); then
  :
elif [[ -n "${DOCKER_DATA_OWNER:-}" ]] && command -v sudo >/dev/null; then
  space=$(sudo -u "$DOCKER_DATA_OWNER" df -Pk -- "$data_root")
else
  echo 'Docker data-root is inaccessible. Run on the Docker host as its owner, or set DOCKER_DATA_OWNER with sudo available.' >&2
  exit 2
fi
printf '%s\n' "$space"
available=$(awk 'END {print $4}' <<< "$space")
[[ "$available" =~ ^[0-9]+$ ]] || exit 2
if ((available < minimum_kib)); then
  echo 'BLOCKED: Docker data-root requires at least 15 GiB available.' >&2
  exit 1
fi
echo 'DOCKER_CAPACITY_OK'
