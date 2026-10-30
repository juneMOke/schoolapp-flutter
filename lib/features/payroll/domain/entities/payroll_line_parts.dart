import 'package:equatable/equatable.dart';

/// Les retenues fixes v2 d'une ligne, dans l'ordre où elles se prennent sur
/// le brut (T3) : l'absence non justifiée, puis l'IPR et la CNSS, puis la
/// prise en charge des enfants. Chaque montant est **ce qui a été retenu** —
/// ce qui ne tenait plus dans le brut est perdu, jamais reporté. Centimes.
class PayrollLineDeductions extends Equatable {
  /// Le diviseur de la retenue : J, les jours ouvrés du mois, depuis la
  /// formule 3 (le réglage de l'école avant) ; `null` pour un vacataire à
  /// l'heure, que l'absence ne concerne pas.
  final int? workDaysDivisor;

  /// Les jours prestés (NJP) d'une ligne figée en formule 2 ; `null` depuis.
  final int? workedDays;

  /// NJ, les absences non justifiées retenues — formule 3 seulement.
  final int? unjustifiedAbsences;
  final int absenceInCents;
  final int iprInCents;
  final int cnssInCents;
  final int childcareInCents;

  const PayrollLineDeductions({
    this.workDaysDivisor,
    this.workedDays,
    this.unjustifiedAbsences,
    this.absenceInCents = 0,
    this.iprInCents = 0,
    this.cnssInCents = 0,
    this.childcareInCents = 0,
  });

  /// Une ligne v1, ou une école qui ne règle rien.
  static const PayrollLineDeductions none = PayrollLineDeductions();

  int get totalInCents =>
      absenceInCents + iprInCents + cnssInCents + childcareInCents;

  /// Les jours d'absence retenus : NJ en formule 3, `diviseur − NJP` avant.
  int? get absentDays {
    if (unjustifiedAbsences case final absences?) return absences;
    final divisor = workDaysDivisor;
    final worked = workedDays;
    if (divisor == null || worked == null) return null;
    return divisor - worked;
  }

  @override
  List<Object?> get props => [
    workDaysDivisor,
    workedDays,
    unjustifiedAbsences,
    absenceInCents,
    iprInCents,
    cnssInCents,
    childcareInCents,
  ];
}

/// Ce que l'école verse ce mois sur le net : le taux du mois, ou le montant
/// fixe de l'agent qui prime sur lui. Le net dû ne change pas ; le reste
/// ([deferredInCents]) devient un arriéré à la validation. Centimes.
class PayrollLinePayout extends Equatable {
  final int toPayInCents;
  final int deferredInCents;

  /// Le taux appliqué, en % ; `null` quand un montant fixe a primé.
  final int? ratePercent;

  /// Le montant fixe saisi pour l'agent, tel quel (il peut dépasser le net,
  /// borné dans [toPayInCents]) ; `null` sans montant fixe.
  final int? fixedInCents;

  /// Le motif du taux réduit ou du montant fixe ; `null` à 100 %.
  final String? reason;

  const PayrollLinePayout({
    required this.toPayInCents,
    required this.deferredInCents,
    this.ratePercent,
    this.fixedInCents,
    this.reason,
  });

  /// Un montant fixe a primé sur le taux du mois.
  bool get fixed => fixedInCents != null;

  /// Versement intégral du net.
  factory PayrollLinePayout.full(int netInCents) => PayrollLinePayout(
    toPayInCents: netInCents,
    deferredInCents: 0,
    ratePercent: 100,
  );

  bool get isReduced => deferredInCents > 0;

  @override
  List<Object?> get props => [
    toPayInCents,
    deferredInCents,
    ratePercent,
    fixedInCents,
    reason,
  ];
}
