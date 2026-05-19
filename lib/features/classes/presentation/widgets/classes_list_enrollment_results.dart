import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_results_toolbar.dart';
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
    final byId = {
      for (final summary in state.summaries) summary.student.id: summary,
    };
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
          canExport:
              state.summariesStatus == EnrollmentLoadStatus.success &&
              rows.isNotEmpty,
          onExportPressed: onExportPressed,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: _buildBody(l10n, rows, byId),
        ),
      ],
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    List<ClassesListStudentRow> rows,
    Map<String, EnrollmentSummary> byId,
  ) {
    return ClassesListStudentsTable(
      key: ValueKey(state.summariesStatus),
      rows: rows,
      isLoading: state.summariesStatus == EnrollmentLoadStatus.loading,
      isError: state.summariesStatus == EnrollmentLoadStatus.failure,
      loadingLabel: l10n.loadingStudents,
      errorLabel: state.errorMessage ?? l10n.classesOrganisationErrorUnknown,
      emptyLabel: state.summariesStatus == EnrollmentLoadStatus.initial
          ? l10n.classesListInitialEmptyMessage
          : l10n.classesListNoMatchMessage,
      onViewRequested: (row) {
        final summary = byId[row.id];
        if (summary != null) {
          onViewRequested(summary);
        }
      },
    );
  }
}
