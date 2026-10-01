import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

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

  /// Heures × taux, pour les jours à l'heure dont le taux est visible.
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
  ///
  /// Le contrat se lit **jour par jour** ([periodOn]) : un jour sans contrat
  /// ne compte pas (avant l'embauche, après la sortie) ; un jour à l'heure ne
  /// compte jamais comme « non pointé », et ses heures se valorisent au taux
  /// de son propre contrat ([contractRates], par `contractId`). Un mois
  /// [closed] compte ses non-pointés comme présents, comme la clôture l'a
  /// annoncé. [isHourly] dit seulement comment afficher l'agent.
  factory StaffMonthStats.of({
    required Map<String, StaffAttendanceRecord> records,
    required List<String> workDays,
    required StaffContractPeriod? Function(String day) periodOn,
    required bool isHourly,
    bool closed = false,
    Map<String, Money> contractRates = const {},
  }) {
    var days = 0;
    var present = 0;
    var late = 0;
    var lateMinutes = 0;
    var lateUnjustified = 0;
    var absentJustified = 0;
    var absentUnjustified = 0;
    var notMarked = 0;
    var worked = 0;
    final amounts = <String, double>{};
    for (final day in workDays) {
      final period = periodOn(day);
      if (period == null) continue;
      days++;
      final hourly = period.isHourlyVacataire;
      final record = records[day];
      switch (record?.status ?? PresenceStatus.none) {
        case PresenceStatus.none:
          if (hourly) break;
          if (closed) {
            present++;
          } else {
            notMarked++;
          }
        case PresenceStatus.present:
          present++;
        case PresenceStatus.late:
          present++;
          late++;
          lateMinutes += record!.lateMinutes;
          if (!record.isJustified) lateUnjustified++;
        case PresenceStatus.absent:
          if (record!.isJustified) {
            absentJustified++;
          } else {
            absentUnjustified++;
          }
      }
      final minutes = hourly ? record?.workedMinutes ?? 0 : 0;
      worked += minutes;
      final rate = contractRates[period.contractId];
      if (minutes > 0 && rate != null) {
        amounts[rate.currency] =
            (amounts[rate.currency] ?? 0) + rate.amountInCents * minutes / 60;
      }
    }
    return StaffMonthStats(
      workDays: days,
      present: present,
      late: late,
      lateMinutes: lateMinutes,
      lateUnjustified: lateUnjustified,
      absentJustified: absentJustified,
      absentUnjustified: absentUnjustified,
      notMarked: notMarked,
      workedMinutes: worked,
      isHourly: isHourly,
      // Deux devises dans un même mois ne s'additionnent pas : pas de
      // montant plutôt qu'un montant faux.
      amount: amounts.length == 1
          ? Money(amounts.values.single.round(), amounts.keys.single)
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
