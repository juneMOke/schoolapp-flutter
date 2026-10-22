import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_beneficiaries_page_model.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_stats_model.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';

/// L'exemple du contrat figé (réponse du back, 2026-10-21).
Map<String, dynamic> _statsJson() => {
  'from': '2026-10-15',
  'to': '2026-10-21',
  'timeZone': 'Africa/Kinshasa',
  'granularity': 'DAY',
  'saleCount': 61,
  'previousSaleCount': 55,
  'articleCount': 97,
  'previousArticleCount': 88,
  'byCurrency': [
    {
      'currency': 'usd',
      'revenue': 128400,
      'previousRevenue': 110200,
      'saleCount': 58,
      'previousSaleCount': 53,
      'buckets': [
        {'key': '2026-10-15', 'total': 18600},
      ],
      'families': [
        {'family': 'UNIFORME', 'amount': 74200, 'quantity': 41},
        {'family': 'BIJOUX', 'amount': 100, 'quantity': 1},
      ],
    },
  ],
  'topArticles': [
    {
      'articleId': 'a-jdc',
      'label': 'Journal de classe',
      'family': 'FOURNITURES',
      'quantity': 22,
      'amounts': [
        {'amount': 11000, 'currency': 'USD'},
      ],
    },
  ],
};

Map<String, dynamic> _beneficiariesJson() => {
  'totalElements': 38,
  'page': 0,
  'size': 50,
  'classes': [
    {'id': 'c-6a', 'label': '6e A'},
  ],
  'walkInLineCount': 7,
  'items': [
    {
      'studentId': 's-1',
      'fullName': 'KABONGO Daniel',
      'classId': null,
      'classLabel': null,
      'lastPurchaseAt': '2026-10-21T09:42:00Z',
      'amounts': [
        {'amount': 2000, 'currency': 'USD'},
      ],
      'articles': [
        {
          'articleId': 'a-polo',
          'label': 'Polo Lacoste',
          'family': 'UNIFORME',
          'quantity': 2,
          'sizes': ['M', ' '],
        },
      ],
    },
  ],
};

void main() {
  group('R8 — stats', () {
    test('lit l\'exemple du contrat', () {
      final stats = BoutiqueStatsModel.fromJson(_statsJson()).toEntity();
      expect(stats.window.dayCount, 7);
      expect(stats.granularity, StatsGranularity.day);
      expect(stats.saleCount, 61);
      final usd = stats.blockOf('USD')!;
      expect(usd.revenue, 128400);
      expect(usd.averageBasket, 2214); // 128400 / 58 = 2213,79
      expect(usd.families.first.family, ArticleFamily.uniforme);
      expect(
        stats.topArticles.single.amounts.amountIn('USD'),
        const Money(11000, 'USD'),
      );
    });

    test('une famille inconnue reste comptée, sans famille', () {
      final usd = BoutiqueStatsModel.fromJson(
        _statsJson(),
      ).toEntity().blockOf('USD')!;
      expect(usd.families.last.family, isNull);
      expect(usd.families.last.amount, 100);
    });

    test('une fenêtre vide est une réponse, pas une erreur', () {
      final stats = BoutiqueStatsModel.fromJson({
        'from': '2026-10-21',
        'to': '2026-10-21',
        'granularity': 'HOUR',
        'saleCount': 0,
        'articleCount': 0,
        'byCurrency': [],
        'topArticles': [],
      }).toEntity();
      expect(stats.hasSales, isFalse);
      expect(stats.granularity, StatsGranularity.hour);
    });

    test('sans fenêtre ni compteurs, la lecture lève', () {
      expect(
        () => BoutiqueStatsModel.fromJson({'saleCount': 1}),
        throwsA(anything),
      );
      expect(
        () => BoutiqueStatsModel.fromJson({..._statsJson(), 'from': 'hier'}),
        throwsFormatException,
      );
    });

    test('le cache relit exactement ce qu\'il a écrit', () {
      final model = BoutiqueStatsModel.fromJson(_statsJson());
      expect(
        BoutiqueStatsModel.fromJson(model.toJson()).toEntity(),
        model.toEntity(),
      );
    });
  });

  group('R9 — bénéficiaires', () {
    test('lit l\'exemple du contrat, élève non placé compris', () {
      final page = BoutiqueBeneficiariesPageModel.fromJson(
        _beneficiariesJson(),
      ).toEntity();
      expect(page.totalElements, 38);
      expect(page.walkInLineCount, 7);
      final student = page.items.single;
      expect(student.classId, isNull);
      expect(student.classLabel, isNull);
      expect(student.lastPurchaseAt, DateTime.utc(2026, 10, 21, 9, 42));
      expect(student.articles.single.sizes, ['M']);
      expect(page.hasMore, isFalse);
    });

    test(
      'un élève illisible fait échouer la page plutôt que de fausser le compte',
      () {
        final json = _beneficiariesJson();
        (json['items'] as List).add({'studentId': 's-2'});
        expect(
          () => BoutiqueBeneficiariesPageModel.fromJson(json),
          throwsA(anything),
        );
      },
    );

    test('le cache relit exactement ce qu\'il a écrit', () {
      final model = BoutiqueBeneficiariesPageModel.fromJson(
        _beneficiariesJson(),
      );
      expect(
        BoutiqueBeneficiariesPageModel.fromJson(model.toJson()).toEntity(),
        model.toEntity(),
      );
    });
  });
}
