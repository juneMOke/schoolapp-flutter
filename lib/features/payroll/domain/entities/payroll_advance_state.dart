import 'package:equatable/equatable.dart';

/// Une avance telle que le moteur la voit pour un mois — la forme de
/// `AdvanceState` du serveur et des vecteurs de référence : ce qui en est déjà
/// retenu, et combien de paies validées l'ont fait mûrir.
class PayrollAdvanceState extends Equatable {
  final String advanceId;
  final int amountInCents;
  final String currency;
  final int installments;

  /// `YYYY-MM`.
  final String firstMonth;

  /// Paies validées, avant ce mois, où l'agent a une ligne dans la devise de
  /// l'avance, depuis son mois de départ (Q4).
  final int maturedMonths;

  /// Somme des retenues figées.
  final int alreadyTaken;

  const PayrollAdvanceState({
    required this.advanceId,
    required this.amountInCents,
    required this.currency,
    required this.installments,
    required this.firstMonth,
    required this.maturedMonths,
    required this.alreadyTaken,
  });

  @override
  List<Object?> get props => [
    advanceId,
    amountInCents,
    currency,
    installments,
    firstMonth,
    maturedMonths,
    alreadyTaken,
  ];
}
