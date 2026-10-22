import 'package:flutter_test/flutter_test.dart';
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
    test(
      'heure par heure : les heures creuses en tête et en queue partent',
      () {
        final buckets = [
          for (var h = 0; h < 24; h++)
            _b(
              '2026-10-21T${h.toString().padLeft(2, '0')}',
              h == 8 || h == 11 ? 100 : 0,
            ),
        ];
        final visible = RevenueSeries.visible(buckets, StatsGranularity.hour);
        expect(visible.map((b) => b.hour), [8, 9, 10, 11]);
      },
    );

    test('une journée sans vente ne dessine rien', () {
      expect(
        RevenueSeries.visible([_b('2026-10-21T08', 0)], StatsGranularity.hour),
        isEmpty,
      );
    });

    test('jour par jour : un dimanche vide part, un dimanche vendu reste', () {
      // Le 18 et le 25 octobre 2026 sont des dimanches.
      final visible = RevenueSeries.visible([
        _b('2026-10-17', 100),
        _b('2026-10-18', 0),
        _b('2026-10-19', 0),
        _b('2026-10-25', 50),
      ], StatsGranularity.day);
      expect(visible.map((b) => b.key), [
        '2026-10-17',
        '2026-10-19',
        '2026-10-25',
      ]);
    });
  });
}
