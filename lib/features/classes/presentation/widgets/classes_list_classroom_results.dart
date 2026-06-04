import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_results_toolbar.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_students_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListClassroomResults extends StatelessWidget {
  final ClassesListSearchRequest request;
  final ClassroomState state;
  final VoidCallback onExportPressed;
  final ValueChanged<ClassroomMember> onViewRequested;

  const ClassesListClassroomResults({
    super.key,
    required this.request,
    required this.state,
    required this.onExportPressed,
    required this.onViewRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredMembers = ClassesListPageHelpers.filterMembers(
      state.members,
      request,
    );
    final byId = {for (final member in filteredMembers) member.id: member};
    final rows = filteredMembers
        .map(
          (member) => ClassesListStudentRow(
            id: member.id,
            studentId: member.studentId,
            lastName: member.studentLastName,
            surname: member.studentMiddleName ?? '',
            firstName: member.studentFirstName,
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
        ? l10n.classesListResultsSummaryWithoutCriteria(rows.length)
        : l10n.classesListResultsSummary(rows.length, criteria);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassesListResultsToolbar(
          summary: summary,
          canExport:
              state.membersStatus == ClassroomStatus.success && rows.isNotEmpty,
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
    Map<String, ClassroomMember> byId,
  ) {
    return ClassesListStudentsTable(
      key: ValueKey(state.membersStatus),
      rows: rows,
      isLoading: state.membersStatus == ClassroomStatus.loading,
      isError: state.membersStatus == ClassroomStatus.failure,
      loadingLabel: l10n.classesListLoadingClassroomMembers,
      errorLabel: ClassesListPageHelpers.mapClassroomErrorToMessage(
        l10n,
        state.membersErrorType,
      ),
      emptyLabel: l10n.classesListNoMatchMessage,
      onViewRequested: (row) {
        final member = byId[row.id];
        if (member != null) {
          onViewRequested(member);
        }
      },
    );
  }
}
