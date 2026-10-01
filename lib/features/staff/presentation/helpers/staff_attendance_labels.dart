import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les libellés propres au Pointage du personnel ; les libellés communs
/// (statuts, dates, heures) sont dans `PresenceLabels`.
abstract final class StaffAttendanceLabels {
  static String reason(AppLocalizations l10n, StaffAbsenceReason reason) =>
      switch (reason) {
        StaffAbsenceReason.illness => l10n.staffAttendanceReasonIllness,
        StaffAbsenceReason.transport => l10n.staffAttendanceReasonTransport,
        StaffAbsenceReason.bereavement => l10n.staffAttendanceReasonBereavement,
        StaffAbsenceReason.family => l10n.staffAttendanceReasonFamily,
        StaffAbsenceReason.mission => l10n.staffAttendanceReasonMission,
        StaffAbsenceReason.training => l10n.staffAttendanceReasonTraining,
        StaffAbsenceReason.other => l10n.staffAttendanceReasonOther,
      };

  /// Pourquoi un pointage a été refusé, sans le code machine.
  static String refusal(AppLocalizations l10n, StaffAttendanceRecord record) =>
      switch (record.syncErrorCode) {
        kStaffDayLockedCode => l10n.staffAttendanceRefusedDayLocked,
        kStaffMonthClosedCode => l10n.staffAttendanceRefusedMonthClosed,
        _ => l10n.staffAttendanceRefused,
      };

  /// « Nom Post-nom », la ligne de tête d'une carte.
  static String familyName(StaffMember member) => [
    member.lastName,
    member.middleName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
}
