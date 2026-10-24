import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';

/// Une ligne du récapitulatif : les totaux du mois d'un agent.
class HrAttendanceRecapRow extends Equatable {
  final HrAttendanceAgent agent;
  final int classDays;
  final int presences;
  final int late;
  final int lateMinutes;
  final int justifiedAbsences;
  final int unjustifiedAbsences;
  final int workedMinutes;

  /// Minutes prestées × taux horaire du contrat, dans sa devise. `null` sans
  /// `hr.pay.read`, ou pour un agent qui n'est pas payé à l'heure.
  final Money? amount;

  const HrAttendanceRecapRow({
    required this.agent,
    required this.classDays,
    required this.presences,
    required this.late,
    required this.lateMinutes,
    required this.justifiedAbsences,
    required this.unjustifiedAbsences,
    required this.workedMinutes,
    required this.amount,
  });

  @override
  List<Object?> get props => [
    agent,
    classDays,
    presences,
    late,
    lateMinutes,
    justifiedAbsences,
    unjustifiedAbsences,
    workedMinutes,
    amount,
  ];
}

/// Les totaux du bandeau du récapitulatif.
class HrAttendanceRecapTotals extends Equatable {
  /// Hors vacataires à l'heure ; `null` sans pointage.
  final int? presenceRatePct;
  final int workedMinutes;
  final int unjustifiedAbsences;

  /// Un montant par devise ; `null` sans `hr.pay.read` — l'écran masque alors
  /// la tuile et la colonne.
  final List<Money>? amounts;

  const HrAttendanceRecapTotals({
    required this.presenceRatePct,
    required this.workedMinutes,
    required this.unjustifiedAbsences,
    required this.amounts,
  });

  @override
  List<Object?> get props => [
    presenceRatePct,
    workedMinutes,
    unjustifiedAbsences,
    amounts,
  ];
}

/// Le récapitulatif d'un mois pour la paie
/// (`GET /hr/attendance-stats/recap?month=`).
///
/// La clôture n'est qu'un verrou : rien n'est transmis, la Paie relit les
/// pointages réels (E4). Un mois clos ne se rouvre pas (E6).
class HrAttendanceRecap extends Equatable {
  /// `AAAA-MM`.
  final String month;
  final int classDays;

  /// Mois en cours : compté jusqu'à aujourd'hui.
  final bool toDate;
  final bool closed;

  /// Instant ISO-8601 de la clôture.
  final String? closedAt;
  final String? closedBy;

  /// Mois fini et compte autorisé à clore (`hr.attendance.manage`).
  final bool closable;

  /// Jours-agent attendus et non pointés.
  final int unscored;
  final HrAttendanceRecapTotals totals;
  final List<HrAttendanceRecapRow> staff;

  const HrAttendanceRecap({
    required this.month,
    required this.classDays,
    required this.toDate,
    required this.closed,
    this.closedAt,
    this.closedBy,
    required this.closable,
    required this.unscored,
    required this.totals,
    required this.staff,
  });

  @override
  List<Object?> get props => [
    month,
    classDays,
    toDate,
    closed,
    closedAt,
    closedBy,
    closable,
    unscored,
    totals,
    staff,
  ];
}
