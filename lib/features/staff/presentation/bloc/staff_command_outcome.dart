import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_notice.dart';

/// Ce qu'un geste du Pointage annonce : le refus d'un jour figé avant toute
/// écriture, ou l'issue de l'écriture elle-même.
abstract final class StaffCommandOutcome {
  /// Le refus d'un geste sur un jour figé (mois clos d'abord), ou `null`.
  static StaffAttendanceNotice? frozen(
    StaffAttendanceSnapshot snapshot,
    String day,
  ) {
    if (snapshot.isMonthClosed(SchoolDayCalendar.monthOf(day))) {
      return const StaffAttendanceNotice(StaffAttendanceNoticeKind.monthFrozen);
    }
    if (snapshot.isDayValidated(day)) {
      return const StaffAttendanceNotice(StaffAttendanceNoticeKind.dayFrozen);
    }
    return null;
  }

  /// Un refus local du dépôt se lit comme l'annonce correspondante.
  static StaffAttendanceNotice? of(
    Either<Failure, Unit> result,
    StaffAttendanceNotice? done,
  ) => result.fold(
    (failure) => switch (failure.message) {
      kStaffDayLockedCode => const StaffAttendanceNotice(
        StaffAttendanceNoticeKind.dayFrozen,
      ),
      kStaffMonthClosedCode => const StaffAttendanceNotice(
        StaffAttendanceNoticeKind.monthFrozen,
      ),
      _ => const StaffAttendanceNotice(StaffAttendanceNoticeKind.writeFailed),
    },
    (_) => done,
  );
}
