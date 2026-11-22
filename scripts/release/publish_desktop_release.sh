#!/usr/bin/env bash
# publish_desktop_release.sh — publie un build de bureau (staging/prod) :
#
#   1. release GitHub `desktop-<env>-v<version>` sur le commit construit
#      (prerelease en staging), avec l'installateur Windows, l'archive Linux et
#      un `.sha256` par fichier ; une release déjà là (relance) est réutilisée
#      et ses fichiers écrasés ;
#   2. pour chaque plateforme, fiche signée (sign_desktop_payload.sh) puis
#      enregistrement auprès du serveur (register_desktop_release.sh).
#
# Appelé par le job `publish` de .github/workflows/build_desktop.yml.
#
# Variables attendues :
#   APP_ENV                      staging | prod
#   BUILD_NAME                   X.Y.Z (sortie de resolve_flutter_version.sh)
#   ARTIFACTS_DIR                dossier où les artefacts du run ont été téléchargés
#   GITHUB_SHA, GITHUB_REPOSITORY, GH_TOKEN   fournis par Actions
#   API_BASE_URL, APP_RELEASES_TOKEN, DESKTOP_UPDATE_SIGNING_KEY   secrets
#   RELEASE_NOTES                facultatif — notes FR saisies au lancement
set -euo pipefail
export LC_ALL=C.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAX_NOTES_CHARS=4000

: "${APP_ENV:?APP_ENV manquant}"
: "${BUILD_NAME:?BUILD_NAME manquant}"
: "${ARTIFACTS_DIR:?ARTIFACTS_DIR manquant}"
: "${GITHUB_SHA:?GITHUB_SHA manquant}"
REPOSITORY="${GITHUB_REPOSITORY:-juneMOke/schoolapp-flutter}"

case "$APP_ENV" in
  staging|prod) ;;
  *) echo "Rien à publier pour l'environnement '$APP_ENV'." >&2; exit 1 ;;
