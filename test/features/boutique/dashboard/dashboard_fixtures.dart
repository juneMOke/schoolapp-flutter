import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiary_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiary_class.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiaries_page.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiary.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_currency_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_family_amount.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_top_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';

/// Mardi 21 octobre 2026, 14 h 30 à Kinshasa.
final dashboardNow = DateTime.utc(2026, 10, 21, 13, 30);

final sevenDays = DashboardWindow(
  from: DateTime(2026, 10, 15),
  to: DateTime(2026, 10, 21),
);

BoutiqueStats statsOf({
  DashboardWindow? window,
  int saleCount = 61,
  List<String> currencies = const ['USD'],
  bool withTop = true,
}) {
  final w = window ?? sevenDays;
  return BoutiqueStats(
    window: w,
    granularity: w.isSingleDay ? StatsGranularity.hour : StatsGranularity.day,
    saleCount: saleCount,
    previousSaleCount: 55,
    articleCount: 97,
    previousArticleCount: 88,
    byCurrency: [
      for (final currency in currencies)
        BoutiqueCurrencyStats(
          currency: currency,
          revenue: saleCount == 0 ? 0 : 128400,
          previousRevenue: 110200,
          saleCount: saleCount,
          previousSaleCount: 53,
          buckets: [
            for (var i = 0; i < w.dayCount; i++)
              BoutiqueStatsBucket(
                key: '2026-10-${(w.from.day + i).toString().padLeft(2, '0')}',
                total: saleCount == 0 ? 0 : 18600,
              ),
          ],
          families: const [
            BoutiqueFamilyAmount(
              family: ArticleFamily.uniforme,
              amount: 74200,
              quantity: 41,
            ),
            BoutiqueFamilyAmount(
              family: ArticleFamily.fournitures,
              amount: 28000,
              quantity: 34,
            ),
          ],
        ),
    ],
    topArticles: withTop
        ? [
            BoutiqueTopArticle(
              articleId: 'a-polo',
              label: 'Polo Lacoste',
              family: ArticleFamily.uniforme,
              quantity: 18,
              amounts: MoneyBag.of(const [Money(23000, 'USD')]),
            ),
          ]
        : const [],
  );
}

BoutiqueBeneficiariesPage beneficiariesOf({
  int count = 2,
  int total = 2,
  int page = 0,
  int size = 100,
}) => BoutiqueBeneficiariesPage(
  totalElements: total,
  page: page,
  size: size,
  classes: const [BeneficiaryClass(id: 'c-6a', label: '6e A')],
  walkInLineCount: 3,
  items: [
    for (var i = 0; i < count; i++)
      BoutiqueBeneficiary(
        studentId: 's-$page-$i',
        fullName: 'KABONGO Daniel $i',
        classId: 'c-6a',
        classLabel: '6e A',
        lastPurchaseAt: DateTime.utc(2026, 10, 21, 9),
        amounts: MoneyBag.of(const [Money(2000, 'USD')]),
        articles: const [
          BeneficiaryArticle(
            articleId: 'a-polo',
            label: 'Polo Lacoste',
            family: ArticleFamily.uniforme,
            quantity: 2,
            sizes: ['M'],
          ),
        ],
      ),
  ],
);

SaleHistoryEntry saleEntry(String id, {String status = 'SYNCED'}) =>
    SaleHistoryEntry(
      id: id,
      payerName: 'Ndombo Lelo Willy',
      amounts: MoneyBag.of(const [Money(1500, 'USD')]),
      soldAt: '2026-10-21T09:00:00Z',
      syncStatus: status,
      receiptNumber: status == 'SYNCED' ? 'RV-000472' : null,
      articleCount: 2,
    );
