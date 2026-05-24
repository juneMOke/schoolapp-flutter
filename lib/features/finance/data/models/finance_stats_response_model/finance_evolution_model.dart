import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model/finance_evolution_bucket_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_evolution.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats/finance_evolution_granularity.dart';

class FinanceEvolutionModel {
  final String granularity;
  final int currentBucketIndex;
  final List<FinanceEvolutionBucketModel> buckets;

  const FinanceEvolutionModel({
    required this.granularity,
    required this.currentBucketIndex,
    required this.buckets,
  });

  factory FinanceEvolutionModel.fromJson(Map<String, dynamic> json) {
    return FinanceEvolutionModel(
      granularity: json['granularity'] as String,
      currentBucketIndex: (json['currentBucketIndex'] as num).toInt(),
      buckets: (json['buckets'] as List<dynamic>)
          .map(
            (bucket) => FinanceEvolutionBucketModel.fromJson(
              bucket as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'granularity': granularity,
    'currentBucketIndex': currentBucketIndex,
    'buckets': buckets.map((bucket) => bucket.toJson()).toList(growable: false),
  };

  FinanceEvolution toEntity() => FinanceEvolution(
    granularity: _parseGranularity(granularity),
    currentBucketIndex: currentBucketIndex,
    buckets: buckets.map((bucket) => bucket.toEntity()).toList(growable: false),
  );

  FinanceEvolutionGranularity _parseGranularity(String value) => switch (value) {
    'week' => FinanceEvolutionGranularity.week,
    'day' => FinanceEvolutionGranularity.day,
    _ => FinanceEvolutionGranularity.month,
  };
}