esac
if [[ ! "$BUILD_NAME" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "Version invalide : '$BUILD_NAME'." >&2
  exit 1
fi

TAG="desktop-$APP_ENV-v$BUILD_NAME"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# ── Fichiers : exactement un par plateforme ────────────────────────────────
find_one() {
  local pattern="$1" matches
  mapfile -t matches < <(find "$ARTIFACTS_DIR" -type f -name "$pattern")
  if [[ ${#matches[@]} -ne 1 ]]; then
    echo "Attendu 1 fichier '$pattern' dans $ARTIFACTS_DIR, trouvé ${#matches[@]}." >&2
    exit 1
  fi
  printf '%s' "${matches[0]}"
}
WINDOWS_FILE="$(find_one "eteelo-connect-$BUILD_NAME-$APP_ENV-windows-x64-setup.exe")"
LINUX_FILE="$(find_one "eteelo-connect-$BUILD_NAME-$APP_ENV-linux-x64.tar.gz")"

# Les `.sha256` au format de `sha256sum -c`, à côté de chaque fichier.
ASSETS=()
for file in "$WINDOWS_FILE" "$LINUX_FILE"; do
  name="$(basename "$file")"
  cp "$file" "$WORK_DIR/$name"
  (cd "$WORK_DIR" && sha256sum "$name" > "$name.sha256")
  ASSETS+=("$WORK_DIR/$name" "$WORK_DIR/$name.sha256")
done

# ── Notes ──────────────────────────────────────────────────────────────────
if [[ -n "${RELEASE_NOTES:-}" ]]; then
  NOTES_FR="$RELEASE_NOTES"
  if (( ${#NOTES_FR} > MAX_NOTES_CHARS )); then
    echo "Notes saisies trop longues (${#NOTES_FR} caractères, $MAX_NOTES_CHARS max)." >&2
    exit 1
  fi
else
  NOTES_FR="$(bash "$SCRIPT_DIR/desktop_release_notes.sh" "$APP_ENV" "$BUILD_NAME" "$GITHUB_SHA")"
fi
# Pas de traduction automatique : l'anglais reprend le français (accepté).
NOTES_EN="$NOTES_FR"
printf '%s\n' "$NOTES_FR" > "$WORK_DIR/notes.md"
echo "Notes :"
cat "$WORK_DIR/notes.md"

# ── Release GitHub ─────────────────────────────────────────────────────────
# Un tag déjà posé sur un AUTRE commit veut dire que cette version a déjà été
# publiée depuis un autre code : on ne l'écrase pas.
# (tag annoté : la ligne `^{}` donne le commit ; tag léger : la ligne seule.)
REMOTE_TAG_SHA="$(git ls-remote --tags origin "refs/tags/$TAG*" | awk -v t="refs/tags/$TAG" '
  $2 == t "^{}" { deref = $1 } $2 == t { plain = $1 }
  END { print (deref != "" ? deref : plain) }')"
if [[ -n "$REMOTE_TAG_SHA" && "$REMOTE_TAG_SHA" != "$GITHUB_SHA" ]]; then
  echo "Le tag $TAG pointe déjà sur $REMOTE_TAG_SHA, pas sur $GITHUB_SHA : publiez une nouvelle version." >&2
  exit 1
fi

if gh release view "$TAG" --repo "$REPOSITORY" >/dev/null 2>&1; then
  # Relance : on ne remplace JAMAIS un fichier publié par un fichier
  # différent. Une version déjà enregistrée sur le back pointe vers ces
  # octets : les remplacer ferait refuser la mise à jour à tous les postes
  # (empreinte qui ne concorde plus). Seule une relance du job `publish` sur
  # les MÊMES artefacts passe ; une reconstruction demande une nouvelle
  # version.
  REMOTE_DIR="$WORK_DIR/remote"
  mkdir -p "$REMOTE_DIR"
  if gh release download "$TAG" --repo "$REPOSITORY" --pattern '*.sha256' \
      --dir "$REMOTE_DIR" >/dev/null 2>&1; then
    for sum in "$REMOTE_DIR"/*.sha256; do
      [[ -e "$sum" ]] || continue
      local_sum="$WORK_DIR/$(basename "$sum")"
      if [[ -f "$local_sum" ]] && ! cmp -s "$sum" "$local_sum"; then
        echo "Release $TAG : $(basename "$sum" .sha256) déjà publié avec une autre empreinte." >&2
        echo "Une reconstruction demande une nouvelle version (version_tag)." >&2
        exit 1
      fi
    done
  fi
  echo "Release $TAG déjà présente, mêmes empreintes : fichiers repris."
  gh release upload "$TAG" "${ASSETS[@]}" --repo "$REPOSITORY" --clobber
else
  PRERELEASE=()
  [[ "$APP_ENV" == "staging" ]] && PRERELEASE=(--prerelease)
  gh release create "$TAG" "${ASSETS[@]}" \
    --repo "$REPOSITORY" \
    --target "$GITHUB_SHA" \
    --title "ETEELO CONNECT bureau $BUILD_NAME ($APP_ENV)" \
    --notes-file "$WORK_DIR/notes.md" \
    "${PRERELEASE[@]}"
fi

# ── Fiches signées et enregistrement ───────────────────────────────────────
DOWNLOAD_BASE="https://github.com/$REPOSITORY/releases/download/$TAG"
for platform in windows linux; do
  if [[ "$platform" == "windows" ]]; then file="$WINDOWS_FILE"; else file="$LINUX_FILE"; fi
  name="$(basename "$file")"
  bash "$SCRIPT_DIR/sign_desktop_payload.sh" \
    "$WORK_DIR/$name" "$platform" "$APP_ENV" "$BUILD_NAME" \
    "$DOWNLOAD_BASE/$name" "$NOTES_FR" "$NOTES_EN" > "$WORK_DIR/$platform.body.json"
  bash "$SCRIPT_DIR/register_desktop_release.sh" "$APP_ENV" "$platform" "$WORK_DIR/$platform.body.json"
done

echo "✓ $TAG publiée et enregistrée."
