import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_bar_actions.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_bar_models.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_counter_filters.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_responsive_mode.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

export 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_bar_models.dart';

class EnrollmentResultsBar extends StatelessWidget {
  final int count;
  final bool isLoading;
  final String? statusLabel;
  final bool showStatusBadge;
  final List<EnrollmentResultsSortOption> sortOptions;
  final String? selectedSort;
  final ValueChanged<String>? onSortChanged;
  final List<EnrollmentResultsActiveFilter> activeFilters;
  final ValueChanged<EnrollmentListingViewMode>? onViewModeChanged;
  final EnrollmentListingViewMode currentViewMode;
  final Future<void> Function()? onRefresh;

  const EnrollmentResultsBar({
    super.key,
    required this.count,
    required this.isLoading,
    this.statusLabel,
    this.showStatusBadge = false,
    this.sortOptions = const [],
    this.selectedSort,
    this.onSortChanged,
    this.activeFilters = const [],
    this.onViewModeChanged,
    this.currentViewMode = EnrollmentListingViewMode.auto,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = _effectiveFilters(l10n);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        boxShadow: AppElevation.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Eyebrow label
          Text(
            l10n.enrollmentResults.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.terreCuite,
              letterSpacing: 1.32,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final left = _buildCounterAndFilters(l10n, filters);
              final right = _buildActions(l10n);
              final canStayOnSingleLine =
                  constraints.maxWidth >= 760 &&
                  (filters.length <= 2 || !_hasStructuredSort);

              if (canStayOnSingleLine) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: left),
                    const SizedBox(
                      width: AppDimensions.enrollmentResultsBarGap,
                    ),
                    right,
                  ],
                );
              }

              return Wrap(
                spacing: AppDimensions.enrollmentResultsBarGap,
                runSpacing: AppDimensions.enrollmentResultsBarGap,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  left,
                  SizedBox(
                    width: constraints.maxWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: right,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  bool get _hasStructuredSort =>
      sortOptions.isNotEmpty && selectedSort != null && onSortChanged != null;

  List<EnrollmentResultsActiveFilter> _effectiveFilters(AppLocalizations l10n) {
    if (activeFilters.isNotEmpty) {
      return activeFilters;
    }
    if (showStatusBadge && statusLabel != null) {
      final normalizedStatus = statusLabel!.trim().toUpperCase();
      final isCompleted = normalizedStatus == 'COMPLETED';
      final statusText = isCompleted
          ? l10n.enrollmentStatusCompleted
          : l10n.enrollmentStatusInProgress;
      return [
        EnrollmentResultsActiveFilter(
          id: 'status',
          label: '${l10n.enrollmentStatusFilterLabel}: $statusText',
          icon: isCompleted
              ? Icons.check_circle_rounded
              : Icons.hourglass_top_rounded,
          softColor: isCompleted
              ? AppColors.enrollmentStatsFirstSoft
              : AppColors.enrollmentStatsInProgressSoft,
          color: isCompleted
              ? AppColors.enrollmentStatsFirst
              : AppColors.textSecondary,
        ),
      ];
    }
    return const [];
  }

  Widget _buildCounterAndFilters(
    AppLocalizations l10n,
    List<EnrollmentResultsActiveFilter> filters,
  ) => EnrollmentResultsCounterFilters(
    count: count,
    isLoading: isLoading,
    filters: filters,
  );

  Widget _buildActions(AppLocalizations l10n) {
    // Le basculeur reflète le mode RÉELLEMENT rendu : en `auto` (défaut) on rend
    // la table → le basculeur surligne « Liste », y compris sur mobile.
    final effectiveMode = EnrollmentResultsResponsiveMode.resolve(
      preferred: currentViewMode,
    );
    return EnrollmentResultsBarActions(
      isLoading: isLoading,
      sortOptions: sortOptions,
      selectedSort: selectedSort,
      onSortChanged: onSortChanged,
      onViewModeChanged: onViewModeChanged,
      currentViewMode: effectiveMode,
      onRefresh: onRefresh,
    );
  }
}
