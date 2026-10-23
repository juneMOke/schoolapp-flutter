import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/dashboard/stats_bucket_keys.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_stats_bucket.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/stats_granularity.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/kpi_delta.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/dashboard/revenue_series.dart';

BoutiqueStatsBucket _b(String key, int total) =>
    BoutiqueStatsBucket(key: key, total: total);

void main() {
  group('KpiDelta', () {
    test('arrondi au point près, signe moins typographique', () {
      expect(KpiDelta.of(61, 55), '+11 %');
      expect(KpiDelta.of(85, 88), '−3 %');
      expect(KpiDelta.of(5, 5), '+0 %');
    });

    test('masqué sans précédent, ou quand la comparaison n\'a pas de sens', () {
      expect(KpiDelta.of(10, 0), isNull);
      expect(KpiDelta.of(10, null), isNull);
      expect(KpiDelta.of(10, 5, comparable: false), isNull);
    });
  });

  group('RevenueSeries.visible', () {
    test('au-delà de deux mois, les jours se regroupent par mois', () {
      // Du 1er septembre au 21 octobre 2026 : 51 jours — encore au jour.
      List<BoutiqueStatsBucket> days(DateTime from, int count) => [
        for (var i = 0; i < count; i++)
          BoutiqueStatsBucket(
            key: StatsBucketKeys.dayKey(
              DateTime(from.year, from.month, from.day + i),
            ),
            total: 100,
          ),
      ];
      final short = days(DateTime(2026, 9), 51);
      expect(RevenueSeries.isMonthly(short, StatsGranularity.day), isFalse);

      // Du 15 juillet au 21 octobre : 99 jours, quatre mois dont deux partiels.
      final long = days(DateTime(2026, 7, 15), 99);
      expect(RevenueSeries.isMonthly(long, StatsGranularity.day), isTrue);
      final months = RevenueSeries.visible(long, StatsGranularity.day);
      expect(months.map((b) => b.key), [
        '2026-07',
        '2026-08',
        '2026-09',
        '2026-10',
      ]);
      expect(months.first.total, 1700);
      expect(months.last.total, 2100);
      expect(months.first.month, DateTime(2026, 7));
      expect(
        RevenueSeries.currentIndex(
          months,
          RevenueSeries.monthKey(DateTime(2026, 10, 21)),
        ),
        3,
      );
    });

    test(
      'heure par heure : seules les heures vendues restent, creux compris',
      () {
        final buckets = [
          for (var h = 0; h < 24; h++)
            _b(
              '2026-10-21T${h.toString().padLeft(2, '0')}',
              h == 8 || h == 11 ? 100 : 0,
            ),
        ];
        final visible = RevenueSeries.visible(buckets, StatsGranularity.hour);
        expect(visible.map((b) => b.hour), [8, 11]);
      },
    );

    test('une journée sans vente ne dessine rien', () {
      expect(
        RevenueSeries.visible([_b('2026-10-21T08', 0)], StatsGranularity.hour),
        isEmpty,
      );
    });

    test('jour par jour : seuls les jours d\'encaissement restent', () {
      final visible = RevenueSeries.visible([
        _b('2026-10-17', 100),
        _b('2026-10-18', 0),
        _b('2026-10-19', 0),
        _b('2026-10-20', 0),
        _b('2026-10-25', 50),
      ], StatsGranularity.day);
      expect(visible.map((b) => b.key), ['2026-10-17', '2026-10-25']);
    });

    test('mois par mois : un mois sans vente ne se dessine pas', () {
      final buckets = [
        for (var i = 0; i < 99; i++)
          _b(
            StatsBucketKeys.dayKey(DateTime(2026, 7, 15 + i)),
            // Rien vendu en août.
            DateTime(2026, 7, 15 + i).month == 8 ? 0 : 100,
          ),
      ];
      final visible = RevenueSeries.visible(buckets, StatsGranularity.day);
      expect(visible.map((b) => b.key), ['2026-07', '2026-09', '2026-10']);
    });
  });
}
