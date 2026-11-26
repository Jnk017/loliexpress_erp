#!/usr/bin/env bash
# À exécuter sur la machine de vérification désignée par l'opérateur.
# Vérifie les prérequis hôte sans installer de logiciel ni modifier les droits.
set -u
printf '[Docker local]\n'
if ! docker version; then
  printf 'Le client ne peut pas joindre le daemon. Contacter l’opérateur hôte.\n' >&2
  exit 1
fi
if ! docker info --format 'Daemon={{.ServerVersion}}'; then
  exit 1
fi
printf '\n[Android]\n'
if command -v adb >/dev/null; then
  adb version
  adb devices | awk 'NR>1 && NF {print "état appareil: " $2}'
else
  printf 'ADB absent. Prévoir un appareil de test ou le SDK Android.\n'
fi
if command -v emulator >/dev/null; then
  emulator -list-avds
fi
if test -e /dev/kvm; then
  ls -ld /dev/kvm
fi
df -h .
