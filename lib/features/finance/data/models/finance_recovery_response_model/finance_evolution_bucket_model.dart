import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery/finance_evolution_bucket.dart';

class FinanceEvolutionBucketModel {
  final String key;
  final int value;
  final bool isCurrent;

  const FinanceEvolutionBucketModel({
    required this.key,
    required this.value,
    required this.isCurrent,
  });

  factory FinanceEvolutionBucketModel.fromJson(Map<String, dynamic> json) {
    return FinanceEvolutionBucketModel(
      key: ((json['key'] as String?) ?? '').trim(),
      value: (json['value'] as num?)?.toInt() ?? 0,
      isCurrent: (json['isCurrent'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'value': value,
    'isCurrent': isCurrent,
  };

  FinanceEvolutionBucket toEntity() =>
      FinanceEvolutionBucket(key: key, value: value, isCurrent: isCurrent);
}
