import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_recovery_response_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_recovery.dart';

import 'finance_stats_fixtures.dart';

FinanceRecovery _entity(String raw) =>
    FinanceRecoveryResponseModel.fromJson(decodeFixture(raw)).toEntity();

/// Le recouvrement, lu depuis le fil.
///
/// L'écran répondait à deux questions sous un seul endpoint ; celui-ci ne
/// répond plus qu'à la première — **ce qu'il reste à encaisser cette année** —
/// et il l'a payé de trois renommages, d'un niveau d'objet en moins et de deux
/// champs neufs. Ce qui suit vérifie la lecture, et surtout les endroits où
/// elle doit céder sans emporter le tableau de bord.
void main() {
  group('forme', () {
    test('le contexte et l’ordre des devises descendent tels quels', () {
      final recovery = _entity(recoveryDormantCurrencyJson);

      expect(recovery.context.schoolYear, '2025-2026');
      expect(recovery.context.period, 'year');
      expect(recovery.context.periodStart, DateTime.parse('2025-09-01'));
      expect(recovery.context.periodEnd, DateTime.parse('2026-08-31'));
      expect(
        recovery.byCurrency.map((block) => block.currency),
        ['CDF', 'USD'],
        reason:
            'l’ordre est celui du serveur — cartes et sections descendent de '
            'la même liste, jamais de deux tris parallèles',
      );
    });

    test('les indicateurs et l’axe arrivent entiers', () {
      final block = _entity(recoverySingleCurrencyJson).byCurrency.single;

      expect(block.kpis.collected, 5240000);
      expect(block.kpis.expected, 7820000);
      expect(block.kpis.outstanding, 2580000);
      expect(block.kpis.collectionRate, 67);

      expect(
        block.monthlyCollected.granularity,
        FinanceEvolutionGranularity.month,
      );
      expect(block.monthlyCollected.currentBucketIndex, 8);
      expect(block.monthlyCollected.buckets.length, 12);
      expect(block.monthlyCollected.buckets.first.key, '2025-09');
      expect(
        block.monthlyCollected.buckets
            .where((bucket) => bucket.isCurrent)
            .single
            .key,
        '2026-05',
      );
    });

    test('la répartition garde l’ordre reçu, décroissant par attendu', () {
      final block = _entity(recoverySingleCurrencyJson).byCurrency.single;

      expect(block.byFeeCode.map((item) => item.code), [
        'TUITION',
        'REGISTRATION',
        'TRANSPORT',
      ]);
      expect(
        block.byFeeCode.map((item) => item.expected).toList(),
        [6000000, 1200000, 620000],
        reason: 'le tri est celui du serveur, jamais rejoué côté client',
      );
    });
  });

  group('les deux champs neufs', () {
    test('le libellé du serveur remplace la table locale', () {
      final block = _entity(recoverySingleCurrencyJson).byCurrency.single;

      expect(block.byFeeCode.map((item) => item.label), [
        'Minerval',
        "Frais d'inscription",
        'Transport scolaire',
      ]);
    });

    test(
      'un libellé absent ou vide retombe sur le code, pas sur un générique',
      () {
        final block = _entity(
          _jsonWith(
            feeCodeLine: '''
        { "code": "LAB_FEE", "collected": 0, "expected": 1000,
          "outstanding": 1000, "collectionRate": 0 }
      ''',
          ),
        ).byCurrency.single;

        expect(
          block.byFeeCode.single.label,
          'LAB_FEE',
          reason:
              'un libellé générique confondrait toutes les natures inconnues '
              'sous un même nom',
        );
      },
    );

    test('le reste dû par poste est porté jusqu’à l’entité', () {
      final block = _entity(recoverySingleCurrencyJson).byCurrency.single;

      expect(block.byFeeCode.map((item) => item.outstanding).toList(), [
        1900000,
        300000,
        380000,
      ]);
    });

    test(
      'un encaissé supérieur à l’attendu reste lisible grâce au reste dû',
      () {
        final item = _entity(
          recoveryOverCollectedJson,
        ).byCurrency.single.byFeeCode.single;

        expect(item.collected > item.expected, isTrue);
        expect(item.collectionRate, lessThan(100));
        expect(
          item.outstanding,
          400000,
          reason:
              'sans lui, la carte montre un encaissé au-dessus de l’attendu à '
              'côté d’une barre aux deux tiers, et rien n’explique l’écart',
        );
      },
    );
  });

  group('le bloc à zéro', () {
    test('une devise dormante se dit, elle ne disparaît pas', () {
      final dormant = _entity(recoveryDormantCurrencyJson).byCurrency.first;

      expect(dormant.currency, 'CDF');
      expect(dormant.hasNoMovement, isTrue);
      expect(dormant.kpis.hasNoExpectation, isTrue);
      expect(
        dormant.kpis.collectionRate,
        100,
        reason:
            'le serveur rend 100 sur un attendu nul ; c’est à l’écran de poser '
            'un tiret, et à `hasNoExpectation` de le lui dire',
      );
    });

    test('une créance non payée n’est PAS un bloc sans mouvement', () {
      final block = _entity(
        _jsonWith(
          collected: 0,
          expected: 1200000,
          outstanding: 1200000,
          rate: 0,
        ),
      ).byCurrency.single;

      expect(
        block.hasNoMovement,
        isFalse,
        reason:
            'rien n’est rentré, mais tout est à recouvrer — c’est exactement '
            'ce qu’un écran de recouvrement doit montrer',
      );
    });

    test('la liste vide reste une lecture valide', () {
      final recovery = _entity(statsNoCurrencyJson);

      expect(recovery.byCurrency, isEmpty);
      expect(recovery.context.schoolYear, '2025-2026');
    });
  });

  group('tolérance de lecture', () {
    test('les montants flottants redeviennent des centimes entiers', () {
      final block = _entity(recoveryFloatingAmountsJson).byCurrency.single;

      expect(block.kpis.collected, 5240000);
      expect(block.kpis.collectionRate, 67);
      expect(block.byFeeCode.single.outstanding, 1900000);
    });

    test('le code de devise est normalisé, jamais refusé', () {
      expect(
        _entity(recoveryFloatingAmountsJson).byCurrency.single.currency,
        'USD',
      );
    });

    test('une section absente est un non-évènement', () {
      final block = _entity(_jsonWith(withSections: false)).byCurrency.single;

      expect(block.byFeeCode, isEmpty);
      expect(block.monthlyCollected.buckets, isEmpty);
      expect(
        block.monthlyCollected.currentBucketIndex,
        -1,
        reason: 'aucun compartiment n’est courant quand il n’y en a aucun',
      );
      expect(
        block.kpis.collected,
        5240000,
        reason:
            'la répartition est un ornement, les indicateurs sont le chiffre',
      );
    });

    test('un bloc qui n’est pas un objet est ignoré, pas fatal', () {
      final recovery = _entity('''
        {
          "context": {
            "schoolYear": "2025-2026", "period": "year",
            "periodStart": "2025-09-01", "periodEnd": "2026-08-31",
            "generatedAt": "2026-05-22T08:00:00Z"
          },
          "byCurrency": ["USD", null]
        }
      ''');

      expect(recovery.byCurrency, isEmpty);
    });

    test('des indicateurs absents lèvent — jamais un zéro fabriqué', () {
      expect(
        () => _entity('''
          {
            "context": {
              "schoolYear": "2025-2026", "period": "year",
              "periodStart": "2025-09-01", "periodEnd": "2026-08-31",
              "generatedAt": "2026-05-22T08:00:00Z"
            },
            "byCurrency": [{ "currency": "USD", "byFeeCode": [] }]
          }
        '''),
        throwsA(isA<TypeError>()),
        reason:
            'un repli à zéro afficherait « 0 encaissé » sur un tableau de bord '
            'd’argent : le dépôt préfère l’état d’erreur',
      );
    });
  });
}

