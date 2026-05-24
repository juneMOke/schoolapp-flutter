import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/fee_type_distribution_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/finance_evolution_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/finance_kpis_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/stats_context_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_stats.dart';

class FinanceStatsResponseModel {
  final StatsContextModel context;
  final FinanceKpisModel kpis;
  final FinanceEvolutionModel evolution;
  final FeeTypeDistributionModel distributionByFeeType;

  const FinanceStatsResponseModel({
    required this.context,
    required this.kpis,
    required this.evolution,
    required this.distributionByFeeType,
  });

  factory FinanceStatsResponseModel.fromJson(Map<String, dynamic> json) {
    return FinanceStatsResponseModel(
      context: StatsContextModel.fromJson(json['context'] as Map<String, dynamic>),
      kpis: FinanceKpisModel.fromJson(json['kpis'] as Map<String, dynamic>),
      evolution: FinanceEvolutionModel.fromJson(
        json['evolution'] as Map<String, dynamic>,
      ),
      distributionByFeeType: FeeTypeDistributionModel.fromJson(
        json['distributionByFeeType'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'context': context.toJson(),
    'kpis': kpis.toJson(),
    'evolution': evolution.toJson(),
    'distributionByFeeType': distributionByFeeType.toJson(),
  };

  FinanceStats toEntity() => FinanceStats(
    context: context.toEntity(),
    kpis: kpis.toEntity(),
    evolution: evolution.toEntity(),
    distributionByFeeType: distributionByFeeType.toEntity(),
  );
}
