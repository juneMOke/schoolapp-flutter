import 'package:equatable/equatable.dart';

/// Le prévu et le réel d'un mois dans une devise, sur toutes ses lignes. Les
/// retenues sont celles réellement prises :
/// `net + absence + legal + childcare + custom + advances = gross`, à l'unité.
class PayrollDashboardForecast extends Equatable {
  final int grossInCents;
  final int absenceInCents;
  final int advancesInCents;

  /// IPR + CNSS.
  final int legalInCents;
  final int childcareInCents;

  /// Les rubriques de l'école ; 0 tant que le serveur ne les sert pas.
  final int customDeductionsInCents;
  final int netInCents;

  /// Brut × (CNSS employeur + INPP + ONEM) ‰, aux taux du jour du calcul.
  final int employerChargesInCents;

  const PayrollDashboardForecast({
    this.grossInCents = 0,
    this.absenceInCents = 0,
    this.advancesInCents = 0,
    this.legalInCents = 0,
    this.childcareInCents = 0,
    this.customDeductionsInCents = 0,
    this.netInCents = 0,
    this.employerChargesInCents = 0,
  });

  /// Ce que les retenues séparent du brut.
  int get savedInCents => grossInCents - netInCents;

  @override
  List<Object?> get props => [
    grossInCents,
    absenceInCents,
    advancesInCents,
    legalInCents,
    childcareInCents,
    customDeductionsInCents,
    netInCents,
    employerChargesInCents,
  ];
}
