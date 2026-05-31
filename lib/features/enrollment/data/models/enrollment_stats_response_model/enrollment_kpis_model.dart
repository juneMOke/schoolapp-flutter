import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/kpi_value_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/enrollment_kpis.dart';

class EnrollmentKpisModel {
  final KpiValueModel totalEnrollments;
  final KpiValueModel firstEnrollments;
  final KpiValueModel reEnrollments;
  final KpiValueModel preEnrollments;
  final KpiValueModel inProgress;

  const EnrollmentKpisModel({
    required this.totalEnrollments,
    required this.firstEnrollments,
    required this.reEnrollments,
    required this.preEnrollments,
    required this.inProgress,
  });

  factory EnrollmentKpisModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentKpisModel(
      totalEnrollments: KpiValueModel.fromJson(
        json['totalEnrollments'] as Map<String, dynamic>,
      ),
      firstEnrollments: KpiValueModel.fromJson(
        json['firstEnrollments'] as Map<String, dynamic>,
      ),
      reEnrollments: KpiValueModel.fromJson(
        json['reEnrollments'] as Map<String, dynamic>,
      ),
      preEnrollments: KpiValueModel.fromJson(
        json['preEnrollments'] as Map<String, dynamic>,
      ),
      inProgress: KpiValueModel.fromJson(
        json['inProgress'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'totalEnrollments': totalEnrollments.toJson(),
    'firstEnrollments': firstEnrollments.toJson(),
    'reEnrollments': reEnrollments.toJson(),
    'preEnrollments': preEnrollments.toJson(),
    'inProgress': inProgress.toJson(),
  };

  EnrollmentKpis toEntity() => EnrollmentKpis(
    totalEnrollments: totalEnrollments.toEntity(),
    firstEnrollments: firstEnrollments.toEntity(),
    reEnrollments: reEnrollments.toEntity(),
    preEnrollments: preEnrollments.toEntity(),
    inProgress: inProgress.toEntity(),
  );
}
