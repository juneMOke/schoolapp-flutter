import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_organisation_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_split_results.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_invitation_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_student_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationResultsSection extends StatelessWidget {
  final bool isSplit;
  final ClassesOrganisationSearchRequest? lastRequest;
  final void Function(Object summary, String levelId) onViewRequested;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationResultsSection({
    super.key,
    required this.isSplit,
    required this.lastRequest,
    required this.onViewRequested,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    final request = lastRequest;
    if (request == null) {
      return const FacturationSearchInvitationCard();
    }

    if (!isSplit) {
      return FacturationStudentTable(onViewRequested: onViewRequested);
    }

    return BlocBuilder<ClassroomBloc, ClassroomState>(
      buildWhen: ClassesOrganisationPageHelpers.buildWhenClassroomResultsChange,
      builder: (context, classroomState) {
        final l10n = AppLocalizations.of(context)!;

        return ClassesOrganisationSplitResults(
          classrooms: classroomState.classrooms,
          membersByClassroom: classroomState.membersByClassroom,
          isLoading: classroomState.status == ClassroomStatus.loading ||
              classroomState.membersStatus == ClassroomStatus.loading,
          isReassigning: classroomState.reassignStatus == ClassroomStatus.loading,
          reassigningMemberId: classroomState.reassigningMemberId,
          isFailure: classroomState.status == ClassroomStatus.failure ||
              classroomState.membersStatus == ClassroomStatus.failure,
          errorMessage: ClassesOrganisationPageHelpers.mapClassroomErrorToMessage(
            l10n,
            classroomState.membersErrorType,
          ),
          onTransferTap: onTransferTap,
        );
      },
    );
  }
}
