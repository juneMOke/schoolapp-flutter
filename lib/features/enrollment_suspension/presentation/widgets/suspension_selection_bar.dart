import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La barre sombre du mode sélection, au-dessus des résultats : le compte, le
/// rappel d'éligibilité, « Tout sélectionner (page) », « Annuler » et
/// « Désactiver (N) ».
class SuspensionSelectionBar extends StatelessWidget {
  final int selectedCount;

  /// `null` quand la page n'a aucun élève éligible : le bouton disparaît.
  final VoidCallback? onTogglePage;
  final bool pageFullySelected;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const SuspensionSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onTogglePage,
    required this.pageFullySelected,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onDark = AppTypography.labelMedium.copyWith(
      color: AppColors.textOnDark,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm + 2,
        AppSpacing.md,
        AppSpacing.sm + 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bleuProfond,
        borderRadius: AppRadius.brMd,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.suspensionSelectionCount(selectedCount),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textOnDark,
                  ),
                ),
                Text(
                  l10n.suspensionSelectionHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onTogglePage != null)
                TextButton(
                  onPressed: onTogglePage,
                  child: Text(
                    pageFullySelected
                        ? l10n.suspensionUnselectAllPage
                        : l10n.suspensionSelectAllPage,
                    style: onDark,
                  ),
                ),
              TextButton(
                onPressed: onCancel,
                child: Text(l10n.suspensionCancel, style: onDark),
              ),
              FilledButton.icon(
                onPressed: selectedCount == 0 ? null : onConfirm,
                icon: const Icon(
                  Icons.person_remove_outlined,
                  size: AppDimensions.suspensionIconSize,
                ),
                label: Text(l10n.suspensionConfirmSelection(selectedCount)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orDoux,
                  foregroundColor: AppColors.bleuProfond,
                  minimumSize: const Size(0, 36),
                  textStyle: AppTypography.labelMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
