import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';

/// Le statut de la paie du mois, au regard du récapitulatif : « prévu »
/// tant qu'elle n'est pas validée, « figé » ensuite.
enum HrRecapPayrollStatus {
  /// Aucune paie encore ouverte pour ce mois.
  none,
  draft,
  submitted,
  validated;

  static HrRecapPayrollStatus fromWire(String? wire) => switch (wire) {
    'DRAFT' => draft,
    'SUBMITTED' => submitted,
    'VALIDATED' => validated,
    _ => none,
  };
}

/// Ce que la paie du mois donne pour un agent, calculé par le moteur du
/// livre (formule 3) : sur le Pointage en direct d'un mois ouvert, sur son
/// résumé une fois clos, sur les lignes figées d'une paie validée. Centimes,
/// dans la devise du contrat en vigueur.
class HrAttendanceRecapPay extends Equatable {
  final String currency;
  final int baseInCents;

  /// Brut prévu : base + heures sup. + allocations familiales.
  final int grossInCents;

  /// `base ÷ J` arrondi, pour l'affichage « 2 j × 21,82 $ » ; seule la
  /// retenue fait foi. `null` pour un vacataire à l'heure.
  final int? dailyRateInCents;

  /// La retenue d'absence, arrondie une seule fois ; `null` pour un
  /// vacataire à l'heure.
  final int? absenceDeductionInCents;
  final int grossAfterAbsenceInCents;

  /// Vacataire à l'heure seulement : sa base est minutes × ce taux.
  final int? hourlyRateInCents;

  const HrAttendanceRecapPay({
    required this.currency,
    required this.baseInCents,
    required this.grossInCents,
    required this.grossAfterAbsenceInCents,
    this.dailyRateInCents,
    this.absenceDeductionInCents,
    this.hourlyRateInCents,
  });

  bool get isHourly => hourlyRateInCents != null;

  @override
  List<Object?> get props => [
    currency,
    baseInCents,
    grossInCents,
    dailyRateInCents,
    absenceDeductionInCents,
    grossAfterAbsenceInCents,
    hourlyRateInCents,
  ];
}

/// Les totaux d'argent d'une devise : jamais deux devises additionnées.
class HrAttendanceRecapAmount extends Equatable {
  final String currency;

  /// Les heures de vacation × taux, à l'ancienne.
  final int hoursInCents;
  final int baseInCents;
  final int grossInCents;
  final int absenceDeductionInCents;
  final int grossAfterAbsenceInCents;

  const HrAttendanceRecapAmount({
    required this.currency,
    this.hoursInCents = 0,
    this.baseInCents = 0,
    this.grossInCents = 0,
    this.absenceDeductionInCents = 0,
    this.grossAfterAbsenceInCents = 0,
  });

  Money get hours => Money(hoursInCents, currency);

  @override
  List<Object?> get props => [
    currency,
    hoursInCents,
    baseInCents,
    grossInCents,
    absenceDeductionInCents,
    grossAfterAbsenceInCents,
  ];
}

/// Une ligne du récapitulatif : les totaux du mois d'un agent.
class HrAttendanceRecapRow extends Equatable {
  final HrAttendanceAgent agent;
  final int classDays;
  final int presences;
  final int late;
  final int lateMinutes;
  final int justifiedAbsences;
  final int unjustifiedAbsences;

  /// Jours de classe attendus et non pointés — jamais pour un vacataire à
  /// l'heure (D2).
  final int unscored;
  final int workedMinutes;

  /// Minutes prestées × taux horaire du contrat, dans sa devise. `null` sans
  /// `hr.pay.read`, ou pour un agent qui n'est pas payé à l'heure.
  final Money? amount;

  /// Sa paie du mois ; `null` sans `hr.pay.read`, ou sans ligne de paie.
  final HrAttendanceRecapPay? pay;

  const HrAttendanceRecapRow({
    required this.agent,
    required this.classDays,
    required this.presences,
    required this.late,
    required this.lateMinutes,
    required this.justifiedAbsences,
    required this.unjustifiedAbsences,
    required this.unscored,
    required this.workedMinutes,
    required this.amount,
    this.pay,
  });

  @override
  List<Object?> get props => [
    pay,
    agent,
    classDays,
    presences,
    late,
    lateMinutes,
    justifiedAbsences,
    unjustifiedAbsences,
    unscored,
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

  /// Une entrée par devise ; `null` sans `hr.pay.read` — l'écran masque alors
  /// les tuiles et les colonnes d'argent.
  final List<HrAttendanceRecapAmount>? amounts;

  const HrAttendanceRecapTotals({
    required this.presenceRatePct,
    required this.workedMinutes,
    required this.unjustifiedAbsences,
    required this.amounts,
  });

  /// Le montant des heures de vacation, par devise : celles qui en ont.
  List<Money>? get hourAmounts => amounts == null
      ? null
      : [
          for (final amount in amounts!)
            if (amount.hoursInCents > 0) amount.hours,
        ];

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
/// La clôture n'est qu'un verrou : rien n'est transmis, la Paie lit le
/// résumé du mois clos (E4). La direction peut rouvrir un mois clos tant que
/// sa paie n'est pas validée.
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

  /// Le geste `REOPEN_MONTH` serait accepté : mois clos, de l'année en
  /// cours, paie pas validée, compte autorisé (`hr.attendance.reopen`).
  final bool reopenable;

  /// La retenue d'absence est active pour l'école (réglage en vigueur).
  final bool absenceDeductionEnabled;

  /// J, les jours ouvrés du mois : le diviseur de la retenue.
  final int workingDays;
  final HrRecapPayrollStatus payrollStatus;

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
    this.reopenable = false,
    this.absenceDeductionEnabled = false,
    this.workingDays = 0,
    this.payrollStatus = HrRecapPayrollStatus.none,
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
    reopenable,
    absenceDeductionEnabled,
    workingDays,
    payrollStatus,
    unscored,
    totals,
    staff,
  ];
}
