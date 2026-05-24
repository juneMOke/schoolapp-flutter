import 'package:equatable/equatable.dart';

class FinanceEvolutionBucket extends Equatable {
  final String key;
  final int value;
  final bool isCurrent;

  const FinanceEvolutionBucket({
    required this.key,
    required this.value,
    required this.isCurrent,
  });

  @override
  List<Object?> get props => [key, value, isCurrent];
}
