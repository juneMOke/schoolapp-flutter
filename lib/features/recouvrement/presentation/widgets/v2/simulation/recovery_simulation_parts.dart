import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/simulation/recovery_verdict.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Avant / après (`RecAvantApres`) : la part conservée de l'effectif, dans la
/// couleur du verdict, sur un fond rouge pâle — ce qui part.
class RecoveryKeptBar extends StatelessWidget {
  final int percent;
  final RecoveryVerdict? verdict;
  final double height;

  const RecoveryKeptBar({
    super.key,
    required this.percent,
    required this.verdict,
    this.height = AppDimensions.recoverySimKeptBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final color = verdict?.color ?? AppColors.textMuted;
    final l10n = AppLocalizations.of(context)!;
    final radius = BorderRadius.circular(
      AppDimensions.recoverySimKeptBarRadius,
    );
    return Row(
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppDimensions.recoverySimKeptBarMinWidth,
            ),
            child: Container(
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.feeStatusDueSoft,
                borderRadius: radius,
                border: Border.all(color: AppColors.border),
              ),
              child: FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: (percent / 100).clamp(0.0, 1.0),
                child: ColoredBox(color: color),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.recoverySimKeptPercentMinWidth,
          ),
          child: Text(
            l10n.recoverySimulationPercent(percent),
            textAlign: TextAlign.end,
            style: AppTypography.labelLarge.copyWith(
              color: verdict?.ink ?? AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// La pastille du verdict : icône et mot, jamais la couleur seule.
class RecoveryVerdictPill extends StatelessWidget {
  final RecoveryVerdict verdict;

  const RecoveryVerdictPill({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: verdict.soft,
      borderRadius: AppRadius.brPill,
      border: Border.all(color: verdict.color.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          verdict.icon,
          size: AppDimensions.recoverySimChipIcon,
          color: verdict.ink,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: EteeloOverflowText(
            verdict.label(AppLocalizations.of(context)!),
            style: AppTypography.labelSmall.copyWith(color: verdict.ink),
          ),
        ),
      ],
    ),
  );
}

/// L'œil (`RecEye`) : décoratif, la ligne ou la carte entière est la cible.
class RecoverySimulationEye extends StatelessWidget {
  const RecoverySimulationEye({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: AppDimensions.recoverySimEyeSize,
      height: AppDimensions.recoverySimEyeSize,
      decoration: BoxDecoration(
        color: AppColors.bleuArdoiseSoft,
        borderRadius: BorderRadius.circular(AppDimensions.recoverySimEyeRadius),
      ),
      child: const Icon(
        Icons.visibility_outlined,
        size: AppDimensions.recoverySimEyeIcon,
        color: AppColors.bleuArdoise,
      ),
    ),
  );
}
