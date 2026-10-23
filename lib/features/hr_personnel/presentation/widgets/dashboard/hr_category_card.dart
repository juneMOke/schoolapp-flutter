import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_stats.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_personnel_labels.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Par catégorie » : une barre par catégorie non vide, à l'échelle de la
/// plus forte. Une ligne touchée devient le filtre de « Qui sont-ils » ; la
/// même, touchée de nouveau, le retire.
///
/// Des lignes propres plutôt que `EteeloBarRows` : celles-ci sont un filtre,
/// elles doivent tenir la cible de 44 dp et montrer laquelle est active.
class HrCategoryCard extends StatelessWidget {
  final HrStaffStats stats;

  /// Le filtre que porte la liste, ou `null`.
  final HrCategoryKey? active;
  final ValueChanged<HrCategoryKey> onTap;

  const HrCategoryCard({
    super.key,
    required this.stats,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final max = stats.categories.fold<int>(
      0,
      (best, category) => category.count > best ? category.count : best,
    );
    return EteeloStatsCard(
      title: l10n.hrByCategoryTitle,
      hint: l10n.hrByCategoryHint,
      icon: Icons.category_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final category in stats.categories)
            _CategoryRow(
              category: category,
              scale: max,
              selected: category.key == active,
              onTap: () => onTap(category.key),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final HrCategoryCount category;
  final int scale;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.category,
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = HrPersonnelLabels.category(l10n, category.key);
    final value = l10n.hrAgentsCount(category.count);
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.hrJoin(label, value),
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.hrCategoryRowActive : Colors.transparent,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: AppDimensions.hrBarLabelWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (selected)
                          Text(
                            l10n.hrFilterActive,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.bleuArdoise,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: HrBar(
                      segments: [
                        HrBarSegment(
                          count: category.count,
                          color: HrPersonnelLabels.categoryColor(category.key),
                        ),
                      ],
                      scale: scale,
                      height: AppDimensions.hrCategoryBarHeight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    value,
                    textAlign: TextAlign.right,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
