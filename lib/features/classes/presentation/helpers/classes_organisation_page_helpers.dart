import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationPageHelpers {
  const ClassesOrganisationPageHelpers._();

  static List<ClassesOrganisationLevelOption> buildAcademicOptions(
    List<BootstrapSchoolLevelGroupBundle> bundles,
  ) {
    final seen = <String>{};
    final sortedOptions = SortedNestedOptionsHelper.buildFlat(
      outers: bundles,
      outerOrder: (bundle) => bundle.schoolLevelGroup.displayOrder,
      inners: (bundle) => bundle.schoolLevels,
      innerOrder: (levelBundle) => levelBundle.schoolLevel.displayOrder,
      mapItem: (groupBundle, levelBundle) => ClassesOrganisationLevelOption(
        schoolLevelGroupId: groupBundle.schoolLevelGroup.id,
        schoolLevelGroupName: groupBundle.schoolLevelGroup.name,
        schoolLevelId: levelBundle.schoolLevel.id,
        schoolLevelName: levelBundle.schoolLevel.name,
        splitIntoClassrooms: levelBundle.schoolLevel.splitIntoClassrooms,
        classrooms: levelBundle.classrooms,
      ),
    );

    return sortedOptions
        .where((option) => seen.add(option.key))
        .toList(growable: false);
  }

  static List<ClassesOrganisationCycleOption> buildCycleOptions(
    List<ClassesOrganisationLevelOption> levels,
  ) {
    final grouped = <String, List<ClassesOrganisationLevelOption>>{};

    for (final level in levels) {
      grouped
          .putIfAbsent(
            level.schoolLevelGroupId,
            () => <ClassesOrganisationLevelOption>[],
          )
          .add(level);
    }

    final cycles = grouped.entries
        .map((entry) {
          final sample = entry.value.first;
          return ClassesOrganisationCycleOption(
            id: entry.key,
            label: sample.schoolLevelGroupName,
            levels: entry.value,
          );
        })
        .toList(growable: false);

    cycles.sort((a, b) => a.label.compareTo(b.label));
    return cycles;
  }

  static String mapClassroomErrorToMessage(
    AppLocalizations l10n,
    ClassroomErrorType errorType,
  ) {
    return switch (errorType) {
      ClassroomErrorType.network => l10n.classesOrganisationErrorNetwork,
      ClassroomErrorType.notFound => l10n.classesOrganisationErrorNotFound,
      ClassroomErrorType.validation => l10n.classesOrganisationErrorValidation,
      ClassroomErrorType.unauthorized =>
        l10n.classesOrganisationErrorUnauthorized,
      ClassroomErrorType.invalidCredentials =>
        l10n.classesOrganisationErrorInvalidCredentials,
      ClassroomErrorType.server => l10n.classesOrganisationErrorServer,
      ClassroomErrorType.storage => l10n.classesOrganisationErrorStorage,
      ClassroomErrorType.auth => l10n.classesOrganisationErrorAuth,
      _ => l10n.classesOrganisationErrorUnknown,
    };
  }

  static bool isSearching(
    ClassroomState classroomState,
    EnrollmentState enrollmentState,
    ClassesOrganisationSearchRequest? lastRequest,
  ) {
    final split = lastRequest?.selectedLevel?.splitIntoClassrooms ?? false;
    if (split) {
      return classroomState.status == ClassroomStatus.loading ||
          classroomState.membersStatus == ClassroomStatus.loading;
    }
    return enrollmentState.summariesStatus == EnrollmentLoadStatus.loading;
  }

  static bool listenDistributionStatus(
    ClassroomState previous,
    ClassroomState current,
  ) {
    return previous.distributionStatus != current.distributionStatus;
  }

  static bool listenReassignStatus(
    ClassroomState previous,
    ClassroomState current,
  ) {
    return previous.reassignStatus != current.reassignStatus;
  }

  static bool buildWhenBootstrapChanges(
    BootstrapContextState previous,
    BootstrapContextState current,
  ) {
    return previous.status != current.status ||
        previous.bootstrap != current.bootstrap;
  }

  static bool buildWhenSearchFormChanges(
    ClassroomState previous,
    ClassroomState current,
  ) {
    return previous.status != current.status ||
        previous.membersStatus != current.membersStatus ||
        previous.distributionStatus != current.distributionStatus;
  }

  static bool buildWhenClassroomResultsChange(
    ClassroomState previous,
    ClassroomState current,
  ) {
    return previous.status != current.status ||
        previous.classrooms != current.classrooms ||
        previous.membersStatus != current.membersStatus ||
        previous.membersByClassroom != current.membersByClassroom ||
        previous.membersErrorType != current.membersErrorType;
  }
}
