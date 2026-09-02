#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: resolve_flutter_version.sh --env <dev|staging|prod> [--version-tag <tag>] [--pubspec-file <path>]

Outputs:
  build_name=<x.y.z>
  build_number=<integer>
EOF
}

APP_ENV=""
VERSION_TAG=""
PUBSPEC_FILE="pubspec.yaml"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      APP_ENV="${2:-}"
      shift 2
      ;;
    --version-tag)
      VERSION_TAG="${2:-}"
      shift 2
      ;;
    --pubspec-file)
      PUBSPEC_FILE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argument inconnu: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
 done

if [[ -z "$APP_ENV" ]]; then
  echo "--env est obligatoire." >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$PUBSPEC_FILE" ]]; then
  echo "Fichier pubspec introuvable: $PUBSPEC_FILE" >&2
  exit 1
fi

PUBSPEC_VERSION_LINE="$(awk -F': ' '/^version:/ {print $2; exit}' "$PUBSPEC_FILE")"
if [[ -z "$PUBSPEC_VERSION_LINE" ]]; then
  echo "Impossible de lire la version dans $PUBSPEC_FILE." >&2
  exit 1
fi

BASE_BUILD_NAME="${PUBSPEC_VERSION_LINE%%+*}"
BASE_BUILD_NUMBER="${PUBSPEC_VERSION_LINE##*+}"
if [[ "$PUBSPEC_VERSION_LINE" == "$BASE_BUILD_NAME" ]]; then
  BASE_BUILD_NUMBER="1"
fi

# Normalise un tag SemVer (`v1.2.3` ou `1.2.3`) et le décompose dans les
# variables globales MAJOR / MINOR / PATCH. Sort en erreur si le tag est
# malformé : une version fournie à la main ne doit jamais être ignorée
# en silence ni retomber discrètement sur le pubspec.
parse_version_tag() {
  local tag="${1#v}"
  if [[ ! "$tag" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "Tag de version invalide: '$1'. Attendu: vX.Y.Z ou X.Y.Z" >&2
    exit 1
  fi
  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"
}

case "$APP_ENV" in
  dev|staging)
    # Un tag explicite prime sur le pubspec : c'est ce que l'opérateur a saisi
    # dans le `workflow_dispatch`. Sans tag, on retombe sur `pubspec.yaml`.
    if [[ -n "$VERSION_TAG" ]]; then
      parse_version_tag "$VERSION_TAG"
      BUILD_NAME="$MAJOR.$MINOR.$PATCH"
    else
      BUILD_NAME="$BASE_BUILD_NAME"
    fi
    # Le build number reste le numéro de run : Firebase App Distribution et le
    # Play Store exigent une suite strictement croissante, qu'un même tag
    # rejoué ne fournirait pas.
    BUILD_NUMBER="${GITHUB_RUN_NUMBER:-$BASE_BUILD_NUMBER}"
    ;;
  prod)
    if [[ -z "$VERSION_TAG" ]]; then
      if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        VERSION_TAG="$(git describe --tags --abbrev=0 2>/dev/null || true)"
      fi
    fi

    if [[ -z "$VERSION_TAG" ]]; then
      echo "Aucun tag de version fourni et aucun tag Git détecté pour la prod." >&2
      exit 1
    fi

    parse_version_tag "$VERSION_TAG"

    BUILD_NAME="$MAJOR.$MINOR.$PATCH"
    BUILD_NUMBER="$((MAJOR * 1000000 + MINOR * 1000 + PATCH))"
    ;;
  *)
    echo "Environnement invalide: '$APP_ENV'. Attendu: dev, staging ou prod." >&2
    exit 1
    ;;
esac

echo "build_name=$BUILD_NAME"
echo "build_number=$BUILD_NUMBER"
