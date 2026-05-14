import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_pagination_bar.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_results_toolbar.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_state_card.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_students_table.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListEnrollmentResults extends StatelessWidget {
  final ClassesListSearchRequest request;
  final EnrollmentState state;
  final VoidCallback onExportPressed;
  final ValueChanged<EnrollmentSummary> onViewRequested;

  const ClassesListEnrollmentResults({
    super.key,
    required this.request,
    required this.state,
    required this.onExportPressed,
    required this.onViewRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byId = {for (final summary in state.summaries) summary.student.id: summary};
    final rows = state.summaries
        .map(
          (summary) => ClassesListStudentRow(
            id: summary.student.id,
            lastName: summary.student.lastName,
            surname: summary.student.surname,
            firstName: summary.student.firstName,
            classroomLabel: request.selectedClassroom?.name ?? '',
          ),
        )
        .toList(growable: false);

    final criteria = [
      request.selectedCycle?.label,
      request.selectedLevel?.label,
      request.selectedClassroom?.name,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');

    final summary = criteria.isEmpty
        ? l10n.classesListResultsSummaryWithoutCriteria(state.summaries.length)
        : l10n.classesListResultsSummary(state.summaries.length, criteria);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassesListResultsToolbar(
          summary: summary,
          canExport: state.summariesStatus == EnrollmentLoadStatus.success && rows.isNotEmpty,
          onExportPressed: onExportPressed,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: _buildBody(context, l10n, rows, byId),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    List<ClassesListStudentRow> rows,
    Map<String, EnrollmentSummary> byId,
  ) {
    switch (state.summariesStatus) {
      case EnrollmentLoadStatus.loading:
        return ClassesListStateCard(
          key: const ValueKey('classes-list-enrollment-loading'),
          icon: Icons.hourglass_top_rounded,
          title: l10n.loadingStudents,
          message: l10n.loadingStudents,
        );
      case EnrollmentLoadStatus.failure:
        return ClassesListStateCard(
          key: const ValueKey('classes-list-enrollment-error'),
          icon: Icons.error_outline_rounded,
          title: l10n.classesOrganisationErrorUnknown,
          message: state.errorMessage ?? l10n.classesOrganisationErrorUnknown,
        );
      case EnrollmentLoadStatus.success:
        if (rows.isEmpty) {
          return ClassesListStateCard(
            key: const ValueKey('classes-list-enrollment-empty'),
            icon: Icons.people_outline_rounded,
              title: l10n.classesListNoMatchTitle,
              message: l10n.classesListNoMatchMessage,
          );
        }

        return Column(
          key: const ValueKey('classes-list-enrollment-table'),
          children: [
            ClassesListStudentsTable(
              rows: rows,
              onViewRequested: (row) {
                final summary = byId[row.id];
                if (summary != null) {
                  onViewRequested(summary);
                }
              },
            ),
            if (state.summariesTotalPages > 1) ...[
              const SizedBox(height: AppDimensions.spacingS),
              ClassesListPaginationBar(
                currentPage: state.summariesPage,
                totalPages: state.summariesTotalPages,
                isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
                onPrevious: () => context.read<EnrollmentBloc>().add(
                  EnrollmentSummariesPageRequested(page: state.summariesPage - 1),
                ),
                onNext: () => context.read<EnrollmentBloc>().add(
                  EnrollmentSummariesPageRequested(page: state.summariesPage + 1),
                ),
              ),
            ],
          ],
        );
      case EnrollmentLoadStatus.initial:
        return ClassesListStateCard(
          key: const ValueKey('classes-list-enrollment-initial'),
          icon: Icons.search_rounded,
          title: l10n.classesListInitialEmptyTitle,
          message: l10n.classesListInitialEmptyMessage,
        );
    }
  }
}
