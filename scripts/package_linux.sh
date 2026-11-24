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
# libsecret-1-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev.
# Prérequis d'exécution : libgtk-3-0 libsecret-1-0, un trousseau
# (gnome-keyring) et GStreamer (gstreamer1.0-plugins-good), voir install.sh.
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
# ETEELO_APP_ENV choisit l'identifiant de l'application (linux/CMakeLists.txt) :
# une instance unique par environnement.
ETEELO_APP_ENV="$APP_ENV" flutter build linux --release "${VERSION_ARGS[@]}" \
  --dart-define=APP_ENV="$APP_ENV" \
  --dart-define=API_BASE_URL="$API_BASE_URL"

BUNDLE="build/linux/x64/release/bundle"
test -f "$BUNDLE/lib/libsqlite3mc.so" || {
  echo "libsqlite3mc.so absente du bundle : la base ne pourrait pas s'ouvrir." >&2
  exit 1
}

# L'application lit sa version dans `version.json` (package_info_plus sous
# Linux) — c'est elle qu'elle compare à la dernière version publiée. Or
# `flutter build linux --build-name` n'y reporte pas le numéro : le fichier
# gardait celui du pubspec (1.0.0), et chaque poste se voyait proposer sans fin
# la version qu'il venait d'installer. On le réécrit, puis on le relit.
VERSION_JSON="$BUNDLE/data/flutter_assets/version.json"
if [[ -n "$BUILD_NAME" ]]; then
  python3 - "$VERSION_JSON" "$BUILD_NAME" "$BUILD_NUMBER" <<'PY'
import json, sys
path, name, number = sys.argv[1:4]
with open(path) as f:
    data = json.load(f)
data["version"] = name
if number:
    data["build_number"] = number
with open(path, "w") as f:
    json.dump(data, f)
PY
  ACTUAL="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$VERSION_JSON")"
  if [[ "$ACTUAL" != "$BUILD_NAME" ]]; then
    echo "version.json annonce $ACTUAL au lieu de $BUILD_NAME : la mise à jour bouclerait." >&2
    exit 1
  fi
  echo "✓ version.json : $ACTUAL"
fi

VERSION="${BUILD_NAME:-$(grep '^version:' pubspec.yaml | sed 's/version: *//; s/+.*//')}"
DIST="build/dist"
STAGE="$DIST/eteelo-connect"
ARCHIVE="$DIST/eteelo-connect-$VERSION-$APP_ENV-linux-x64.tar.gz"

rm -rf "$STAGE" "$ARCHIVE"
mkdir -p "$STAGE"
cp -r "$BUNDLE/." "$STAGE/"
cp assets/app-icon/play_store_512.png "$STAGE/eteelo-connect.png"
cp linux/packaging/eteelo-connect.desktop "$STAGE/"
# install.sh apprend son environnement ici : il en tire son dossier et son
# entrée de menu, pour que staging et prod cohabitent sur un même poste.
sed "s|@APP_ENV@|$APP_ENV|" linux/packaging/install.sh > "$STAGE/install.sh"

tar -C "$DIST" -czf "$ARCHIVE" eteelo-connect
echo "✓ $ARCHIVE"
