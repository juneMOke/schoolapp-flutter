import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/layout/leading_trailing_row.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_personnel_labels.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Parité » : femmes et hommes sur tout le personnel, puis par catégorie non
/// vide. Lecture seule.
///
/// Un sexe non renseigné a son propre segment, gris, au bout de la barre : le
/// ranger d'office d'un côté fausserait la parité.
class HrParityCard extends StatelessWidget {
  final HrStaffStats stats;

  const HrParityCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final anyUnknown = stats.sexes.unknown > 0;
    return EteeloStatsCard(
      title: l10n.hrParityTitle,
      hint: l10n.hrParityHint,
      icon: Icons.wc_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ParityLine(
            label: l10n.hrParityAll,
            split: stats.sexes,
            barHeight: AppDimensions.hrParityAllBarHeight,
            labelStyle: AppTypography.titleSmall,
          ),
          for (final category in stats.categories) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),
            _ParityLine(
              label: HrPersonnelLabels.category(l10n, category.key),
              split: category.split,
              barHeight: AppDimensions.hrParityBarHeight,
              labelStyle: AppTypography.labelLarge,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              _Legend(
                color: AppColors.hrParityWomen,
                label: l10n.hrParityWomen,
              ),
              _Legend(color: AppColors.hrParityMen, label: l10n.hrParityMen),
              if (anyUnknown)
                _Legend(
                  color: AppColors.hrParityUnknown,
                  label: l10n.hrParityUnknown,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParityLine extends StatelessWidget {
  final String label;
  final HrSexSplit split;
  final double barHeight;
  final TextStyle labelStyle;

  const _ParityLine({
    required this.label,
    required this.split,
    required this.barHeight,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final counts = split.unknown == 0
        ? l10n.hrParityCounts(split.women, split.men)
        : l10n.hrParityCountsUnknown(split.women, split.men, split.unknown);
    return Semantics(
      container: true,
      label: l10n.hrJoin(label, counts),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Les comptes ne s'abrègent jamais : bornés aux deux tiers de la
          // ligne, ils passent à la ligne (téléphone, texte ×1,3).
          LeadingTrailingRow(
            gap: AppSpacing.sm,
            maxTrailingShare: 2 / 3,
            crossAxisAlignment: CrossAxisAlignment.start,
            leading: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle.copyWith(color: AppColors.textPrimary),
            ),
            trailing: Text(
              counts,
              textAlign: TextAlign.right,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          HrBar(
            scale: split.total,
            height: barHeight,
            segments: [
              HrBarSegment(count: split.women, color: AppColors.hrParityWomen),
              HrBarSegment(count: split.men, color: AppColors.hrParityMen),
              HrBarSegment(
                count: split.unknown,
                color: AppColors.hrParityUnknown,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: AppDimensions.hrLegendSwatchSize,
        height: AppDimensions.hrLegendSwatchSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(
            AppDimensions.hrLegendSwatchRadius,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.xs),
      Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );
}
