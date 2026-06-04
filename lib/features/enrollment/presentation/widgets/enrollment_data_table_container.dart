import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_listing_view_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_grid_view.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_responsive_mode.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/results/enrollment_results_table_view.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_loading_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Adapte l'etat BLoC vers la config de [EnrollmentDataTable] ou [EnrollmentResultsGridView].
/// Gère le choix table/grid basé sur le layout et le mode vue préféré.
class EnrollmentDataTableContainer extends StatefulWidget {
  final ValueChanged<EnrollmentSummary> onViewRequested;
  final EnrollmentListingLayout? layout;
  final EnrollmentListingViewMode preferredViewMode;
  final DataTableDensity tableDensity;
  final VoidCallback? onSortToggled;
  final ValueChanged<EnrollmentListingViewMode>? onViewModeChanged;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onResetSearchRequested;
  final VoidCallback? onCreateEnrollmentRequested;
  final VoidCallback? onReconnectRequested;
  final VoidCallback? onContactAdminRequested;

  const EnrollmentDataTableContainer({
    super.key,
    required this.onViewRequested,
    this.layout,
    this.preferredViewMode = EnrollmentListingViewMode.auto,
    this.tableDensity = DataTableDensity.comfortable,
    this.onSortToggled,
    this.onViewModeChanged,
    this.onRefresh,
    this.onResetSearchRequested,
    this.onCreateEnrollmentRequested,
    this.onReconnectRequested,
    this.onContactAdminRequested,
  });

  @override
  State<EnrollmentDataTableContainer> createState() =>
      _EnrollmentDataTableContainerState();
}

class _EnrollmentDataTableContainerState
    extends State<EnrollmentDataTableContainer> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveViewMode = _resolveViewModeForWidth(
          constraints.maxWidth,
        );

        return BlocBuilder<EnrollmentBloc, EnrollmentState>(
          builder: (context, state) {
            final stateWidget = _buildStateWidget(
              context,
              state,
              effectiveViewMode,
            );
            if (stateWidget != null) {
              return AnimatedSwitcher(
                duration: AppMotion.layout,
                switchInCurve: AppMotion.outCurve,
                switchOutCurve: AppMotion.inCurve,
                child: stateWidget,
              );
            }

            final l10n = AppLocalizations.of(context)!;
            return AnimatedSwitcher(
              duration: AppMotion.layout,
              switchInCurve: AppMotion.outCurve,
              switchOutCurve: AppMotion.inCurve,
              child: effectiveViewMode.isGrid
                  ? _buildGridView(state)
                  : _buildTableView(state, l10n),
            );
          },
        );
      },
    );
  }

  EnrollmentListingViewMode _resolveViewModeForWidth(double width) {
    return EnrollmentResultsResponsiveMode.resolve(
      containerWidth: width,
      preferred: widget.preferredViewMode,
    );
  }

  Widget? _buildStateWidget(
    BuildContext context,
    EnrollmentState state,
    EnrollmentListingViewMode effectiveViewMode,
  ) {
    if (state.summariesStatus == EnrollmentLoadStatus.loading) {
      return EnrollmentResultsLoadingSkeleton(
        key: const ValueKey<String>('results-loading'),
        isGrid: effectiveViewMode.isGrid,
      );
    }

    if (state.summariesStatus == EnrollmentLoadStatus.failure) {
      return EnrollmentResultsErrorState(
        key: const ValueKey<String>('results-error'),
        type: state.summariesErrorType ?? EnrollmentErrorType.unknown,
        message: state.errorMessage,
        onRetry: _resolveRetryAction(context),
        onReconnect: widget.onReconnectRequested,
        onContactAdmin: widget.onContactAdminRequested,
      );
    }

    if (state.summariesStatus == EnrollmentLoadStatus.success &&
        state.summaries.isEmpty) {
      return EnrollmentResultsEmptyState(
        key: const ValueKey<String>('results-empty'),
        criteria: _buildCriteriaChips(context, state),
        onReset: widget.onResetSearchRequested ?? _resolveRetryAction(context),
        onCreateEnrollment: widget.onCreateEnrollmentRequested,
      );
    }

    return null;
  }

  Widget _buildTableView(EnrollmentState state, AppLocalizations l10n) {
    return EnrollmentResultsTableView(
      key: ValueKey('table-${state.summariesStatus}'),
      enrollments: state.summaries,
      totalCount: state.summariesTotalElements,
      isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
      isError: state.summariesStatus == EnrollmentLoadStatus.failure,
      loadingLabel: l10n.loadingStudents,
      errorLabel: state.errorMessage,
      emptyLabel: _buildEmptyLabel(state, l10n),
      showPagination: true,
      currentPage: state.summariesPage + 1,
      totalPages: state.summariesTotalPages,
      density: widget.tableDensity,
      onPreviousPage: () => context.read<EnrollmentBloc>().add(
        EnrollmentSummariesPageRequested(page: state.summariesPage - 1),
      ),
      onNextPage: () => context.read<EnrollmentBloc>().add(
        EnrollmentSummariesPageRequested(page: state.summariesPage + 1),
      ),
      pageLabelBuilder: (current, total) =>
          l10n.enrollmentPageIndicator(current, total),
      onViewRequested: widget.onViewRequested,
    );
  }

  Widget _buildGridView(EnrollmentState state) {
    return EnrollmentResultsGridView(
      key: ValueKey('grid-${state.summariesStatus}'),
      enrollments: state.summaries,
      onViewRequested: widget.onViewRequested,
    );
  }

  VoidCallback? _resolveRetryAction(BuildContext context) {
    if (widget.onRefresh != null) {
      return () => widget.onRefresh!.call();
    }

    return () => context.read<EnrollmentBloc>().add(
      const EnrollmentSummariesRefreshRequested(),
    );
  }

  List<String> _buildCriteriaChips(
    BuildContext context,
    EnrollmentState state,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final query = state.lastSummariesQuery;
    if (query == null) {
      return const <String>[];
    }

    final chips = <String>[];

    void addIfNotEmpty(String label, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        chips.add('$label: $trimmed');
      }
    }

    addIfNotEmpty(l10n.firstName, query.firstName);
    addIfNotEmpty(l10n.lastName, query.lastName);
    addIfNotEmpty(l10n.surname, query.surname);
    addIfNotEmpty(l10n.dateOfBirth, query.dateOfBirth);

    return chips;
  }

  String _buildEmptyLabel(EnrollmentState state, AppLocalizations l10n) {
    return switch (state.summariesStatus) {
      EnrollmentLoadStatus.initial => l10n.noResultsFound,
      EnrollmentLoadStatus.success => l10n.enrollmentNoResultsDescription,
      _ => l10n.enrollmentNoResultsDescription,
    };
  }
}
