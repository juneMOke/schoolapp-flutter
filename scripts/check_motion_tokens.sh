#!/usr/bin/env bash
# check_motion_tokens.sh
#
# Garde-fou Motion : vérifie l'absence de Duration(...) hardcodées
# dans les répertoires UI scopés (Home, Enrollment, Finance).
#
# La source autorisée est lib/core/theme/app_motion.dart.
# finance_motion.dart est également exclu car il délègue vers AppMotion.
#
# Usage : bash scripts/check_motion_tokens.sh
# Retour : 0 si OK, 1 si violations détectées.

set -euo pipefail

SCOPES=(
  "lib/features/home/presentation"
  "lib/features/enrollment/presentation"
  "lib/features/finance/presentation"
)

EXCLUDE_FILES=(
  "lib/core/theme/app_motion.dart"
  "lib/features/finance/presentation/widgets/common/finance_motion.dart"
)

PATTERN="Duration\("

violations=()

for scope in "${SCOPES[@]}"; do
  if [ ! -d "$scope" ]; then
    continue
  fi

  while IFS= read -r -d '' file; do
    # Sauter les fichiers exclus
    skip=false
    for excluded in "${EXCLUDE_FILES[@]}"; do
      if [[ "$file" == *"$excluded"* ]]; then
        skip=true
        break
      fi
    done
    $skip && continue

    # Chercher le pattern dans le fichier
    if grep -qP "$PATTERN" "$file" 2>/dev/null; then
      matches=$(grep -nP "$PATTERN" "$file")
      while IFS= read -r line; do
        violations+=("$file: $line")
      done <<< "$matches"
    fi
  done < <(find "$scope" -name "*.dart" -print0)
done

if [ ${#violations[@]} -eq 0 ]; then
  echo "✅  Motion check passed — aucune Duration() hardcodée dans le scope UI."
  exit 0
fi

echo ""
echo "❌  Motion check FAILED — Duration() hardcodées détectées dans le scope UI :"
echo "    Utiliser les tokens AppMotion (lib/core/theme/app_motion.dart)."
echo ""
for v in "${violations[@]}"; do
  echo "  ⚠  $v"
done
echo ""
echo "  Tokens disponibles : micro fast medium standard entrance layout"
echo "                       actionCooldown refreshCooldown tooltipShowDuration"
echo ""
exit 1
