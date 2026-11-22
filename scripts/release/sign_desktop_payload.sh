#!/usr/bin/env bash
# sign_desktop_payload.sh — compose et signe la fiche d'une mise à jour de
# poste de bureau, puis écrit sur la sortie standard le corps JSON attendu par
# `PUT /api/v1/platform/app-releases/desktop/<canal>/<plateforme>` :
#
#   {"signedPayload":"<chaîne JSON>","signature":"<base64 Ed25519>"}
#
# Usage :
#   DESKTOP_UPDATE_SIGNING_KEY="$(cat cle.pem)" \
#     bash scripts/release/sign_desktop_payload.sh \
#       <fichier> <platform> <env> <version> <url> <notesFr> <notesEn>
#
# La clé privée PEM se lit dans DESKTOP_UPDATE_SIGNING_KEY (contenu) ou, à
# défaut, dans le fichier DESKTOP_UPDATE_SIGNING_KEY_FILE.
#
# `signedPayload` est un objet JSON compact, clés triées, UTF-8 brut (pas
# d'échappement \uXXXX des accents), sans saut de ligne final. La signature
# porte sur ses octets EXACTS : le serveur et l'application la vérifient sur la
# chaîne telle quelle, sans la ré-sérialiser.
set -euo pipefail
export LC_ALL=C.UTF-8

if [[ $# -ne 7 ]]; then
  echo "Usage : $0 <fichier> <platform> <env> <version> <url> <notesFr> <notesEn>" >&2
  exit 1
fi

FILE="$1"
PLATFORM="$2"
CHANNEL="$3"
VERSION="$4"
URL="$5"
NOTES_FR="$6"
NOTES_EN="$7"

# ── Contrôles : un payload signé ne se rattrape pas ────────────────────────
[[ -f "$FILE" ]] || { echo "Fichier introuvable : $FILE" >&2; exit 1; }
case "$PLATFORM" in
  windows|linux) ;;
  *) echo "Plateforme invalide : '$PLATFORM' (windows|linux)." >&2; exit 1 ;;
esac
case "$CHANNEL" in
  staging|prod) ;;
  *) echo "Canal invalide : '$CHANNEL' (staging|prod)." >&2; exit 1 ;;
esac
if [[ ! "$VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  echo "Version invalide : '$VERSION' (X.Y.Z attendu)." >&2
  exit 1
fi
[[ "$URL" =~ ^https:// ]] || { echo "URL non HTTPS : '$URL'." >&2; exit 1; }

# `pkeyutl -rawin` (signature Ed25519 d'un message brut) n'existe qu'à partir
# d'OpenSSL 3.0 — c'est le cas des runners ubuntu-latest.
OPENSSL_MAJOR="$(openssl version | sed -E 's/^OpenSSL ([0-9]+)\..*/\1/')"
if [[ ! "$OPENSSL_MAJOR" =~ ^[0-9]+$ ]] || (( OPENSSL_MAJOR < 3 )); then
  echo "OpenSSL 3 requis (trouvé : $(openssl version))." >&2
  exit 1
fi

KEY_FILE=""
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
if [[ -n "${DESKTOP_UPDATE_SIGNING_KEY:-}" ]]; then
  KEY_FILE="$TMP_DIR/key.pem"
  (umask 077 && printf '%s\n' "$DESKTOP_UPDATE_SIGNING_KEY" > "$KEY_FILE")
elif [[ -n "${DESKTOP_UPDATE_SIGNING_KEY_FILE:-}" ]]; then
  KEY_FILE="$DESKTOP_UPDATE_SIGNING_KEY_FILE"
else
  echo "Clé de signature absente (DESKTOP_UPDATE_SIGNING_KEY ou DESKTOP_UPDATE_SIGNING_KEY_FILE)." >&2
  exit 1
fi

# ── Empreinte et taille du fichier publié ──────────────────────────────────
SHA256="$(sha256sum "$FILE" | cut -d ' ' -f1)"
SIZE="$(wc -c < "$FILE" | tr -d ' ')"
[[ "$SHA256" =~ ^[0-9a-f]{64}$ ]] || { echo "Empreinte inattendue : $SHA256" >&2; exit 1; }

# ── Composition : exactement 8 clés, triées (-S), compact (-c) ──────────────
# `$( … )` retire le saut de ligne final de jq : la chaîne signée n'en a pas.
PAYLOAD="$(jq -cSn \
  --arg channel "$CHANNEL" \
  --arg notesEn "$NOTES_EN" \
  --arg notesFr "$NOTES_FR" \
  --arg platform "$PLATFORM" \
  --arg sha256 "$SHA256" \
  --argjson size "$SIZE" \
  --arg url "$URL" \
  --arg version "$VERSION" \
  '{channel: $channel, notesEn: $notesEn, notesFr: $notesFr, platform: $platform,
    sha256: $sha256, size: $size, url: $url, version: $version}')"

# ── Signature Ed25519 sur les octets exacts de la chaîne ───────────────────
printf '%s' "$PAYLOAD" > "$TMP_DIR/payload.json"
openssl pkeyutl -sign -rawin -inkey "$KEY_FILE" \
  -in "$TMP_DIR/payload.json" -out "$TMP_DIR/payload.sig"
SIG_SIZE="$(wc -c < "$TMP_DIR/payload.sig" | tr -d ' ')"
[[ "$SIG_SIZE" -eq 64 ]] || { echo "Signature de $SIG_SIZE octets (64 attendus)." >&2; exit 1; }
SIGNATURE="$(base64 < "$TMP_DIR/payload.sig" | tr -d '\n')"

# Contrôle croisé : la clé publique dérivée vérifie bien ce qu'on vient de signer.
openssl pkey -in "$KEY_FILE" -pubout -out "$TMP_DIR/pub.pem"
openssl pkeyutl -verify -rawin -pubin -inkey "$TMP_DIR/pub.pem" \
  -in "$TMP_DIR/payload.json" -sigfile "$TMP_DIR/payload.sig" >/dev/null

jq -cn --arg signedPayload "$PAYLOAD" --arg signature "$SIGNATURE" \
  '{signedPayload: $signedPayload, signature: $signature}'
