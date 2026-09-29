import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_timeline.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_stats.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';

/// Le mois d'un agent, tel que la fiche mensuelle et le récapitulatif le
/// lisent : **une seule** façon de compter, partagée par les deux écrans.
class StaffMonthLedger {
  final StaffAttendanceSnapshot snapshot;

  /// `YYYY-MM`.
  final String month;

  /// Jours ouvrés retenus : lundi → vendredi, jusqu'à aujourd'hui, dans
  /// l'année scolaire. Vide = vacances.
  final List<String> workDays;

  /// Le jour qui dit le contrat du mois : aujourd'hui pour le mois en cours,
  /// sinon son dernier jour.
  final String referenceDay;

  StaffMonthLedger._(
    this.snapshot,
    this.month,
    this.workDays,
    this.referenceDay,
  );

  factory StaffMonthLedger.of(
    StaffAttendanceSnapshot snapshot, {
    required String month,
    required String today,
  }) {
    final days = StaffWorkCalendar.daysOf(month);
    final last = days.last;
    return StaffMonthLedger._(
      snapshot,
      month,
      StaffWorkCalendar.workDaysOf(
        month,
        today: today,
        year: snapshot.schoolYear,
      ),
      last.compareTo(today) > 0 ? today : last,
    );
  }

  bool get isHoliday => workDays.isEmpty;

  bool get isClosed => snapshot.isMonthClosed(month);

  StaffContractPeriod? periodOf(StaffMember member) =>
      StaffContractTimeline.currentAt(member.contracts, referenceDay);

  StaffMonthStats statsOf(StaffMember member) => StaffMonthStats.of(
    records: snapshot.records[member.id] ?? const {},
    workDays: workDays,
    isHourly: periodOf(member)?.isHourlyVacataire ?? false,
    hourlyRate: snapshot.hourlyRates[member.id],
  );
}
