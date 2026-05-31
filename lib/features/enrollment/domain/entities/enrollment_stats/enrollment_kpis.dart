import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/kpi_value.dart';

class EnrollmentKpis extends Equatable {
  final KpiValue totalEnrollments;
  final KpiValue firstEnrollments;
  final KpiValue reEnrollments;
  final KpiValue preEnrollments;
  final KpiValue inProgress;

  const EnrollmentKpis({
    required this.totalEnrollments,
    required this.firstEnrollments,
    required this.reEnrollments,
    required this.preEnrollments,
    required this.inProgress,
  });

  @override
  List<Object?> get props => [
    totalEnrollments,
    firstEnrollments,
    reEnrollments,
    preEnrollments,
    inProgress,
  ];
}
