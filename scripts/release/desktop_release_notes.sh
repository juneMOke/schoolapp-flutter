#!/usr/bin/env bash
# desktop_release_notes.sh — imprime les notes d'une version de bureau : la
# liste des titres de PR fusionnées depuis la version précédente du même canal
# (tag `desktop-<env>-vX.Y.Z` le plus haut en SemVer, strictement inférieur à
# la version publiée).
#
# Usage :
#   bash scripts/release/desktop_release_notes.sh <env> <version> [<commit>]
#
# Sortie tronquée à 4000 caractères (et non octets).
set -euo pipefail
export LC_ALL=C.UTF-8

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage : $0 <env> <version> [<commit>]" >&2
  exit 1
fi

CHANNEL="$1"
VERSION="$2"
COMMIT="${3:-HEAD}"
MAX_CHARS=4000

# Version précédente : les tags du canal, triés en SemVer, le dernier qui
# précède strictement la version publiée (une relance ne se prend pas pour
# sa propre devancière).
PREVIOUS_TAG=""
while IFS= read -r version; do
  [[ -z "$version" ]] && continue
  if [[ "$(printf '%s\n%s\n' "$version" "$VERSION" | sort -V | head -n1)" == "$version" \
        && "$version" != "$VERSION" ]]; then
    PREVIOUS_TAG="desktop-$CHANNEL-v$version"
  fi
done < <(git tag -l "desktop-$CHANNEL-v*" \
  | sed -n "s/^desktop-$CHANNEL-v\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\)$/\1/p" \
  | sort -V)

if [[ -n "$PREVIOUS_TAG" ]]; then
  RANGE="$PREVIOUS_TAG..$COMMIT"
  LIMIT=()
else
  # Première publication du canal : les 30 dernières fusions suffisent.
  RANGE="$COMMIT"
  LIMIT=(-n 30)
fi

NOTES=""
# Une fusion de PR a pour sujet « Merge pull request #N from … » et pour
# première ligne du corps le titre de la PR ; les fusions de branche
# (« Merge branch … », « Merge origin/main … ») sont écartées.
while IFS= read -r hash; do
  subject="$(git log -1 --format=%s "$hash")"
  if [[ "$subject" =~ ^Merge\ pull\ request\ \#([0-9]+) ]]; then
    number="${BASH_REMATCH[1]}"
    title="$(git log -1 --format=%b "$hash" | sed -n '/[^[:space:]]/{p;q;}')"
    [[ -z "$title" ]] && continue
    NOTES+="- $title (#$number)"$'\n'
  fi
done < <(git log --first-parent --merges "${LIMIT[@]}" --format=%H "$RANGE")

NOTES="${NOTES%$'\n'}"
if [[ -z "$NOTES" ]]; then
  NOTES="Version $VERSION."
fi

if (( ${#NOTES} > MAX_CHARS )); then
  NOTES="${NOTES:0:$((MAX_CHARS - 1))}…"
fi
printf '%s' "$NOTES"
