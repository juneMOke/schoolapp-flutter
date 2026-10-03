#!/usr/bin/env bash
# install.sh — installe ETEELO CONNECT pour l'utilisateur courant, sans droits
# administrateur. Livré DANS l'archive Linux, à lancer depuis le dossier
# décompressé :
#
#   tar -xzf eteelo-connect-<version>-linux-x64.tar.gz
#   bash eteelo-connect/install.sh
#
# Réinstaller par-dessus une version précédente remplace le programme, jamais
# les données : la base locale vit dans ~/.local/share/com.junethink.school_app_flutter.
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/eteelo-connect"
APPLICATIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

# Le jeton de la session et la clé de la base vivent dans le trousseau du
# système (Secret Service). Sans lui, l'application ne peut pas démarrer.
# Sortie capturée d'abord : sous `pipefail`, `grep -q` qui referme le tube
# tôt ferait échouer `ldconfig` (SIGPIPE), et l'alerte tomberait à tort.
SHARED_LIBS="$(/sbin/ldconfig -p 2>/dev/null || true)"
if [[ "$SHARED_LIBS" != *libsecret-1.so.0* ]]; then
  echo "⚠ libsecret absente : installez-la (Debian/Ubuntu : sudo apt install libsecret-1-0 gnome-keyring)." >&2
fi

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR" "$APPLICATIONS_DIR"
cp -r "$SOURCE_DIR/." "$INSTALL_DIR/"
rm -f "$INSTALL_DIR/install.sh" "$INSTALL_DIR/eteelo-connect.desktop"

sed "s|@INSTALL_DIR@|$INSTALL_DIR|g" "$SOURCE_DIR/eteelo-connect.desktop" \
  > "$APPLICATIONS_DIR/eteelo-connect.desktop"
chmod +x "$INSTALL_DIR/school_app_flutter"

echo "✓ ETEELO CONNECT installé dans $INSTALL_DIR (menu des applications)."
