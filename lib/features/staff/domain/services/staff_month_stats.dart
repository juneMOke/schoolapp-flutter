import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';

/// La synthèse d'un agent sur un mois — calculée, **jamais stockée** ni
/// envoyée : le livre de paie prendra sa propre photo.
class StaffMonthStats extends Equatable {
  /// Jours ouvrés du mois (jusqu'à aujourd'hui pour le mois en cours).
  final int workDays;

  /// Présent ou en retard.
  final int present;
  final int late;
  final int lateMinutes;

  /// Retards sans justification — le compteur « à justifier ».
  final int lateUnjustified;
  final int absentJustified;
  final int absentUnjustified;

  /// Jours ouvrés sans pointage (ou effacés). Toujours 0 pour un vacataire à
  /// l'heure : il ne vient que les jours de cours.
  final int notMarked;

  final int workedMinutes;
  final bool isHourly;

  /// Heures × taux, pour un vacataire à l'heure dont le taux est visible.
  final Money? amount;

  const StaffMonthStats({
    required this.workDays,
    required this.present,
    required this.late,
    required this.lateMinutes,
    required this.lateUnjustified,
    required this.absentJustified,
    required this.absentUnjustified,
    required this.notMarked,
    required this.workedMinutes,
    required this.isHourly,
    this.amount,
  });

  int get absent => absentJustified + absentUnjustified;

  /// Retards et absences sans justification.
  int get unjustified => lateUnjustified + absentUnjustified;

  /// Le calcul (`ptMonthStats`) : [records] = les pointages de l'agent sur le
  /// mois, par jour ; [workDays] = les jours ouvrés retenus.
  factory StaffMonthStats.of({
    required Map<String, StaffAttendanceRecord> records,
    required List<String> workDays,
    required bool isHourly,
    Money? hourlyRate,
  }) {
    var present = 0;
    var late = 0;
    var lateMinutes = 0;
    var lateUnjustified = 0;
    var absentJustified = 0;
    var absentUnjustified = 0;
    var notMarked = 0;
    var worked = 0;
    for (final day in workDays) {
      final record = records[day];
      switch (record?.status ?? StaffAttendanceStatus.none) {
        case StaffAttendanceStatus.none:
          if (!isHourly) notMarked++;
        case StaffAttendanceStatus.present:
          present++;
        case StaffAttendanceStatus.late:
          present++;
          late++;
          lateMinutes += record!.lateMinutes;
          if (!record.isJustified) lateUnjustified++;
        case StaffAttendanceStatus.absent:
          if (record!.isJustified) {
            absentJustified++;
          } else {
            absentUnjustified++;
          }
      }
      worked += record?.workedMinutes ?? 0;
    }
    return StaffMonthStats(
      workDays: workDays.length,
      present: present,
      late: late,
      lateMinutes: lateMinutes,
      lateUnjustified: lateUnjustified,
      absentJustified: absentJustified,
      absentUnjustified: absentUnjustified,
      notMarked: notMarked,
      workedMinutes: worked,
      isHourly: isHourly,
      amount: isHourly && hourlyRate != null
          ? Money(
              (hourlyRate.amountInCents * worked / 60).round(),
              hourlyRate.currency,
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
    workDays,
    present,
    late,
    lateMinutes,
    lateUnjustified,
    absentJustified,
    absentUnjustified,
    notMarked,
    workedMinutes,
    isHourly,
    amount,
  ];
}
