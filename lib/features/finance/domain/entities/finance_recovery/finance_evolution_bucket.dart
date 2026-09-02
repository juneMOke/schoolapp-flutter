import 'package:equatable/equatable.dart';

class FinanceEvolutionBucket extends Equatable {
  /// `YYYY-MM` sur l'axe du recouvrement.
  final String key;

  /// Encaissé sur le mois, en centimes.
  final int value;

  /// Le mois en cours — celui qui n'est pas fini, et dont le montant montera
  /// encore.
  final bool isCurrent;

  const FinanceEvolutionBucket({
    required this.key,
    required this.value,
    required this.isCurrent,
  });

  @override
  List<Object?> get props => [key, value, isCurrent];
}
