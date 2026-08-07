import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendancePageHelpers {
  const AttendancePageHelpers._();

  /// [classrooms] : toutes les classes de l'année (lecture locale `ClassroomOfflineBloc`),
  /// regroupées ici par niveau — indépendant du référentiel cycles/niveaux.
  static List<AttendanceCycleOption> buildCycleOptions(
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
      mapInner: (bundle, level) => AttendanceLevelOption(
        schoolLevelGroupId: bundle.group.id,
        schoolLevelId: level.id,
        label: level.name,
        displayOrder: level.displayOrder,
        classrooms: classroomsByLevel[level.id] ?? const [],
      ),
      mapOuter: (bundle, levels) => AttendanceCycleOption(
        id: bundle.group.id,
        label: bundle.group.name,
        displayOrder: bundle.group.displayOrder,
        levels: levels,
      ),
    );
  }

  static bool buildWhenAcademicYearContextChanges(
    AcademicYearContextState previous,
    AcademicYearContextState current,
  ) {
    return previous.status != current.status ||
        previous.context != current.context;
  }

  static bool buildWhenFetchStatusChanges(
    AttendanceState previous,
    AttendanceState current,
  ) {
    return previous.fetchStatus != current.fetchStatus ||
        previous.fetchErrorType != current.fetchErrorType ||
        previous.records != current.records;
  }

  static bool buildWhenResultsChanges(
    AttendanceState previous,
    AttendanceState current,
  ) {
    return previous.fetchStatus != current.fetchStatus ||
        previous.fetchErrorType != current.fetchErrorType ||
        previous.records != current.records ||
        previous.draftRows != current.draftRows ||
        previous.callTaken != current.callTaken ||
        previous.saveStatus != current.saveStatus ||
        previous.saveErrorType != current.saveErrorType ||
        previous.hasUnsavedChanges != current.hasUnsavedChanges ||
        previous.hasValidationErrors != current.hasValidationErrors;
  }

  static bool listenWhenFetchFailure(
    AttendanceState previous,
    AttendanceState current,
  ) {
    return previous.fetchStatus != current.fetchStatus ||
        previous.fetchErrorType != current.fetchErrorType;
  }

  static bool listenWhenSaveStatusChanges(
    AttendanceState previous,
    AttendanceState current,
  ) {
    return previous.saveStatus != current.saveStatus ||
        previous.saveErrorType != current.saveErrorType;
  }

  static String mapAttendanceErrorToMessage(
    AppLocalizations l10n,
    AttendanceErrorType errorType,
  ) => switch (errorType) {
    AttendanceErrorType.network => l10n.attendanceErrorNetwork,
    AttendanceErrorType.notFound => l10n.attendanceErrorNotFound,
    AttendanceErrorType.validation => l10n.attendanceErrorValidation,
    AttendanceErrorType.unauthorized => l10n.attendanceErrorUnauthorized,
    AttendanceErrorType.forbidden => l10n.attendanceErrorForbidden,
    AttendanceErrorType.invalidCredentials =>
      l10n.attendanceErrorInvalidCredentials,
    AttendanceErrorType.server => l10n.attendanceErrorServer,
    AttendanceErrorType.storage => l10n.attendanceErrorStorage,
    AttendanceErrorType.auth => l10n.attendanceErrorAuth,
    AttendanceErrorType.none ||
    AttendanceErrorType.unknown => l10n.attendanceErrorUnknown,
  };

  static String absenceReasonLabel(
    AppLocalizations l10n,
    AbsenceReason? reason,
  ) {
    if (reason == null) {
      return l10n.attendanceNoAbsenceReason;
    }

    return switch (reason) {
      AbsenceReason.sickness => l10n.absenceReasonSickness,
      AbsenceReason.familyEmergency => l10n.absenceReasonFamilyEmergency,
      AbsenceReason.personal => l10n.absenceReasonPersonal,
      AbsenceReason.unknown => l10n.absenceReasonUnknown,
      AbsenceReason.vacation => l10n.absenceReasonVacation,
      AbsenceReason.underGraduateLeave => l10n.absenceReasonUnderGraduateLeave,
      AbsenceReason.marriageLeave => l10n.absenceReasonMarriageLeave,
      AbsenceReason.parentalLeave => l10n.absenceReasonParentalLeave,
      AbsenceReason.workLeave => l10n.absenceReasonWorkLeave,
      AbsenceReason.unjustified => l10n.absenceReasonUnjustified,
      AbsenceReason.other => l10n.absenceReasonOther,
    };
  }
}
