import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';

/// D'où vient un arriéré (B4).
enum PayrollArrearOrigin {
  /// La part non versée par décision : taux du mois ou montant fixe.
  deferred,

  /// Rien versé sur une paie validée.
  unpaid,

  /// Le reste d'un acompte.
  partial,
}

/// Ce que l'école doit encore à un agent sur une paie validée — jamais saisi,
/// il naît d'un reste à payer et reste rattaché à son mois d'origine. Un
/// versement d'arriéré est un versement ordinaire sur cette paie.
class PayrollArrear extends Equatable {
  final PayrollLine line;

  /// La validation sous laquelle se verse le reste.
  final String validationGestureId;
  final int paidInCents;
  final PayrollArrearOrigin origin;
  final bool prioritized;

  /// Le motif d'un versement réduit (taux du mois ou montant fixe).
  final String? reason;

  const PayrollArrear({
    required this.line,
    required this.validationGestureId,
    required this.paidInCents,
    required this.origin,
    this.prioritized = false,
    this.reason,
  });

  String get staffMemberId => line.staffMemberId;

  /// `YYYY-MM`.
  String get month => line.month;
  String get currency => line.currency;
  int get dueInCents => line.netInCents - paidInCents;

  @override
  List<Object?> get props => [
    line,
    validationGestureId,
    paidInCents,
    origin,
    prioritized,
    reason,
  ];
}

/// Les arriérés d'un agent, du mois le plus ancien au plus récent.
class PayrollArrearsAgent extends Equatable {
  final String staffMemberId;
  final List<PayrollArrear> months;

  const PayrollArrearsAgent({
    required this.staffMemberId,
    required this.months,
  });

  /// Les devises dues, triées.
  List<String> get currencies =>
      {for (final arrear in months) arrear.currency}.toList()..sort();

  int dueIn(String currency) => months
      .where((arrear) => arrear.currency == currency)
      .fold(0, (sum, arrear) => sum + arrear.dueInCents);

  String get oldestMonth => months.first.month;

  bool get prioritized => months.any((arrear) => arrear.prioritized);

  Set<PayrollArrearOrigin> get origins => {
    for (final arrear in months) arrear.origin,
  };

  @override
  List<Object?> get props => [staffMemberId, months];
}
