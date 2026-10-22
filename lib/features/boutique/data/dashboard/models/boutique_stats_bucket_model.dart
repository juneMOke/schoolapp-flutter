import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';

/// Miroir d'un seau de `buckets[]`.
class BoutiqueStatsBucketModel {
  final String key;
  final int total;

  const BoutiqueStatsBucketModel({required this.key, required this.total});

  /// Une barre est un ornement de l'axe : son montant cède à zéro plutôt que
  /// de faire échouer la lecture des recettes, qui vivent sur le bloc.
  factory BoutiqueStatsBucketModel.fromJson(Map<String, dynamic> json) =>
      BoutiqueStatsBucketModel(
        key: ((json['key'] as String?) ?? '').trim(),
        total: (json['total'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'key': key, 'total': total};

  BoutiqueStatsBucket toEntity() => BoutiqueStatsBucket(key: key, total: total);
}
