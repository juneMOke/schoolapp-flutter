import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Adapte l'etat BLoC vers la config de [EnrollmentDataTable].
class EnrollmentDataTableContainer extends StatelessWidget {
  final ValueChanged<EnrollmentSummary> onViewRequested;

  const EnrollmentDataTableContainer({
    super.key,
    required this.onViewRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: EnrollmentDataTable(
            key: ValueKey(state.summariesStatus),
            enrollments: state.summaries,
            totalCount: state.summariesTotalElements,
            isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
            isError: state.summariesStatus == EnrollmentLoadStatus.failure,
            loadingLabel: l10n.loadingStudents,
            errorLabel: state.errorMessage,
            emptyLabel: _buildEmptyLabel(state, l10n),
            showPagination: true,
            currentPage: state.summariesPage,
            totalPages: state.summariesTotalPages,
            onPreviousPage: () => context.read<EnrollmentBloc>().add(
              EnrollmentSummariesPageRequested(page: state.summariesPage - 1),
            ),
            onNextPage: () => context.read<EnrollmentBloc>().add(
              EnrollmentSummariesPageRequested(page: state.summariesPage + 1),
            ),
            pageLabelBuilder: (current, total) =>
                l10n.enrollmentPageIndicator(current, total),
            onViewRequested: onViewRequested,
          ),
        );
      },
    );
  }

  String _buildEmptyLabel(EnrollmentState state, AppLocalizations l10n) {
    return switch (state.summariesStatus) {
      EnrollmentLoadStatus.initial => l10n.noResultsFound,
      EnrollmentLoadStatus.success => l10n.enrollmentNoResultsDescription,
      _ => l10n.enrollmentNoResultsDescription,
    };
  }
}
