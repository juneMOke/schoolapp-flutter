import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_organisation_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListPageHelpers {
  const ClassesListPageHelpers._();

  static List<ClassesListCycleOption> buildCycleOptions(
    List<BootstrapSchoolLevelGroupBundle> bundles,
  ) {
    final cycles = <ClassesListCycleOption>[];

    final sortedBundles = [...bundles]
      ..sort(
        (a, b) =>
            a.schoolLevelGroup.displayOrder.compareTo(b.schoolLevelGroup.displayOrder),
      );

    for (final bundle in sortedBundles) {
      final levels = [...bundle.schoolLevels]
        ..sort(
          (a, b) =>
              a.schoolLevel.displayOrder.compareTo(b.schoolLevel.displayOrder),
        );

      cycles.add(
        ClassesListCycleOption(
          id: bundle.schoolLevelGroup.id,
          label: bundle.schoolLevelGroup.name,
          displayOrder: bundle.schoolLevelGroup.displayOrder,
          levels: levels
              .map(
                (levelBundle) => ClassesListLevelOption(
                  schoolLevelGroupId: bundle.schoolLevelGroup.id,
                  schoolLevelGroupName: bundle.schoolLevelGroup.name,
                  schoolLevelId: levelBundle.schoolLevel.id,
                  label: levelBundle.schoolLevel.name,
                  displayOrder: levelBundle.schoolLevel.displayOrder,
                  splitIntoClassrooms:
                      levelBundle.schoolLevel.splitIntoClassrooms,
                  classrooms: levelBundle.classrooms,
                ),
              )
              .toList(growable: false),
        ),
      );
    }

    return cycles;
  }

  static List<ClassroomMember> filterMembers(
    List<ClassroomMember> members,
    ClassesListSearchRequest request,
  ) {
    if (!request.hasNameFilters) {
      return members;
    }

    final firstName = request.firstName.trim().toLowerCase();
    final lastName = request.lastName.trim().toLowerCase();
    final surname = request.surname.trim().toLowerCase();

    return members.where((member) {
      final memberFirstName = member.studentFirstName.trim().toLowerCase();
      final memberLastName = member.studentLastName.trim().toLowerCase();
      final memberSurname = (member.studentMiddleName ?? '').trim().toLowerCase();

      return memberFirstName.contains(firstName) &&
          memberLastName.contains(lastName) &&
          memberSurname.contains(surname);
    }).toList(growable: false);
  }

  static String mapClassroomErrorToMessage(
    AppLocalizations l10n,
    ClassroomErrorType errorType,
  ) => ClassesOrganisationPageHelpers.mapClassroomErrorToMessage(l10n, errorType);

  static bool isSearching({
    required EnrollmentState enrollmentState,
    required ClassroomState classroomState,
    required ClassesListSearchRequest? lastRequest,
  }) {
    if (lastRequest == null) {
      return false;
    }

    if (lastRequest.targetsClassroom) {
      return classroomState.membersStatus == ClassroomStatus.loading;
    }

    return enrollmentState.summariesStatus == EnrollmentLoadStatus.loading;
  }

  static bool buildWhenBootstrapChanges(
    BootstrapContextState previous,
    BootstrapContextState current,
  ) {
    return previous.status != current.status ||
        previous.bootstrap != current.bootstrap;
  }

  static bool listenWhenEnrollmentStatusChanges(
    EnrollmentState previous,
    EnrollmentState current,
  ) {
    return previous.summariesStatus != current.summariesStatus ||
        previous.errorMessage != current.errorMessage;
  }

  static bool listenWhenClassroomMembersStatusChanges(
    ClassroomState previous,
    ClassroomState current,
  ) {
    return previous.membersStatus != current.membersStatus ||
        previous.membersErrorType != current.membersErrorType;
  }

  static bool buildWhenEnrollmentResultsChange(
    EnrollmentState previous,
    EnrollmentState current,
  ) {
    return previous.summariesStatus != current.summariesStatus ||
        previous.summaries != current.summaries ||
        previous.summariesPage != current.summariesPage ||
        previous.summariesTotalPages != current.summariesTotalPages ||
        previous.summariesQueryType != current.summariesQueryType ||
        previous.errorMessage != current.errorMessage;
  }

  static bool buildWhenClassroomMembersChange(
    ClassroomState previous,
    ClassroomState current,
  ) {
    return previous.membersStatus != current.membersStatus ||
        previous.members != current.members ||
        previous.membersErrorType != current.membersErrorType;
  }

  static String buildClassroomMemberDisplayName(ClassroomMember member) {
    return [
      member.studentLastName,
      member.studentMiddleName,
      member.studentFirstName,
    ].where((part) => (part ?? '').trim().isNotEmpty).join(' ');
  }
}
