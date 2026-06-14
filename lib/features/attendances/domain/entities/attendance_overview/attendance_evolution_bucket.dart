import 'package:equatable/equatable.dart';

/// Un point de l'evolution du taux de presence (un mois / semaine / jour).
class AttendanceEvolutionBucket extends Equatable {
  final String key;
  final double presenceRate;
  final int recordedDays;
  final bool isCurrent;

  const AttendanceEvolutionBucket({
    required this.key,
    required this.presenceRate,
    required this.recordedDays,
    required this.isCurrent,
  });

  @override
  List<Object?> get props => [key, presenceRate, recordedDays, isCurrent];
}
