import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_family_amount_model.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_stats_bucket_model.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_currency_stats.dart';

/// Miroir d'une entrée de `byCurrency[]` — ce qui s'est vendu dans une devise.
class BoutiqueCurrencyStatsModel {
  final String currency;
  final int revenue;
  final int previousRevenue;
  final int saleCount;
  final int previousSaleCount;
  final List<BoutiqueStatsBucketModel> buckets;
  final List<BoutiqueFamilyAmountModel> families;

  const BoutiqueCurrencyStatsModel({
    required this.currency,
    required this.revenue,
    required this.previousRevenue,
    required this.saleCount,
    required this.previousSaleCount,
    this.buckets = const [],
    this.families = const [],
  });

  /// Les recettes sont **exigées** : un bloc sans montant n'a rien à dire, et
  /// le lire comme zéro afficherait une journée blanche qui ne l'a pas été.
  /// La série et les familles cèdent au vide — elles ornent, elles ne
  /// comptent pas.
  factory BoutiqueCurrencyStatsModel.fromJson(Map<String, dynamic> json) =>
      BoutiqueCurrencyStatsModel(
        // Normalisée, jamais refusée : même règle que la caisse Finances.
        currency: ((json['currency'] as String?) ?? '').trim().toUpperCase(),
        revenue: (json['revenue'] as num).toInt(),
        previousRevenue: (json['previousRevenue'] as num?)?.toInt() ?? 0,
        saleCount: (json['saleCount'] as num?)?.toInt() ?? 0,
        previousSaleCount: (json['previousSaleCount'] as num?)?.toInt() ?? 0,
        buckets: [
          for (final raw in (json['buckets'] as List<dynamic>? ?? const []))
            if (raw is Map<String, dynamic>)
              BoutiqueStatsBucketModel.fromJson(raw),
        ],
        families: [
          for (final raw in (json['families'] as List<dynamic>? ?? const []))
            if (raw is Map<String, dynamic>)
              BoutiqueFamilyAmountModel.fromJson(raw),
        ],
      );

  Map<String, dynamic> toJson() => {
    'currency': currency,
    'revenue': revenue,
    'previousRevenue': previousRevenue,
    'saleCount': saleCount,
    'previousSaleCount': previousSaleCount,
    'buckets': [for (final bucket in buckets) bucket.toJson()],
    'families': [for (final family in families) family.toJson()],
  };

  BoutiqueCurrencyStats toEntity() => BoutiqueCurrencyStats(
    currency: currency,
    revenue: revenue,
    previousRevenue: previousRevenue,
    saleCount: saleCount,
    previousSaleCount: previousSaleCount,
    buckets: [for (final bucket in buckets) bucket.toEntity()],
    families: [for (final family in families) family.toEntity()],
  );
}
