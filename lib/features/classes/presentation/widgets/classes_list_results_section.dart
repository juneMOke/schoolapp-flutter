import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_classroom_results.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_enrollment_results.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_state_card.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListResultsSection extends StatelessWidget {
  final ClassesListSearchRequest? lastRequest;
  final VoidCallback onExportPressed;
  final ValueChanged<EnrollmentSummary> onEnrollmentViewRequested;
  final ValueChanged<ClassroomMember> onClassroomMemberViewRequested;

  const ClassesListResultsSection({
    super.key,
    required this.lastRequest,
    required this.onExportPressed,
    required this.onEnrollmentViewRequested,
    required this.onClassroomMemberViewRequested,
  });

  @override
  Widget build(BuildContext context) {
    final request = lastRequest;
    final l10n = AppLocalizations.of(context)!;

    if (request == null) {
      return ClassesListStateCard(
        icon: Icons.search_rounded,
        title: l10n.classesListInitialEmptyTitle,
        message: l10n.classesListInitialEmptyMessage,
      );
    }

    if (request.targetsClassroom) {
      return BlocBuilder<ClassroomBloc, ClassroomState>(
        buildWhen: ClassesListPageHelpers.buildWhenClassroomMembersChange,
        builder: (context, state) => ClassesListClassroomResults(
          request: request,
          state: state,
          onExportPressed: onExportPressed,
          onViewRequested: onClassroomMemberViewRequested,
        ),
      );
    }

    return BlocBuilder<EnrollmentBloc, EnrollmentState>(
      buildWhen: ClassesListPageHelpers.buildWhenEnrollmentResultsChange,
      builder: (context, state) => ClassesListEnrollmentResults(
        request: request,
        state: state,
        onExportPressed: onExportPressed,
        onViewRequested: onEnrollmentViewRequested,
      ),
    );
  }
}
