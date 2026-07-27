import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_organisation_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListPageHelpers {
  const ClassesListPageHelpers._();

  /// [classrooms] : toutes les classes de l'année (lecture locale
  /// `ClassroomOfflineBloc`), regroupées ici par niveau.
  static List<ClassesListCycleOption> buildCycleOptions(
    List<SchoolLevelGroupBundle> bundles,
    List<OfflineClassroom> classrooms,
  ) {
    final classroomsByLevel = <String, List<OfflineClassroom>>{};
    for (final classroom in classrooms) {
      final levelId = classroom.schoolLevelId;
      if (levelId == null) continue;
      (classroomsByLevel[levelId] ??= []).add(classroom);
    }

    return SortedNestedOptionsHelper.build(
      outers: bundles,
      outerOrder: (bundle) => bundle.group.displayOrder,
      inners: (bundle) => bundle.levels,
      innerOrder: (level) => level.displayOrder,
      mapInner: (bundle, level) => ClassesListLevelOption(
        schoolLevelGroupId: bundle.group.id,
        schoolLevelGroupName: bundle.group.name,
        schoolLevelId: level.id,
        label: level.name,
        displayOrder: level.displayOrder,
        splitIntoClassrooms: level.splitIntoClassrooms,
        classrooms: classroomsByLevel[level.id] ?? const [],
      ),
      mapOuter: (bundle, levels) => ClassesListCycleOption(
        id: bundle.group.id,
        label: bundle.group.name,
        displayOrder: bundle.group.displayOrder,
        levels: levels,
      ),
    );
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

    return members
        .where((member) {
          final memberFirstName = member.studentFirstName.trim().toLowerCase();
          final memberLastName = member.studentLastName.trim().toLowerCase();
          final memberSurname = (member.studentMiddleName ?? '')
              .trim()
              .toLowerCase();

          return memberFirstName.contains(firstName) &&
              memberLastName.contains(lastName) &&
              memberSurname.contains(surname);
        })
        .toList(growable: false);
  }

  static String mapClassroomErrorToMessage(
    AppLocalizations l10n,
    ClassroomErrorType errorType,
  ) => ClassesOrganisationPageHelpers.mapClassroomErrorToMessage(
    l10n,
    errorType,
  );

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

  static bool buildWhenAcademicYearContextChanges(
    AcademicYearContextState previous,
    AcademicYearContextState current,
  ) {
    return previous.status != current.status ||
        previous.context != current.context;
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
