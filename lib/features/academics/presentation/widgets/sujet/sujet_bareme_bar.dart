import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_bareme.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/sujet_visuals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Barre du barème, en direct sur le brouillon (spec S4) : « Barème Σ / max
/// pts », message, questions à compléter, progression — et « Ajuster le
/// maximum » tant qu'aucune note n'est posée. Jamais bloquante.
class SujetBaremeBar extends StatelessWidget {
  final SujetBareme bareme;
  final int incompleteCount;

  /// Une note est posée : le maximum est figé, il ne s'ajuste plus.
  final bool maxLocked;
  final VoidCallback onAdjustMax;

  const SujetBaremeBar({
    super.key,
    required this.bareme,
    required this.incompleteCount,
    required this.maxLocked,
    required this.onAdjustMax,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = bareme.status;
    final visual = baremeVisual(status);
    final adjustable =
        status == BaremeStatus.under || status == BaremeStatus.over;
    final message = [
      baremeMessage(l10n, bareme),
      if (incompleteCount > 0) l10n.sujetIncompleteCount(incompleteCount),
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: visual.soft,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: visual.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.sujetBaremeValue(
                  formatPoints(bareme.total),
                  formatPoints(bareme.maxPoints),
                ),
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    visual.icon,
                    size: AppDimensions.sujetIconSize,
                    color: visual.color,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      message,
                      style: AppTypography.bodySmall.copyWith(
                        color: visual.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (adjustable && maxLocked)
                Text(
                  l10n.sujetBaremeLocked,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                )
              else if (adjustable)
                TextButton(
                  onPressed: onAdjustMax,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.bleuArdoise,
                  ),
                  child: Text(
                    l10n.sujetBaremeAdjust(formatPoints(bareme.total)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: status == BaremeStatus.over ? 1 : bareme.fraction,
              minHeight: AppDimensions.sujetBaremeBar,
              color: visual.color,
              backgroundColor: AppColors.surfaceRaised,
            ),
          ),
        ],
      ),
    );
  }
}
