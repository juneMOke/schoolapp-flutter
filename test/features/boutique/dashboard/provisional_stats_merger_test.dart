import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/dashboard/provisional_stats_merger.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_currency_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_family_amount.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sale_line.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/provisional_sales.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';

BoutiqueStats _stats({
  StatsGranularity granularity = StatsGranularity.day,
  DashboardWindow? window,
  List<BoutiqueCurrencyStats>? byCurrency,
}) => BoutiqueStats(
  window:
      window ??
      DashboardWindow(from: DateTime(2026, 10, 19), to: DateTime(2026, 10, 21)),
  granularity: granularity,
  saleCount: 3,
  previousSaleCount: 2,
  articleCount: 5,
  previousArticleCount: 4,
  byCurrency:
      byCurrency ??
      const [
        BoutiqueCurrencyStats(
          currency: 'USD',
          revenue: 6000,
          previousRevenue: 4000,
          saleCount: 3,
          previousSaleCount: 2,
          buckets: [
            BoutiqueStatsBucket(key: '2026-10-19', total: 1000),
            BoutiqueStatsBucket(key: '2026-10-20', total: 2000),
            BoutiqueStatsBucket(key: '2026-10-21', total: 3000),
          ],
          families: [
            BoutiqueFamilyAmount(
              family: ArticleFamily.uniforme,
              amount: 6000,
              quantity: 5,
            ),
          ],
        ),
      ],
);

ProvisionalSaleLine _line({
  String saleId = 'p-1',
  DateTime? soldAt,
  String currency = 'USD',
  int total = 500,
  int quantity = 1,
  ArticleFamily? family = ArticleFamily.fournitures,
}) => ProvisionalSaleLine(
  saleId: saleId,
  // 10 h à Kinshasa le 21.
  soldAt: soldAt ?? DateTime.utc(2026, 10, 21, 9),
  currency: currency,
  lineTotal: total,
  quantity: quantity,
  family: family,
);

/// Les tickets provisoires du poste, AJOUTÉS aux chiffres du serveur.
void main() {
  test('sans ticket, les chiffres du serveur sont rendus tels quels', () {
    final stats = _stats();
    expect(
      ProvisionalStatsMerger.merge(stats, ProvisionalSales.none),
      same(stats),
    );
  });

  test('compteurs, recettes, seau du jour et familles absorbent le ticket', () {
    final merged = ProvisionalStatsMerger.merge(
      _stats(),
      ProvisionalSales([
        _line(saleId: 'p-1', total: 500, quantity: 1),
        _line(
          saleId: 'p-1',
          total: 300,
          quantity: 2,
          family: ArticleFamily.uniforme,
        ),
      ]),
    );

    // Une vente, deux lignes : un ticket.
    expect(merged.saleCount, 4);
    expect(merged.articleCount, 8);
    final usd = merged.blockOf('USD')!;
    expect(usd.revenue, 6800);
    expect(usd.saleCount, 4);
    expect(usd.buckets.last.total, 3800);
    expect(usd.buckets.first.total, 1000);
    // Ordre du catalogue : Uniforme avant Fournitures.
    expect(usd.families.map((f) => f.family), [
      ArticleFamily.uniforme,
      ArticleFamily.fournitures,
    ]);
    expect(usd.families.first.amount, 6300);
    expect(usd.families.first.quantity, 7);
    // Le palmarès ne se recalcule pas sans la liste complète.
    expect(merged.topArticles, isEmpty);
    // Le précédent n'est pas touché : les provisoires sont d'aujourd'hui.
    expect(merged.previousSaleCount, 2);
    expect(usd.previousRevenue, 4000);
  });

  test('une devise inconnue du serveur fait naître un bloc à série dense', () {
    final merged = ProvisionalStatsMerger.merge(
      _stats(),
      ProvisionalSales([_line(currency: 'cdf', total: 900000)]),
    );
    expect(merged.byCurrency.map((b) => b.currency), ['CDF', 'USD']);
    final cdf = merged.blockOf('CDF')!;
    expect(cdf.buckets.map((b) => b.key), [
      '2026-10-19',
      '2026-10-20',
      '2026-10-21',
    ]);
    expect(cdf.buckets.map((b) => b.total), [0, 0, 900000]);
    expect(cdf.saleCount, 1);
  });

  test('un ticket hors de la fenêtre comptée par le serveur est ignoré', () {
    // 0 h 30 le 22 à Kinshasa : la photo de cache d'hier ne l'absorbe pas.
    final merged = ProvisionalStatsMerger.merge(
      _stats(),
      ProvisionalSales([_line(soldAt: DateTime.utc(2026, 10, 21, 23, 30))]),
    );
    expect(merged.saleCount, 3);
  });

  test('heure par heure : le ticket tombe dans l\'heure de Kinshasa', () {
    final day = DateTime(2026, 10, 21);
    final merged = ProvisionalStatsMerger.merge(
      _stats(
        granularity: StatsGranularity.hour,
        window: DashboardWindow(from: day, to: day),
        byCurrency: [
          BoutiqueCurrencyStats(
            currency: 'USD',
            revenue: 0,
            previousRevenue: 0,
            saleCount: 0,
            previousSaleCount: 0,
            buckets: [
              for (var h = 0; h < 24; h++)
                BoutiqueStatsBucket(
                  key: '2026-10-21T${h.toString().padLeft(2, '0')}',
                  total: 0,
                ),
            ],
          ),
        ],
      ),
      // 9 h UTC = 10 h à Kinshasa.
      ProvisionalSales([_line(total: 700)]),
    );
    final buckets = merged.blockOf('USD')!.buckets;
    expect(buckets.firstWhere((b) => b.total > 0).key, '2026-10-21T10');
  });

  test('une famille inconnue se range en dernier, sans disparaître', () {
    final merged = ProvisionalStatsMerger.merge(
      _stats(),
      ProvisionalSales([_line(family: null, total: 100)]),
    );
    final families = merged.blockOf('USD')!.families;
    expect(families.last.family, isNull);
    expect(families.last.amount, 100);
  });
}
