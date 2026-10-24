import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_currency_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_top_article.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';

/// « Combien la boutique a-t-elle vendu, et quoi ? » sur une fenêtre — la
/// réponse de `GET /boutique/stats`.
///
/// Un flux, jamais un stock ni une dette : la boutique vend au comptant.
class BoutiqueStats extends Equatable {
  /// La fenêtre **que le serveur a comptée** — celle qu'il dit, pas celle que
  /// le client a demandée. Les deux coïncident ; si elles divergeaient, c'est
  /// la première que l'écran doit écrire.
  final DashboardWindow window;

  final StatsGranularity granularity;

  /// Reçus, toutes devises.
  final int saleCount;
  final int previousSaleCount;

  /// Σ des quantités, toutes devises.
  final int articleCount;
  final int previousArticleCount;

  /// Une entrée par devise de catalogue, **jamais additionnées**. Vide sur une
  /// fenêtre sans vente.
  final List<BoutiqueCurrencyStats> byCurrency;

  /// Cinq au plus, toutes devises.
  final List<BoutiqueTopArticle> topArticles;

  const BoutiqueStats({
    required this.window,
    required this.granularity,
    required this.saleCount,
    required this.previousSaleCount,
    required this.articleCount,
    required this.previousArticleCount,
    this.byCurrency = const [],
    this.topArticles = const [],
  });

  bool get hasSales => saleCount > 0;

  /// Le bloc d'une devise, `null` si la fenêtre n'en a rien vendu.
  BoutiqueCurrencyStats? blockOf(String? currency) {
    for (final block in byCurrency) {
      if (block.currency == currency) return block;
    }
    return null;
  }

  BoutiqueStats copyWith({
    int? saleCount,
    int? articleCount,
    List<BoutiqueCurrencyStats>? byCurrency,
  }) => BoutiqueStats(
    window: window,
    granularity: granularity,
    saleCount: saleCount ?? this.saleCount,
    previousSaleCount: previousSaleCount,
    articleCount: articleCount ?? this.articleCount,
    previousArticleCount: previousArticleCount,
    byCurrency: byCurrency ?? this.byCurrency,
    topArticles: topArticles,
  );

  @override
  List<Object?> get props => [
    window,
    granularity,
    saleCount,
    previousSaleCount,
    articleCount,
    previousArticleCount,
    byCurrency,
    topArticles,
  ];
}
