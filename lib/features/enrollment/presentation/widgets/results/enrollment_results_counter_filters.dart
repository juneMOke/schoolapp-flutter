import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_bar_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentResultsCounterFilters extends StatelessWidget {
  final int count;
  final bool isLoading;
  final List<EnrollmentResultsActiveFilter> filters;

  const EnrollmentResultsCounterFilters({
    super.key,
    required this.count,
    required this.isLoading,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppDimensions.enrollmentResultsBarGap,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildCounterRow(l10n),
        ...filters.map((f) => _buildFilterChip(l10n, f)),
      ],
    );
  }

  Widget _buildCounterRow(AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.bleuArdoise.withValues(alpha: 0.12),
            borderRadius: AppRadius.brSm,
          ),
          child: const Icon(
            Icons.assignment_turned_in_outlined,
            size: 18,
            color: AppColors.bleuArdoise,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(
            isLoading
                ? l10n.loadingStudents
                : l10n.enrollmentResultsCount(count),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    AppLocalizations l10n,
    EnrollmentResultsActiveFilter filter,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.enrollmentResultsFilterChipHPadding,
        vertical: AppDimensions.enrollmentResultsFilterChipVPadding,
      ),
      decoration: BoxDecoration(
        color: filter.softColor,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filter.icon != null) ...[
            Icon(
              filter.icon,
              size: AppDimensions.enrollmentResultsFilterChipIconSize,
              color: filter.color,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            filter.label,
            style: AppTypography.labelSmall.copyWith(color: filter.color),
          ),
          if (filter.onRemove != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Semantics(
              button: true,
              label:
                  filter.removeSemanticLabel ??
                  l10n.removeFilterNamed(filter.label),
              child: InkWell(
                borderRadius: AppRadius.brPill,
                onTap: filter.onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: AppDimensions.enrollmentResultsFilterChipCloseIconSize,
                  color: filter.color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
