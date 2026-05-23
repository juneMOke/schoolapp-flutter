import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/evolution_bucket_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/enrollment_evolution.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/evolution_granularity.dart';

class EnrollmentEvolutionModel {
  final String granularity;
  final int currentBucketIndex;
  final List<EvolutionBucketModel> buckets;

  const EnrollmentEvolutionModel({
    required this.granularity,
    required this.currentBucketIndex,
    required this.buckets,
  });

  factory EnrollmentEvolutionModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentEvolutionModel(
      granularity: json['granularity'] as String,
      currentBucketIndex: (json['currentBucketIndex'] as num).toInt(),
      buckets: (json['buckets'] as List<dynamic>)
          .map(
            (bucket) => EvolutionBucketModel.fromJson(
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

  EnrollmentEvolution toEntity() => EnrollmentEvolution(
    granularity: _parseGranularity(granularity),
    currentBucketIndex: currentBucketIndex,
    buckets: buckets.map((bucket) => bucket.toEntity()).toList(growable: false),
  );

  EvolutionGranularity _parseGranularity(String value) => switch (value) {
    'week' => EvolutionGranularity.week,
    'day' => EvolutionGranularity.day,
    _ => EvolutionGranularity.month,
  };
}
