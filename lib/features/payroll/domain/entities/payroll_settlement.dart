import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';

/// Où en est le règlement d'un salaire validé (B3) — dérivé, jamais stocké.
enum PayrollSettlementStatus {
  /// Net nul : rien à verser.
  nothingToPay,

  /// Rien versé.
  unpaid,

  /// Un acompte, en deçà de ce qui était prévu ce mois.
  partial,

  /// Ce qui était prévu ce mois est versé ; le reste est un arriéré décidé.
  deferred,

  /// Tout le net est versé.
  settled,
}

/// Le net validé est une dette de l'école envers l'agent : il se règle en
/// plusieurs versements. `reste = net − Σ versements vivants`, dans la devise
/// de la ligne ; un versement refusé n'en est pas un (il va « à régulariser »).
class PayrollSettlement extends Equatable {
  final PayrollLine line;

  /// Vivants ou en file, dans l'ordre de pose.
  final List<PayrollDisbursement> disbursements;

  const PayrollSettlement({required this.line, required this.disbursements});

  int get netInCents => line.netInCents;

  int get paidInCents =>
      disbursements.fold(0, (sum, d) => sum + d.amount.amountInCents);

  int get remainingInCents {
    final remaining = netInCents - paidInCents;
    return remaining < 0 ? 0 : remaining;
  }

  /// Ce qui reste de la part prévue ce mois (taux du mois ou montant fixe).
  int get plannedRemainingInCents {
    final remaining = line.toPayInCents - paidInCents;
    return remaining < 0 ? 0 : remaining;
  }

  PayrollSettlementStatus get status {
    if (netInCents <= 0) return PayrollSettlementStatus.nothingToPay;
    if (paidInCents >= netInCents) return PayrollSettlementStatus.settled;
    if (line.deferredInCents > 0 && paidInCents >= line.toPayInCents) {
      return PayrollSettlementStatus.deferred;
    }
    return paidInCents == 0
        ? PayrollSettlementStatus.unpaid
        : PayrollSettlementStatus.partial;
  }

  /// Plus rien à verser ce mois : soldé, différé décidé, ou net nul.
  bool get isDoneThisMonth =>
      status == PayrollSettlementStatus.settled ||
      status == PayrollSettlementStatus.deferred ||
      status == PayrollSettlementStatus.nothingToPay;

  PayrollDisbursement? get last =>
      disbursements.isEmpty ? null : disbursements.last;

  @override
  List<Object?> get props => [line, disbursements];
}
