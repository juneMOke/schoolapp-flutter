import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_organisation_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
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

  /// Restreint le roster d'une classe aux noms portés par [request].
  ///
  /// En production c'est l'**affinage** du mode « Par classe » qui arrive ici,
  /// donc le seul nom rempli est [ClassesListSearchRequest.lastName]. Le
  /// rapprochement est partiel et **insensible aux accents**, comme celui du
  /// même champ sur la liste des inscriptions
  /// (`EnrollmentLocalListProjector`) : « kab » doit trouver « Kabongo » des
  /// deux côtés, sans quoi le même geste rendrait deux résultats différents
  /// selon qu'une classe est choisie ou non.
  static List<ClassroomMember> filterMembers(
    List<ClassroomMember> members,
    ClassesListSearchRequest request,
  ) {
    if (!request.hasNameFilters) {
      return members;
    }

    return members
        .where(
          (member) =>
              SearchNormalizationHelper.contains(
                member.studentFirstName,
                request.firstName,
              ) &&
              SearchNormalizationHelper.contains(
                member.studentLastName,
                request.lastName,
              ) &&
              SearchNormalizationHelper.contains(
                member.studentMiddleName,
                request.surname,
              ),
        )
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
    required EnrollmentLocalListState enrollmentState,
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
    EnrollmentLocalListState previous,
    EnrollmentLocalListState current,
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
    EnrollmentLocalListState previous,
    EnrollmentLocalListState current,
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
