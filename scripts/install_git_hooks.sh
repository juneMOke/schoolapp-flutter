#!/usr/bin/env bash
# scripts/install_git_hooks.sh
#
# Active les hooks Git locaux stockes dans .githooks/.
# A executer une seule fois apres avoir clone le depot :
#
#   bash scripts/install_git_hooks.sh
#
# Hooks installes :
#   pre-commit  — format Dart + motion tokens check (rapide)
#   pre-push    — flutter analyze + flutter test (lourd)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.githooks"

HOOKS=("pre-commit" "pre-push")
ERRORS=0

for hook in "${HOOKS[@]}"; do
  hook_path="$HOOKS_DIR/$hook"
  if [[ ! -f "$hook_path" ]]; then
    echo "[install-hooks] Hook introuvable : $hook_path"
    ERRORS=$((ERRORS + 1))
  else
    chmod +x "$hook_path"
    echo "[install-hooks] OK $hook active"
  fi
done

if [[ $ERRORS -gt 0 ]]; then
  echo "[install-hooks] FAILED $ERRORS hook(s) manquant(s) dans $HOOKS_DIR"
  exit 1
fi

git -C "$REPO_ROOT" config core.hooksPath .githooks

echo ""
echo "[install-hooks] Hooks Git actifs via .githooks/"
echo "[install-hooks]   pre-commit : format Dart + motion tokens check"
echo "[install-hooks]   pre-push   : flutter analyze + flutter test"
echo ""
echo "  Pour desactiver temporairement :"
echo "    git commit --no-verify"
echo "    git push --no-verify"