/// Un bloc de recouvrement taillé pour un cas précis, sur la forme du contrat.
///
/// Le JSON est écrit à la main plutôt que dérivé d'une entité : une fixture
/// construite en Dart n'exercerait jamais `fromJson`, qui est exactement ce
/// qu'on vérifie ici.
String _jsonWith({
  int collected = 5240000,
  int expected = 7820000,
  int outstanding = 2580000,
  int rate = 67,
  String? feeCodeLine,
  bool withSections = true,
}) {
  final sections = withSections
      ? '''
      ,
      "byFeeCode": [${feeCodeLine ?? '''
        { "code": "TUITION", "label": "Minerval", "collected": 4100000,
          "expected": 6000000, "outstanding": 1900000, "collectionRate": 68 }
      '''}],
      "monthlyCollected": {
        "granularity": "month",
        "currentBucketIndex": 8,
        "buckets": [{ "key": "2026-05", "value": 610000, "isCurrent": true }]
      }
      '''
      : '';

  return '''
  {
    "context": {
      "schoolYear": "2025-2026", "period": "year",
      "periodStart": "2025-09-01", "periodEnd": "2026-08-31",
      "generatedAt": "2026-05-22T08:00:00Z"
    },
    "byCurrency": [
      {
        "currency": "USD",
        "kpis": {
          "collected": $collected, "expected": $expected,
          "outstanding": $outstanding, "collectionRate": $rate
        }$sections
      }
    ]
  }
  ''';
}
