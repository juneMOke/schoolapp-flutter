import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/enrollment_stats_period.dart';

class StatsContext extends Equatable {
  final String schoolYear;
  final EnrollmentStatsPeriod period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime generatedAt;

  const StatsContext({
    required this.schoolYear,
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
    schoolYear,
    period,
    periodStart,
    periodEnd,
    generatedAt,
  ];
}
