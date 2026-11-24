#!/usr/bin/env bash
# register_desktop_release.sh — enregistre une mise à jour signée auprès du
# serveur :
#
#   PUT <API_BASE_URL>/api/v1/platform/app-releases/desktop/<canal>/<plateforme>
#
# Usage :
#   API_BASE_URL=https://… APP_RELEASES_TOKEN=… \
#     bash scripts/release/register_desktop_release.sh <env> <platform> <corps.json>
#
# API_BASE_URL est la RACINE du serveur, comme pour l'application (dont les
# routes portent elles-mêmes `/api/v1`, cf. AppConstants) ; un `/api/v1` ou un
# `/` final éventuel est retiré pour ne pas le doubler.
#
# Réponses : 200/201 = succès ; 401/404/409/422 (et tout autre 4xx) = échec
# immédiat, corps affiché ; erreur réseau, 429 ou 5xx = jusqu'à 3 essais.
# Le serveur est idempotent sur un rejeu identique.
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage : $0 <env> <platform> <corps.json>" >&2
  exit 1
fi

CHANNEL="$1"
PLATFORM="$2"
BODY_FILE="$3"
MAX_ATTEMPTS="${REGISTER_MAX_ATTEMPTS:-3}"
RETRY_DELAY="${REGISTER_RETRY_DELAY:-15}"

case "$CHANNEL" in staging|prod) ;; *) echo "Canal invalide : '$CHANNEL'." >&2; exit 1 ;; esac
case "$PLATFORM" in windows|linux) ;; *) echo "Plateforme invalide : '$PLATFORM'." >&2; exit 1 ;; esac
[[ -f "$BODY_FILE" ]] || { echo "Corps introuvable : $BODY_FILE" >&2; exit 1; }
: "${API_BASE_URL:?API_BASE_URL manquant}"
: "${APP_RELEASES_TOKEN:?APP_RELEASES_TOKEN manquant}"

BASE="${API_BASE_URL%/}"
BASE="${BASE%/api/v1}"
ENDPOINT="$BASE/api/v1/platform/app-releases/desktop/$CHANNEL/$PLATFORM"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
# Le jeton passe par un fichier d'en-têtes : il n'apparaît ni dans la ligne de
# commande ni dans les journaux.
(umask 077 && printf 'X-Release-Token: %s\n' "$APP_RELEASES_TOKEN" > "$TMP_DIR/headers")

for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
  echo "→ PUT $ENDPOINT (essai $attempt/$MAX_ATTEMPTS)"
  set +e
  STATUS="$(curl -sS -X PUT "$ENDPOINT" \
    -H @"$TMP_DIR/headers" \
    -H 'Content-Type: application/json' \
    --data-binary @"$BODY_FILE" \
    --connect-timeout 15 --max-time 60 \
    -o "$TMP_DIR/response" -w '%{http_code}')"
  CURL_EXIT=$?
  set -e

  if [[ $CURL_EXIT -ne 0 ]]; then
    echo "Erreur réseau (curl $CURL_EXIT)." >&2
  else
    case "$STATUS" in
      200|201)
        echo "✓ $PLATFORM enregistré sur le canal $CHANNEL (HTTP $STATUS)."
        exit 0
        ;;
      429|5??)
        echo "HTTP $STATUS — nouvel essai possible." >&2
        cat "$TMP_DIR/response" >&2 || true
        echo >&2
        ;;
      *)
        # 401 jeton, 404 route/canal, 409 version déjà prise par un autre
        # fichier, 422 payload refusé : rejouer ne changerait rien.
        echo "Échec HTTP $STATUS :" >&2
        cat "$TMP_DIR/response" >&2 || true
        echo >&2
        exit 1
        ;;
    esac
  fi

  if ((attempt < MAX_ATTEMPTS)); then
    sleep "$((RETRY_DELAY * attempt))"
  fi
done

echo "Échec après $MAX_ATTEMPTS essais." >&2
exit 1
