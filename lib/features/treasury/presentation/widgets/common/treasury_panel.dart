import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';

/// Un panneau blanc de la trésorerie (A3, A5) : rayon 16, pad 20, ombre
/// douce.
class TreasuryPanel extends StatelessWidget {
  final Widget child;

  const TreasuryPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppDimensions.treasuryPanelPadding),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppDimensions.treasuryPanelRadius),
      border: Border.all(color: AppColors.border),
      boxShadow: TreasuryTones.cardShadow,
    ),
    child: child,
  );
}

/// L'en-tête d'une section : l'icône dans sa boîte, le titre, le
/// sous-titre, puis un filet.
class TreasurySectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const TreasurySectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            width: AppDimensions.treasuryIconBox,
            height: AppDimensions.treasuryIconBox,
            decoration: BoxDecoration(
              color: AppColors.treasuryUsdSoft,
              border: Border.all(color: AppColors.treasuryUsdBorder),
              borderRadius: BorderRadius.circular(
                AppDimensions.treasuryIconBoxRadius,
              ),
            ),
            child: Icon(
              icon,
              size: AppSpacing.lg + 2,
              color: AppColors.bleuProfond,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.bleuProfond,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
      const Divider(height: 1, color: AppColors.border),
      const SizedBox(height: AppSpacing.md),
    ],
  );
}

/// Le bandeau de période (A3) : fond note, icône terre cuite, le texte, et
/// une aide facultative à droite.
class TreasuryNoteBand extends StatelessWidget {
  final IconData icon;
  final InlineSpan text;
  final String? hint;

  const TreasuryNoteBand({
    super.key,
    required this.icon,
    required this.text,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.treasuryNoteBg,
        border: Border.all(color: AppColors.treasuryNoteBorder),
        borderRadius: BorderRadius.circular(
          AppDimensions.treasuryIconBoxRadius,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSpacing.lg - 1, color: AppColors.terreCuite),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text.rich(
                  text,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.treasuryNoteText,
                  ),
                ),
              ),
            ],
          ),
          if (hint != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: AppSpacing.md + 1,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    hint,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Le titre des écrans de la trésorerie (spec A1) : Lora 32, bleu profond ;
/// 26 sur téléphone.
abstract final class TreasuryTitle {
  static TextStyle style(BuildContext context) =>
      AppTypography.displayMedium.copyWith(
        color: AppColors.bleuProfond,
        fontSize:
            MediaQuery.sizeOf(context).width < AppBreakpoints.phoneNarrowMax
            ? AppDimensions.treasuryKpiAmountSizeCompact
            : null,
      );
}
