import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/evolution_bucket.dart';

class EvolutionBucketModel {
  final String key;
  final int value;
  final bool isCurrent;

  const EvolutionBucketModel({
    required this.key,
    required this.value,
    required this.isCurrent,
  });

  factory EvolutionBucketModel.fromJson(Map<String, dynamic> json) {
    return EvolutionBucketModel(
      key: json['key'] as String,
      value: (json['value'] as num).toInt(),
      isCurrent: json['isCurrent'] as bool,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'value': value,
    'isCurrent': isCurrent,
  };

  EvolutionBucket toEntity() =>
      EvolutionBucket(key: key, value: value, isCurrent: isCurrent);
}
