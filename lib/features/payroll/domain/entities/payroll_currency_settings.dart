import 'package:equatable/equatable.dart';

/// Les réglages d'une devise : allocation par enfant, taux d'heure sup. par
/// défaut, le pas auquel s'arrondit un taux calculé, et les retenues légales
/// v2 — le forfait IPR par agent payé et la CNSS en ‰ de la base. Centimes.
class PayrollCurrencySettings extends Equatable {
  final int childAllowanceInCents;
  final int defaultOvertimeRateInCents;
  final int overtimeRateStepInCents;

  /// Retenu une fois sur chaque agent dont le brut est positif (T3).
  final int iprFlatInCents;

  /// Pour mille de la base de la ligne, avant l'absence (T4).
  final int cnssPermille;

  const PayrollCurrencySettings({
    required this.childAllowanceInCents,
    required this.defaultOvertimeRateInCents,
    required this.overtimeRateStepInCents,
    this.iprFlatInCents = 0,
    this.cnssPermille = 0,
  });

  /// Une devise que l'école n'a pas réglée : rien n'est inventé.
  static const PayrollCurrencySettings none = PayrollCurrencySettings(
    childAllowanceInCents: 0,
    defaultOvertimeRateInCents: 0,
    overtimeRateStepInCents: 0,
  );

  @override
  List<Object?> get props => [
    childAllowanceInCents,
    defaultOvertimeRateInCents,
    overtimeRateStepInCents,
    iprFlatInCents,
    cnssPermille,
  ];
}
