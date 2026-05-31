import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/cycle_stat_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/cycle_distribution.dart';

class CycleDistributionModel {
  final List<CycleStatModel> cycles;

  const CycleDistributionModel({required this.cycles});

  factory CycleDistributionModel.fromJson(Map<String, dynamic> json) {
    return CycleDistributionModel(
      cycles: (json['cycles'] as List<dynamic>)
          .map((item) => CycleStatModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'cycles': cycles.map((cycle) => cycle.toJson()).toList(growable: false),
  };

  CycleDistribution toEntity() => CycleDistribution(
    cycles: cycles.map((cycle) => cycle.toEntity()).toList(growable: false),
  );
}
