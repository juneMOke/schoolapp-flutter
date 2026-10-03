#!/usr/bin/env bash
# package_linux.sh — construit l'application pour Linux x64 et l'emballe en
# build/dist/eteelo-connect-<version>-linux-x64.tar.gz.
#
# Usage :
#   bash scripts/package_linux.sh --env=staging --api-base-url=https://… \
#     [--build-name=1.2.3] [--build-number=42]
#
# Le poste n'a pas de flavor (Flutter n'en connaît pas sous Linux) : seuls les
# `--dart-define` distinguent les environnements.
#
# Prérequis de build : clang cmake ninja-build pkg-config libgtk-3-dev
# libsecret-1-dev. Prérequis d'exécution : libgtk-3-0 libsecret-1-0 et un
# trousseau (gnome-keyring), voir install.sh.
set -euo pipefail

APP_ENV=""
API_BASE_URL=""
BUILD_NAME=""
BUILD_NUMBER=""

for arg in "$@"; do
  case $arg in
    --env=*)          APP_ENV="${arg#*=}"      ;;
    --api-base-url=*) API_BASE_URL="${arg#*=}" ;;
    --build-name=*)   BUILD_NAME="${arg#*=}"   ;;
    --build-number=*) BUILD_NUMBER="${arg#*=}" ;;
    *) echo "Argument inconnu : $arg" >&2; exit 1 ;;
  esac
done

bash scripts/validate_env.sh --env="$APP_ENV" --api-base-url="$API_BASE_URL"

VERSION_ARGS=()
[[ -n "$BUILD_NAME" ]] && VERSION_ARGS+=(--build-name "$BUILD_NAME")
[[ -n "$BUILD_NUMBER" ]] && VERSION_ARGS+=(--build-number "$BUILD_NUMBER")

# ⚠️ Build PROPRE, toujours. Un build incrémental a déjà livré un `libapp.so`
# qui ignorait la bibliothèque SQLite3MultipleCiphers posée à côté de lui :
# l'application s'arrêtait à l'ouverture de la base (« No available native
# assets »).
flutter clean
flutter build linux --release "${VERSION_ARGS[@]}" \
  --dart-define=APP_ENV="$APP_ENV" \
  --dart-define=API_BASE_URL="$API_BASE_URL"

BUNDLE="build/linux/x64/release/bundle"
test -f "$BUNDLE/lib/libsqlite3mc.so" || {
  echo "libsqlite3mc.so absente du bundle : la base ne pourrait pas s'ouvrir." >&2
  exit 1
}

VERSION="${BUILD_NAME:-$(grep '^version:' pubspec.yaml | sed 's/version: *//; s/+.*//')}"
DIST="build/dist"
STAGE="$DIST/eteelo-connect"
ARCHIVE="$DIST/eteelo-connect-$VERSION-$APP_ENV-linux-x64.tar.gz"

rm -rf "$STAGE" "$ARCHIVE"
mkdir -p "$STAGE"
cp -r "$BUNDLE/." "$STAGE/"
cp assets/app-icon/play_store_512.png "$STAGE/eteelo-connect.png"
cp linux/packaging/eteelo-connect.desktop linux/packaging/install.sh "$STAGE/"

tar -C "$DIST" -czf "$ARCHIVE" eteelo-connect
echo "✓ $ARCHIVE"
