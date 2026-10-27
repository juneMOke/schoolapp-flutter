import 'package:equatable/equatable.dart';

/// La somme des lignes servies d'une devise — la ligne Total du tableau.
class PayrollDashboardTotals extends Equatable {
  final int plannedInCents;
  final int deductionsInCents;
  final int netInCents;
  final int arrearsInCents;
  final int receivedInCents;
  final int remainingInCents;

  const PayrollDashboardTotals({
    this.plannedInCents = 0,
    this.deductionsInCents = 0,
    this.netInCents = 0,
    this.arrearsInCents = 0,
    this.receivedInCents = 0,
    this.remainingInCents = 0,
  });

  @override
  List<Object?> get props => [
    plannedInCents,
    deductionsInCents,
    netInCents,
    arrearsInCents,
    receivedInCents,
    remainingInCents,
  ];
}
