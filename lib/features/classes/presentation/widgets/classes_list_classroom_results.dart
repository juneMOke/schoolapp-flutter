import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_results_toolbar.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_state_card.dart';
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
    final filteredMembers = ClassesListPageHelpers.filterMembers(state.members, request);
    final byId = {for (final member in filteredMembers) member.id: member};
    final rows = filteredMembers
        .map(
          (member) => ClassesListStudentRow(
            id: member.id,
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
          canExport: state.membersStatus == ClassroomStatus.success && rows.isNotEmpty,
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
    if (state.membersStatus == ClassroomStatus.loading) {
      return ClassesListStateCard(
        key: const ValueKey('classes-list-classroom-loading'),
        icon: Icons.hourglass_top_rounded,
        title: l10n.classesListLoadingClassroomMembers,
        message: l10n.classesListLoadingClassroomMembers,
      );
    }

    if (state.membersStatus == ClassroomStatus.failure) {
      return ClassesListStateCard(
        key: const ValueKey('classes-list-classroom-error'),
        icon: Icons.error_outline_rounded,
        title: l10n.classesOrganisationErrorUnknown,
        message: ClassesListPageHelpers.mapClassroomErrorToMessage(
          l10n,
          state.membersErrorType,
        ),
      );
    }

    if (rows.isEmpty) {
      return ClassesListStateCard(
        key: const ValueKey('classes-list-classroom-empty'),
        icon: Icons.groups_outlined,
        title: l10n.classesListNoMatchTitle,
        message: l10n.classesListNoMatchMessage,
      );
    }

    return ClassesListStudentsTable(
      key: const ValueKey('classes-list-classroom-table'),
      rows: rows,
      onViewRequested: (row) {
        final member = byId[row.id];
        if (member != null) {
          onViewRequested(member);
        }
      },
    );
  }
}
