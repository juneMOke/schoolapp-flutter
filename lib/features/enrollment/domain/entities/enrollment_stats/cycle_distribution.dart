import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/cycle_stat.dart';

class CycleDistribution extends Equatable {
  final List<CycleStat> cycles;

  const CycleDistribution({required this.cycles});

  @override
  List<Object?> get props => [cycles];
}
