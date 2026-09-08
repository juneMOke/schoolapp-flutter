import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_best_bucket.dart';

/// Miroir de `TillBestBucketDto` — l'intervalle le plus fort de la série.
class TillBestBucketModel {
  final String key;
  final int amount;
  final int sharePercent;

  const TillBestBucketModel({
    required this.key,
    required this.amount,
    required this.sharePercent,
  });

  /// **`null` en entrée, `null` en sortie.** Le serveur rend `null` sur une
  /// caisse creuse — elle n'a pas de meilleur jour — et cette absence doit
  /// traverser la couche de données intacte : un repli sur un objet à zéro
  /// afficherait une carte annonçant une pointe à `0 %`, c'est-à-dire la
  /// mensonge que le `null` existe pour éviter.
  static TillBestBucketModel? fromJsonOrNull(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return TillBestBucketModel(
      key: ((raw['key'] as String?) ?? '').trim(),
      amount: (raw['amount'] as num?)?.toInt() ?? 0,
      sharePercent: (raw['sharePercent'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'key': key,
    'amount': amount,
    'sharePercent': sharePercent,
  };

  TillBestBucket toEntity() =>
      TillBestBucket(key: key, amount: amount, sharePercent: sharePercent);
}
