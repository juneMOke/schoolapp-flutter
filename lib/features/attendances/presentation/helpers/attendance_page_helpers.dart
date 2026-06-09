import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_models.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendancePageHelpers {
  const AttendancePageHelpers._();

  static List<AttendanceCycleOption> buildCycleOptions(
    List<BootstrapSchoolLevelGroupBundle> bundles,
  ) {
    return SortedNestedOptionsHelper.build(
      outers: bundles,
      outerOrder: (bundle) => bundle.schoolLevelGroup.displayOrder,
      inners: (bundle) => bundle.schoolLevels,
      innerOrder: (levelBundle) => levelBundle.schoolLevel.displayOrder,
      mapInner: (bundle, levelBundle) => AttendanceLevelOption(
        schoolLevelGroupId: bundle.schoolLevelGroup.id,
        schoolLevelId: levelBundle.schoolLevel.id,
        label: levelBundle.schoolLevel.name,
        displayOrder: levelBundle.schoolLevel.displayOrder,
        classrooms: levelBundle.classrooms,
      ),
      mapOuter: (bundle, levels) => AttendanceCycleOption(
        id: bundle.schoolLevelGroup.id,
        label: bundle.schoolLevelGroup.name,
        displayOrder: bundle.schoolLevelGroup.displayOrder,
        levels: levels,
      ),
    );
  }

  static bool buildWhenBootstrapChanges(
    BootstrapContextState previous,
    BootstrapContextState current,
  ) {
    return previous.status != current.status ||
        previous.bootstrap != current.bootstrap;
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
