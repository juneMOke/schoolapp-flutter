import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/cycle_distribution_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/enrollment_evolution_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/enrollment_kpis_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/gender_distribution_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/stats_context_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/enrollment_stats.dart';

class EnrollmentStatsResponseModel {
  final StatsContextModel context;
  final EnrollmentKpisModel kpis;
  final EnrollmentEvolutionModel evolution;
  final CycleDistributionModel distributionByCycle;
  final GenderDistributionModel distributionByGender;

  const EnrollmentStatsResponseModel({
    required this.context,
    required this.kpis,
    required this.evolution,
    required this.distributionByCycle,
    required this.distributionByGender,
  });

  factory EnrollmentStatsResponseModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentStatsResponseModel(
      context: StatsContextModel.fromJson(json['context'] as Map<String, dynamic>),
      kpis: EnrollmentKpisModel.fromJson(json['kpis'] as Map<String, dynamic>),
      evolution: EnrollmentEvolutionModel.fromJson(
        json['evolution'] as Map<String, dynamic>,
      ),
      distributionByCycle: CycleDistributionModel.fromJson(
        json['distributionByCycle'] as Map<String, dynamic>,
      ),
      distributionByGender: GenderDistributionModel.fromJson(
        json['distributionByGender'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'context': context.toJson(),
    'kpis': kpis.toJson(),
    'evolution': evolution.toJson(),
    'distributionByCycle': distributionByCycle.toJson(),
    'distributionByGender': distributionByGender.toJson(),
  };

  EnrollmentStats toEntity() => EnrollmentStats(
    context: context.toEntity(),
    kpis: kpis.toEntity(),
    evolution: evolution.toEntity(),
    distributionByCycle: distributionByCycle.toEntity(),
    distributionByGender: distributionByGender.toEntity(),
  );
}
