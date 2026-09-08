import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_best_bucket_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_bucket_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_classroom_amount_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_summary_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_currency_block.dart';

/// Miroir de `TillCurrencyStatsDto` — la caisse d'une devise.
class TillCurrencyBlockModel {
  final String currency;
  final TillSummaryModel summary;
  final List<TillBucketModel> buckets;
  final List<TillClassroomAmountModel> byClassroom;
  final int unassignedAmount;
  final TillBestBucketModel? bestBucket;

  const TillCurrencyBlockModel({
    required this.currency,
    required this.summary,
    required this.buckets,
    this.byClassroom = const [],
    this.unassignedAmount = 0,
    this.bestBucket,
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
      // Un palmarès absent coûte une carte, pas un montant.
      byClassroom: [
        for (final raw in (json['byClassroom'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>)
            TillClassroomAmountModel.fromJson(raw),
      ],
      // Cède à zéro — mais zéro veut dire ici « rien d'inattribuable », ce qui
      // est une affirmation juste : la carte n'ajoutera alors aucune mention.
      unassignedAmount: (json['unassignedAmount'] as num?)?.toInt() ?? 0,
      bestBucket: TillBestBucketModel.fromJsonOrNull(json['bestBucket']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'currency': currency,
    'summary': summary.toJson(),
    'buckets': buckets.map((bucket) => bucket.toJson()).toList(growable: false),
    'byClassroom': [for (final row in byClassroom) row.toJson()],
    'unassignedAmount': unassignedAmount,
    'bestBucket': bestBucket?.toJson(),
  };

  TillCurrencyBlock toEntity() => TillCurrencyBlock(
    currency: currency,
    summary: summary.toEntity(),
    buckets: buckets.map((bucket) => bucket.toEntity()).toList(growable: false),
    byClassroom: [for (final row in byClassroom) row.toEntity()],
    unassignedAmount: unassignedAmount,
    bestBucket: bestBucket?.toEntity(),
  );
}
