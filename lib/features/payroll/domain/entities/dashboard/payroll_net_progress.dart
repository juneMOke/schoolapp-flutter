import 'package:equatable/equatable.dart';

/// Où en est le net d'un mois dans une devise :
/// `paid + deferred + unpaid + notYet = net`. Une paie non validée a tout en
/// [notYetInCents] et ses compteurs à 0.
///
/// ⚠️ Les compteurs ne portent que sur le net **du mois** : un agent soldé
/// pour le mois qui doit encore un arriéré compte ici comme soldé, alors que
/// sa ligne dit « Partiel » ou « À payer » (la ligne compte les arriérés).
class PayrollNetProgress extends Equatable {
  final int paidInCents;

  /// La part différée par le taux du mois, pas encore versée.
  final int deferredInCents;
  final int unpaidInCents;
  final int notYetInCents;
  final int settledCount;
  final int partialCount;
  final int unpaidCount;

  const PayrollNetProgress({
    this.paidInCents = 0,
    this.deferredInCents = 0,
    this.unpaidInCents = 0,
    this.notYetInCents = 0,
    this.settledCount = 0,
    this.partialCount = 0,
    this.unpaidCount = 0,
  });

  int get totalInCents =>
      paidInCents + deferredInCents + unpaidInCents + notYetInCents;

  /// Le reste du net du mois, une fois la paie validée.
  int get outstandingInCents => deferredInCents + unpaidInCents;

  @override
  List<Object?> get props => [
    paidInCents,
    deferredInCents,
    unpaidInCents,
    notYetInCents,
    settledCount,
    partialCount,
    unpaidCount,
  ];
}
