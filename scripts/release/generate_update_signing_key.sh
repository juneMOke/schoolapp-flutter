#!/usr/bin/env bash
# generate_update_signing_key.sh — crée la paire de clés Ed25519 qui signe les
# mises à jour des postes de bureau.
#
# Usage :
#   bash scripts/release/generate_update_signing_key.sh <dossier de sortie>
#
# Écrit :
#   <dossier>/desktop_update_signing_key.pem   clé PRIVÉE (PEM PKCS#8, chmod 600)
#                                              → contenu du secret GitHub
#                                                DESKTOP_UPDATE_SIGNING_KEY
#   <dossier>/desktop_update_public_key.b64    clé publique BRUTE (32 octets,
#                                              base64 standard) → embarquée
#                                              par l'application
# et imprime la clé publique sur la sortie standard.
#
# ⚠️ La clé privée ne doit JAMAIS être commitée : le dépôt est public.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage : $0 <dossier de sortie>" >&2
  exit 1
fi

OUT_DIR="$1"
PRIVATE_KEY="$OUT_DIR/desktop_update_signing_key.pem"
PUBLIC_KEY="$OUT_DIR/desktop_update_public_key.b64"

if [[ -e "$PRIVATE_KEY" ]]; then
  # Écraser une clé en service rendrait toutes les mises à jour invérifiables
  # pour les postes déjà installés.
  echo "Refus : $PRIVATE_KEY existe déjà." >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
# umask d'abord : la clé ne doit pas être lisible par d'autres, même un instant.
umask 077
openssl genpkey -algorithm ed25519 -out "$PRIVATE_KEY"
chmod 600 "$PRIVATE_KEY"

# Le DER SubjectPublicKeyInfo d'une clé Ed25519 fait 44 octets : 12 d'en-tête
# fixe puis les 32 octets bruts de la clé.
DER_SIZE="$(openssl pkey -in "$PRIVATE_KEY" -pubout -outform DER | wc -c)"
if [[ "$DER_SIZE" -ne 44 ]]; then
  echo "Clé publique DER inattendue ($DER_SIZE octets au lieu de 44)." >&2
  exit 1
fi
openssl pkey -in "$PRIVATE_KEY" -pubout -outform DER | tail -c 32 | base64 | tr -d '\n' > "$PUBLIC_KEY"
chmod 644 "$PUBLIC_KEY"

echo "Clé privée : $PRIVATE_KEY (à verser dans le secret DESKTOP_UPDATE_SIGNING_KEY, puis à ranger hors ligne)" >&2
echo "Clé publique (32 octets, base64) :" >&2
cat "$PUBLIC_KEY"
echo
