import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_bar_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentResultsBarActions extends StatelessWidget {
  final bool isLoading;
  final List<EnrollmentResultsSortOption> sortOptions;
  final String? selectedSort;
  final ValueChanged<String>? onSortChanged;
  final ValueChanged<EnrollmentListingViewMode>? onViewModeChanged;
  final EnrollmentListingViewMode currentViewMode;
  final Future<void> Function()? onRefresh;

  const EnrollmentResultsBarActions({
    super.key,
    required this.isLoading,
    required this.sortOptions,
    required this.selectedSort,
    required this.onSortChanged,
    required this.onViewModeChanged,
    required this.currentViewMode,
    required this.onRefresh,
  });

  bool get _hasStructuredSort =>
      sortOptions.isNotEmpty && selectedSort != null && onSortChanged != null;

  EnrollmentListingViewMode get _segmentedSelectedMode => currentViewMode.isGrid
      ? EnrollmentListingViewMode.grid
      : EnrollmentListingViewMode.table;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: AppDimensions.enrollmentResultsBarGap,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_hasStructuredSort)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.sort,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: AppDimensions.enrollmentResultsSortSelectWidth,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedSort,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surfaceAlt,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.brSm,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: sortOptions
                      .map(
                        (opt) => DropdownMenuItem<String>(
                          value: opt.value,
                          child: Text(
                            opt.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          if (value != null) {
                            onSortChanged?.call(value);
                          }
                        },
                ),
              ),
            ],
          ),
        if (onViewModeChanged != null)
          SizedBox(
            height: AppDimensions.enrollmentResultsViewToggleHeight,
            child: SegmentedTabFilter<EnrollmentListingViewMode>(
              semanticsLabel: l10n.sort,
              style: const SegmentedTabFilterStyle(
                backgroundColor: AppColors.surfaceAlt,
                borderColor: AppColors.border,
                borderRadius: 10,
                containerPadding: EdgeInsets.all(3),
                itemWidth: 38,
                itemHeight: AppDimensions.enrollmentResultsViewToggleItemHeight,
                itemBorderRadius: 7,
                selectedBackgroundColor: Colors.white,
                selectedForegroundColor: AppColors.bleuArdoise,
                unselectedForegroundColor: AppColors.textSecondary,
                selectedShadow: AppElevation.shadowKpi,
              ),
              options: [
                SegmentedTabOption(
                  label: '',
                  semanticLabel: l10n.enrollmentViewTable,
                  icon: Icons.reorder_rounded,
                  value: EnrollmentListingViewMode.table,
                ),
                SegmentedTabOption(
                  label: '',
                  semanticLabel: l10n.enrollmentViewGrid,
                  icon: Icons.grid_view_rounded,
                  value: EnrollmentListingViewMode.grid,
                ),
              ],
              selected: _segmentedSelectedMode,
              onSelected: (mode) {
                if (!isLoading) {
                  onViewModeChanged?.call(mode);
                }
              },
            ),
          ),
        if (onRefresh != null)
          Tooltip(
            message: l10n.refresh,
            child: IconButton(
              onPressed: isLoading ? null : onRefresh,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              color: AppColors.bleuArdoise,
            ),
          ),
      ],
    );
  }
}
