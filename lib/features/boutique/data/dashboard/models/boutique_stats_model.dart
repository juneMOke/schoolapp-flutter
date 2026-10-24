import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_currency_stats_model.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_top_article_model.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';

/// Miroir de la réponse de `GET /api/v1/boutique/stats` (R8).
class BoutiqueStatsModel {
  /// `YYYY-MM-DD`, bornes incluses.
  final String from;
  final String to;
  final String granularity;
  final int saleCount;
  final int previousSaleCount;
  final int articleCount;
  final int previousArticleCount;
  final List<BoutiqueCurrencyStatsModel> byCurrency;
  final List<BoutiqueTopArticleModel> topArticles;

  const BoutiqueStatsModel({
    required this.from,
    required this.to,
    required this.granularity,
    required this.saleCount,
    required this.previousSaleCount,
    required this.articleCount,
    required this.previousArticleCount,
    this.byCurrency = const [],
    this.topArticles = const [],
  });

  /// La fenêtre et les compteurs sont **exigés** : sans eux la réponse ne dit
  /// rien, et `fromJson` lève — le dépôt en fait une erreur serveur plutôt
  /// qu'un tableau de bord vide qui mentirait sur la journée.
  factory BoutiqueStatsModel.fromJson(Map<String, dynamic> json) {
    final from = json['from'] as String;
    final to = json['to'] as String;
    if (DateTime.tryParse(from) == null || DateTime.tryParse(to) == null) {
      throw FormatException('Fenêtre illisible : $from → $to');
    }
    return BoutiqueStatsModel(
      from: from,
      to: to,
      granularity: (json['granularity'] as String?) ?? '',
      saleCount: (json['saleCount'] as num).toInt(),
      previousSaleCount: (json['previousSaleCount'] as num?)?.toInt() ?? 0,
      articleCount: (json['articleCount'] as num).toInt(),
      previousArticleCount:
          (json['previousArticleCount'] as num?)?.toInt() ?? 0,
      byCurrency: [
        for (final raw in (json['byCurrency'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic>)
            BoutiqueCurrencyStatsModel.fromJson(raw),
      ],
      // Un palmarès absent coûte une carte, pas les recettes.
      topArticles: [
        for (final raw in (json['topArticles'] as List<dynamic>? ?? const []))
          if (raw is Map<String, dynamic> && raw['articleId'] is String)
            BoutiqueTopArticleModel.fromJson(raw),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'granularity': granularity,
    'saleCount': saleCount,
    'previousSaleCount': previousSaleCount,
    'articleCount': articleCount,
    'previousArticleCount': previousArticleCount,
    'byCurrency': [for (final block in byCurrency) block.toJson()],
    'topArticles': [for (final article in topArticles) article.toJson()],
  };

  BoutiqueStats toEntity() => BoutiqueStats(
    window: DashboardWindow(from: DateTime.parse(from), to: DateTime.parse(to)),
    granularity: StatsGranularity.fromWire(granularity),
    saleCount: saleCount,
    previousSaleCount: previousSaleCount,
    articleCount: articleCount,
    previousArticleCount: previousArticleCount,
    byCurrency: [for (final block in byCurrency) block.toEntity()],
    topArticles: [for (final article in topArticles) article.toEntity()],
  );
}
