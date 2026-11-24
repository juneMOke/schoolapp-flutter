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
#
# Une installation par environnement, comme l'installateur Windows : la prod
# vit dans `eteelo-connect`, la staging dans `eteelo-connect-staging` (dev :
# `eteelo-connect-dev`), chacune avec son entrée de menu. Installer une
# staging ne remplace donc jamais la prod du poste. APP_ENV est posé par
# scripts/package_linux.sh ; la règle des dossiers est reprise par
# `LinuxDesktopInstaller` (lib/features/desktop_update/data/desktop_installer.dart).
set -euo pipefail

APP_ENV="@APP_ENV@"
case "$APP_ENV" in
  prod)    SUFFIX="";         APP_NAME="ETEELO CONNECT" ;;
  staging) SUFFIX="-staging"; APP_NAME="ETEELO CONNECT Staging" ;;
  dev)     SUFFIX="-dev";     APP_NAME="ETEELO CONNECT Dev" ;;
  *)
    echo "Environnement inconnu ($APP_ENV) : archive mal emballée." >&2
    exit 1
    ;;
esac

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/eteelo-connect$SUFFIX"
APPLICATIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_FILE="$APPLICATIONS_DIR/eteelo-connect$SUFFIX.desktop"

# Le jeton de la session et la clé de la base vivent dans le trousseau du
# système (Secret Service). Sans lui, l'application ne peut pas démarrer.
# Sortie capturée d'abord : sous `pipefail`, `grep -q` qui referme le tube
# tôt ferait échouer `ldconfig` (SIGPIPE), et l'alerte tomberait à tort.
SHARED_LIBS="$(/sbin/ldconfig -p 2>/dev/null || true)"
if [[ "$SHARED_LIBS" != *libsecret-1.so.0* ]]; then
  echo "⚠ libsecret absente : installez-la (Debian/Ubuntu : sudo apt install libsecret-1-0 gnome-keyring)." >&2
fi
# La caméra lie GStreamer au chargement : sans lui, l'application ne démarre pas.
if [[ "$SHARED_LIBS" != *libgstapp-1.0.so.0* ]]; then
  echo "⚠ GStreamer absent : installez-le (Debian/Ubuntu : sudo apt install gstreamer1.0-plugins-base gstreamer1.0-plugins-good)." >&2
fi

# Remplacement en deux temps : la nouvelle version est copiée À CÔTÉ, puis
# prend la place de l'ancienne par renommage. Une copie qui échoue (disque
# plein) laisse l'ancienne version intacte et lançable — l'application lance ce
# script toute seule lors d'une mise à jour.
NEW_DIR="$INSTALL_DIR.new"
OLD_DIR="$INSTALL_DIR.old"
rm -rf "$NEW_DIR" "$OLD_DIR"
mkdir -p "$NEW_DIR" "$APPLICATIONS_DIR"
cp -r "$SOURCE_DIR/." "$NEW_DIR/"
rm -f "$NEW_DIR/install.sh" "$NEW_DIR/eteelo-connect.desktop"
chmod +x "$NEW_DIR/school_app_flutter"
if [[ -d "$INSTALL_DIR" ]]; then
  mv "$INSTALL_DIR" "$OLD_DIR"
fi
mv "$NEW_DIR" "$INSTALL_DIR"
rm -rf "$OLD_DIR"

sed -e "s|@INSTALL_DIR@|$INSTALL_DIR|g" -e "s|@APP_NAME@|$APP_NAME|g" \
  "$SOURCE_DIR/eteelo-connect.desktop" > "$DESKTOP_FILE"

echo "✓ $APP_NAME installé dans $INSTALL_DIR (menu des applications)."
