import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_bucket.dart';

/// Miroir de `TillBucketDto` — une barre de l'axe.
class TillBucketModel {
  final String key;
  final int total;
  final int fees;
  final int boutique;
  final bool isCurrent;

  const TillBucketModel({
    required this.key,
    required this.total,
    required this.fees,
    required this.boutique,
    required this.isCurrent,
  });

  /// Une barre est un ornement de l'axe : ses montants cèdent à zéro plutôt que
  /// de faire échouer la lecture du total, qui, lui, vit sur le résumé.
  factory TillBucketModel.fromJson(Map<String, dynamic> json) {
    return TillBucketModel(
      key: ((json['key'] as String?) ?? '').trim(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      fees: (json['fees'] as num?)?.toInt() ?? 0,
      boutique: (json['boutique'] as num?)?.toInt() ?? 0,
      isCurrent: (json['isCurrent'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'total': total,
    'fees': fees,
    'boutique': boutique,
    'isCurrent': isCurrent,
  };

  TillBucket toEntity() => TillBucket(
    key: key,
    total: total,
    fees: fees,
    boutique: boutique,
    isCurrent: isCurrent,
  );
}
