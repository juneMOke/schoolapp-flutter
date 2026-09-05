import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/evolution_bucket_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/enrollment_evolution.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/evolution_granularity.dart';

class EnrollmentEvolutionModel {
  final String granularity;
  final int currentBucketIndex;
  final String? axisStart;
  final String? axisEnd;
  final List<EvolutionBucketModel> buckets;

  const EnrollmentEvolutionModel({
    required this.granularity,
    required this.currentBucketIndex,
    this.axisStart,
    this.axisEnd,
    required this.buckets,
  });

  factory EnrollmentEvolutionModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentEvolutionModel(
      granularity: json['granularity'] as String,
      currentBucketIndex: (json['currentBucketIndex'] as num).toInt(),
      axisStart: json['axisStart'] as String?,
      axisEnd: json['axisEnd'] as String?,
      buckets: (json['buckets'] as List<dynamic>)
          .map(
            (bucket) =>
                EvolutionBucketModel.fromJson(bucket as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'granularity': granularity,
    'currentBucketIndex': currentBucketIndex,
    'axisStart': axisStart,
    'axisEnd': axisEnd,
    'buckets': buckets.map((bucket) => bucket.toJson()).toList(growable: false),
  };

  EnrollmentEvolution toEntity() => EnrollmentEvolution(
    granularity: _parseGranularity(granularity),
    currentBucketIndex: currentBucketIndex,
    axisStart: _parseDate(axisStart),
    axisEnd: _parseDate(axisEnd),
    buckets: buckets.map((bucket) => bucket.toEntity()).toList(growable: false),
  );

  /// `2026-09-01` → date. Nulle si le serveur ne la porte pas : l'axe est une
  /// information d'appoint, son absence ne doit pas faire échouer la lecture.
  static DateTime? _parseDate(String? value) =>
      value == null ? null : DateTime.tryParse(value);

  EvolutionGranularity _parseGranularity(String value) => switch (value) {
    'week' => EvolutionGranularity.week,
    'day' => EvolutionGranularity.day,
    _ => EvolutionGranularity.month,
  };
}
