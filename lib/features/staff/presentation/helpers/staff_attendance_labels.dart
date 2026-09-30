import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les libellés du Pointage, en un seul endroit.
abstract final class StaffAttendanceLabels {
  /// Le statut d'un pointage (« En retard »).
  static String status(AppLocalizations l10n, StaffAttendanceStatus status) =>
      switch (status) {
        StaffAttendanceStatus.none => l10n.staffAttendanceStatusNone,
        StaffAttendanceStatus.present => l10n.staffAttendanceStatusPresent,
        StaffAttendanceStatus.late => l10n.staffAttendanceStatusLate,
        StaffAttendanceStatus.absent => l10n.staffAttendanceStatusAbsent,
      };

  /// Le même statut comme filtre (« Retards »).
  static String filter(AppLocalizations l10n, StaffAttendanceStatus status) =>
      switch (status) {
        StaffAttendanceStatus.none => l10n.staffAttendanceStatusNone,
        StaffAttendanceStatus.present => l10n.staffAttendanceFilterPresent,
        StaffAttendanceStatus.late => l10n.staffAttendanceFilterLate,
        StaffAttendanceStatus.absent => l10n.staffAttendanceFilterAbsent,
      };

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

  // Les dates passent par [MaterialLocalizations], comme partout ailleurs
  // dans l'application : aucune donnée de locale à initialiser.

  /// « mardi 29 septembre 2026 ».
  static String longDay(MaterialLocalizations dates, String day) =>
      dates.formatFullDate(DateTime.parse(day));

  /// « septembre 2026 ».
  static String month(MaterialLocalizations dates, String month) =>
      dates.formatMonthYear(DateTime.parse('$month-01'));

  /// « 29 sept. 2026 · 16:02 » depuis un instant ISO-8601.
  static String? moment(MaterialLocalizations dates, String? iso) {
    final instant = DateTime.tryParse(iso ?? '')?.toLocal();
    if (instant == null) return null;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dates.formatMediumDate(instant)} · '
        '${two(instant.hour)}:${two(instant.minute)}';
  }

  /// « 3 h » ou « 3 h 30 » depuis des minutes.
  static String hours(AppLocalizations l10n, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0
        ? l10n.staffAttendanceHours(h)
        : l10n.staffAttendanceHoursMinutes(h, m.toString().padLeft(2, '0'));
  }
}
