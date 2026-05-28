#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.githooks"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

if [[ ! -f "$PRE_COMMIT_HOOK" ]]; then
  echo "[install-hooks] Hook introuvable: $PRE_COMMIT_HOOK"
  exit 1
fi

chmod +x "$PRE_COMMIT_HOOK"
git -C "$REPO_ROOT" config core.hooksPath .githooks

echo "[install-hooks] Hooks Git actifs via .githooks"
echo "[install-hooks] pre-commit: $PRE_COMMIT_HOOK"
