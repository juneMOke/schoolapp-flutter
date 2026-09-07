import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/cycle_distribution_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/enrollment_evolution_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/enrollment_kpis_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/gender_distribution_model.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/stats_context_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/enrollment_stats.dart';

class EnrollmentStatsResponseModel {
  final StatsContextModel context;
  final GenderDistributionModel headcount;
  final EnrollmentKpisModel kpis;
  final EnrollmentEvolutionModel evolution;
  final CycleDistributionModel distributionByCycle;
  final GenderDistributionModel distributionByGender;

  const EnrollmentStatsResponseModel({
    required this.context,
    required this.headcount,
    required this.kpis,
    required this.evolution,
    required this.distributionByCycle,
    required this.distributionByGender,
  });

  factory EnrollmentStatsResponseModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentStatsResponseModel(
      context: StatsContextModel.fromJson(
        json['context'] as Map<String, dynamic>,
      ),
      // Le serveur le sérialise TOUJOURS, à zéro s'il n'y a rien — c'est ce
      // qui permet au bandeau de rester en repère de lecture à l'état vide.
      // Le repli à zéro protège seulement d'une charge utile plus ancienne.
      headcount: json['headcount'] == null
          ? const GenderDistributionModel(total: 0, segments: [])
          : GenderDistributionModel.fromJson(
              json['headcount'] as Map<String, dynamic>,
            ),
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
    'headcount': headcount.toJson(),
    'kpis': kpis.toJson(),
    'evolution': evolution.toJson(),
    'distributionByCycle': distributionByCycle.toJson(),
    'distributionByGender': distributionByGender.toJson(),
  };

  EnrollmentStats toEntity() => EnrollmentStats(
    context: context.toEntity(),
    headcount: headcount.toEntity(),
    kpis: kpis.toEntity(),
    evolution: evolution.toEntity(),
    distributionByCycle: distributionByCycle.toEntity(),
    distributionByGender: distributionByGender.toEntity(),
  );
}
