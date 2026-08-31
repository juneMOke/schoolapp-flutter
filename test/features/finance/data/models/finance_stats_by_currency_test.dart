import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_stats_response_model.dart';

Map<String, dynamic> _block(String currency, int collected) => {
  'currency': currency,
  'kpis': {
    'collected': collected,
    'expected': 400000,
    'outstanding': 400000 - collected,
    'collectionRate': 50,
  },
  'evolution': {
    'granularity': 'month',
    'currentBucketIndex': 1,
    'buckets': [
      {'key': '2026-04', 'value': 1000, 'isCurrent': false},
      {'key': '2026-05', 'value': 2000, 'isCurrent': true},
    ],
  },
  'distributionByFeeType': {
    'items': [
      {
        'code': 'TUITION',
        'collected': collected,
        'expected': 400000,
        'collectionRate': 50,
      },
    ],
  },
};

Map<String, dynamic> _response(List<Map<String, dynamic>> blocks) => {
  'context': {
    'schoolYear': '2025-2026',
    'period': 'year',
    'periodStart': '2025-09-01T00:00:00Z',
    'periodEnd': '2026-06-30T00:00:00Z',
    'generatedAt': '2026-05-23T08:00:00Z',
  },
  'byCurrency': blocks,
};

/// Les indicateurs de pilotage descendent d'un niveau : `kpis`, `evolution` et
/// `distributionByFeeType` quittent la racine pour un bloc complet **par
/// devise**.
///
/// L'endpoint refusait jusqu'ici une école bi-devise avec un 422, faute de
/// pouvoir rendre autre chose qu'un nombre unique. Il ne le fait plus.
void main() {
  group('byCurrency', () {
    test('un bloc par devise, dans l’ordre reçu du serveur', () {
      final model = FinanceStatsResponseModel.fromJson(
        _response([_block('CDF', 900000), _block('USD', 200000)]),
      );

      final stats = model.toEntity();
      expect(stats.byCurrency.map((b) => b.currency), ['CDF', 'USD']);
      expect(stats.byCurrency.first.kpis.collected, 900000);
      expect(stats.byCurrency.last.kpis.collected, 200000);
    });

    test('vide quand aucun argent n’a circulé — pas un zéro inventé', () {
      // « Aucun mouvement » n'est pas « zéro dollar » : personne n'a choisi
      // cette unité. C'est un état vide, pas une valeur.
      final stats = FinanceStatsResponseModel.fromJson(
        _response(const []),
      ).toEntity();

      expect(stats.byCurrency, isEmpty);
    });

    test('byCurrency absent se lit comme vide, sans lever', () {
      final json = _response(const [])..remove('byCurrency');

      final stats = FinanceStatsResponseModel.fromJson(json).toEntity();

      expect(stats.byCurrency, isEmpty);
    });

    test('une seule devise : le contenu du bloc est celui d’avant', () {
      final stats = FinanceStatsResponseModel.fromJson(
        _response([_block('USD', 200000)]),
      ).toEntity();

      final block = stats.byCurrency.single;
      expect(block.kpis.expected, 400000);
      expect(block.evolution.buckets, hasLength(2));
      expect(block.distributionByFeeType.items.single.code, 'TUITION');
    });

    test('la devise est normalisée, jamais rejetée', () {
      // Une devise que le serveur ajouterait avant cette version du client ne
      // doit pas faire échouer la lecture de tout le tableau de bord.
      final stats = FinanceStatsResponseModel.fromJson(
        _response([_block(' xaf ', 10)]),
      ).toEntity();

      expect(stats.byCurrency.single.currency, 'XAF');
    });

    test('l’axe du temps est le même dans tous les blocs', () {
      // C'est la garantie qui autorise à EMPILER les graphiques : ils
      // s'alignent compartiment par compartiment. Jamais à les superposer sur
      // un même axe vertical — l'écart d'échelle est de ×2 800.
      final stats = FinanceStatsResponseModel.fromJson(
        _response([_block('CDF', 900000), _block('USD', 200000)]),
      ).toEntity();

      final first = stats.byCurrency.first.evolution;
      final second = stats.byCurrency.last.evolution;
      expect(first.granularity, second.granularity);
      expect(first.currentBucketIndex, second.currentBucketIndex);
      expect(first.buckets.map((b) => b.key), second.buckets.map((b) => b.key));
    });

    test('le contexte ne porte plus de devise, et n’en a jamais eu besoin', () {
      // `context.currency` a disparu du contrat : elle n'était vraie que tant
      // qu'il n'y en avait qu'une. Ce modèle ne l'a jamais lue.
      final json = _response([_block('USD', 1)]);
      (json['context']! as Map<String, dynamic>)['currency'] = 'USD';

      expect(() => FinanceStatsResponseModel.fromJson(json), returnsNormally);
    });
  });
}
