#!/usr/bin/env bash
# validate_env.sh
# Vérifie que les variables d'environnement obligatoires sont présentes et valides
# avant tout build. Fait échouer le pipeline si une variable est manquante.
#
# Usage :
#   bash scripts/validate_env.sh --env=dev --api-base-url=https://api-dev.example.com
#   bash scripts/validate_env.sh --env=prod --api-base-url=https://api.example.com

set -euo pipefail

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'

err()  { echo -e "${RED}[ERREUR]${RESET} $*" >&2; }
ok()   { echo -e "${GREEN}[OK]${RESET}    $*"; }
info() { echo -e "${YELLOW}[INFO]${RESET}  $*"; }

# --------------------------------------------------------------------------
# Parse arguments
# --------------------------------------------------------------------------
APP_ENV=""
API_BASE_URL=""

for arg in "$@"; do
  case $arg in
    --env=*)         APP_ENV="${arg#*=}"         ;;
    --api-base-url=*) API_BASE_URL="${arg#*=}"   ;;
    *) err "Argument inconnu : $arg"; exit 1     ;;
  esac
done

# --------------------------------------------------------------------------
# Validation 1 — APP_ENV
# --------------------------------------------------------------------------
echo ""
info "Validation de APP_ENV..."

if [[ -z "$APP_ENV" ]]; then
  err "APP_ENV est obligatoire. Passez --env=dev|staging|prod"
  exit 1
fi

case "$APP_ENV" in
  dev|staging|prod) ok "APP_ENV=${APP_ENV}" ;;
  *)
    err "APP_ENV doit valoir 'dev', 'staging' ou 'prod'. Reçu : '${APP_ENV}'"
    exit 1
    ;;
esac

# --------------------------------------------------------------------------
# Validation 2 — API_BASE_URL
# --------------------------------------------------------------------------
info "Validation de API_BASE_URL..."

if [[ -z "$API_BASE_URL" ]]; then
  err "API_BASE_URL est obligatoire. Passez --api-base-url=https://..."
  exit 1
fi

# Vérifier schéma http/https
if [[ ! "$API_BASE_URL" =~ ^https?:// ]]; then
  err "API_BASE_URL doit commencer par 'http://' ou 'https://'. Reçu : '${API_BASE_URL}'"
  exit 1
fi

# Vérifier qu'il y a un host non vide après le schéma
HOST="$(echo "$API_BASE_URL" | sed -E 's|^https?://||' | cut -d '/' -f1 | cut -d ':' -f1)"
if [[ -z "$HOST" ]]; then
  err "API_BASE_URL ne contient pas de host valide. Reçu : '${API_BASE_URL}'"
  exit 1
fi

ok "API_BASE_URL=${API_BASE_URL}"

# --------------------------------------------------------------------------
# Validation 3 — cohérence env/url
# --------------------------------------------------------------------------
info "Validation de la cohérence env / URL..."

if [[ "$APP_ENV" == "prod" ]] && [[ "$API_BASE_URL" =~ (dev|staging|localhost|127\.0\.0\.1|10\.0\.) ]]; then
  err "Incohérence détectée : APP_ENV=prod mais API_BASE_URL semble pointer vers un env non-prod."
  err "URL reçue : ${API_BASE_URL}"
  err "Un build de production ne peut pas utiliser une URL de dev/staging."
  exit 1
fi

if [[ "$APP_ENV" == "staging" ]] && [[ "$API_BASE_URL" =~ (localhost|127\.0\.0\.1|10\.0\.) ]]; then
  err "Incohérence : APP_ENV=staging mais API_BASE_URL pointe vers localhost/loopback."
  exit 1
fi

ok "Cohérence env/URL validée"

# --------------------------------------------------------------------------
# Résumé
# --------------------------------------------------------------------------
echo ""
echo -e "${BOLD}─────────────────────────────────────────${RESET}"
echo -e "${GREEN}✓ Validation réussie${RESET}"
echo -e "  APP_ENV         = ${BOLD}${APP_ENV}${RESET}"
echo -e "  API_BASE_URL    = ${BOLD}${API_BASE_URL}${RESET}"
echo -e "${BOLD}─────────────────────────────────────────${RESET}"
echo ""
