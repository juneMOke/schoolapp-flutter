import 'package:equatable/equatable.dart';

class EvolutionBucket extends Equatable {
  final String key;
  final int value;
  final bool isCurrent;

  const EvolutionBucket({
    required this.key,
    required this.value,
    required this.isCurrent,
  });

  @override
  List<Object?> get props => [key, value, isCurrent];
}
