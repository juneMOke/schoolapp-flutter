import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/entities/stats_context.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/cycle_distribution.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/enrollment_evolution.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/enrollment_kpis.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/gender_distribution.dart';

class EnrollmentStats extends Equatable {
  final StatsContext context;
  final EnrollmentKpis kpis;
  final EnrollmentEvolution evolution;
  final CycleDistribution distributionByCycle;
  final GenderDistribution distributionByGender;

  const EnrollmentStats({
    required this.context,
    required this.kpis,
    required this.evolution,
    required this.distributionByCycle,
    required this.distributionByGender,
  });

  @override
  List<Object?> get props => [
    context,
    kpis,
    evolution,
    distributionByCycle,
    distributionByGender,
  ];
}
