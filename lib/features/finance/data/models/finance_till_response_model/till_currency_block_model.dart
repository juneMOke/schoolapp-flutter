import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_bucket_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_summary_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_currency_block.dart';

/// Miroir de `TillCurrencyStatsDto` — la caisse d'une devise.
class TillCurrencyBlockModel {
  final String currency;
  final TillSummaryModel summary;
  final List<TillBucketModel> buckets;

  const TillCurrencyBlockModel({
    required this.currency,
    required this.summary,
    required this.buckets,
  });

  factory TillCurrencyBlockModel.fromJson(Map<String, dynamic> json) {
    return TillCurrencyBlockModel(
      // Normalisée, jamais refusée : même règle que le recouvrement.
      currency: ((json['currency'] as String?) ?? '').trim().toUpperCase(),
      summary: TillSummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      // L'axe est un ornement : un axe absent rend un graphique vide, jamais
      // une erreur qui emporterait le total du tiroir avec elle.
      buckets: [
        for (final raw in (json['buckets'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>) TillBucketModel.fromJson(raw),
      ],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currency': currency,
    'summary': summary.toJson(),
    'buckets': buckets.map((bucket) => bucket.toJson()).toList(growable: false),
  };

  TillCurrencyBlock toEntity() => TillCurrencyBlock(
    currency: currency,
    summary: summary.toEntity(),
    buckets: buckets.map((bucket) => bucket.toEntity()).toList(growable: false),
  );
}
