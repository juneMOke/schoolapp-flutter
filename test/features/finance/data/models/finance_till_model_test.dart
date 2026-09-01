import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/finance_till_response_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';

import 'finance_stats_fixtures.dart';

FinanceTill _entity(String raw) =>
    FinanceTillResponseModel.fromJson(decodeFixture(raw)).toEntity();

/// La caisse, lue depuis le fil.
///
/// L'écran répond à « combien est entré dans le tiroir » — un **flux**, exact
/// complémentaire du recouvrement qui est un **état**. Rien n'y est dû, rien
/// n'y est attendu, aucun taux n'y est calculé ; en revanche deux moitiés s'y
/// additionnent, et c'est le seul endroit du pilotage financier où une somme
/// est un invariant qu'on peut vérifier.
void main() {
  group('forme', () {
    test(
      'le contexte, le fuseau et l’ordre des devises descendent tels quels',
      () {
        final till = _entity(tillDayJson);

        expect(till.context.period, 'day');
        expect(till.context.periodStart, DateTime.parse('2026-05-15'));
        expect(till.context.periodEnd, DateTime.parse('2026-05-15'));
        expect(till.timeZone, 'Africa/Kinshasa');
        expect(till.hasTimeZone, isTrue);
        expect(till.byCurrency.map((block) => block.currency), ['CDF', 'USD']);
      },
    );

    test('le total et ses deux moitiés arrivent entiers', () {
      final usd = _entity(tillDayJson).byCurrency.last;

      expect(usd.summary.total, 123450);
      expect(usd.summary.fees, 100000);
      expect(usd.summary.boutique, 23450);
      expect(usd.summary.total, usd.summary.fees + usd.summary.boutique);
    });

    test('la ventilation ne couvre que les frais, jamais le total', () {
      final usd = _entity(tillDayJson).byCurrency.last;

      final ventilated = usd.summary.byFeeCode.fold<int>(
        0,
        (sum, line) => sum + line.amount,
      );
      expect(ventilated, usd.summary.fees);
      expect(
        ventilated,
        isNot(usd.summary.total),
        reason:
            'une vente boutique n’est imputée sur aucune créance : elle n’a '
            'aucun poste de frais et reste entière dans `boutique`',
      );
      expect(usd.summary.byFeeCode.map((line) => line.label), [
        'Minerval',
        "Frais d'inscription",
      ]);
    });

    test('le total du résumé vaut la somme des barres', () {
      for (final raw in [tillDayJson, tillMonthJson, tillYearJson]) {
        for (final block in _entity(raw).byCurrency) {
          final summed = block.buckets.fold<int>(
            0,
            (sum, bucket) => sum + bucket.total,
          );
          expect(
            block.summary.total,
            summed,
            reason:
                'les deux sont repliés depuis les mêmes lignes journalières — '
                'le total et les barres s’affichent côte à côte sans '
                'réconciliation',
          );
        }
      }
    });
  });

  group('l’axe', () {
    test('une journée rend une barre, pas zéro', () {
      final buckets = _entity(tillDayJson).byCurrency.first.buckets;

      expect(buckets.single.key, '2026-05-15');
      expect(buckets.single.isCurrent, isTrue);
    });

    test('un mois se lit jour par jour : 31 barres, une seule courante', () {
      final buckets = _entity(tillMonthJson).byCurrency.single.buckets;

      expect(buckets.length, 31);
      expect(
        buckets.where((bucket) => bucket.isCurrent).single.key,
        '2026-05-15',
      );
      expect(
        buckets.every((bucket) => bucket.key.length == 10),
        isTrue,
        reason: 'les semaines ISO déborderaient de part et d’autre du mois',
      );
    });

    test('seul l’axe annuel replie ses clés en mois', () {
      final buckets = _entity(tillYearJson).byCurrency.single.buckets;

      expect(buckets.length, 12);
      expect(buckets.first.key, '2025-09');
      expect(
        buckets.every((bucket) => bucket.key.length == 7),
        isTrue,
        reason:
            'c’est la seule période où la clé change de forme, et le '
            'formatteur de libellé doit s’en apercevoir',
      );
    });

    test(
      'un intervalle creux rend une barre à zéro, jamais une barre absente',
      () {
        final buckets = _entity(tillMonthJson).byCurrency.single.buckets;

        expect(buckets.where((bucket) => bucket.total == 0), isNotEmpty);
      },
    );
  });

  group('le bloc à zéro', () {
    test('une journée creuse se dit, elle ne disparaît pas', () {
      final block = _entity(tillEmptyDayJson).byCurrency.single;

      expect(block.hasNoMovement, isTrue);
      expect(block.summary.byFeeCode, isEmpty);
      expect(
        block.buckets,
        isNotEmpty,
        reason:
            'la forme de la réponse ne change pas avec la période : l’écran '
            'n’a jamais deux branches d’affichage à tenir',
      );
    });

    test('une seule vente boutique suffit à faire un mouvement', () {
      final block = _entity(
        _jsonWith(total: 5000, fees: 0, boutique: 5000),
      ).byCurrency.single;

      expect(block.hasNoMovement, isFalse);
      expect(block.summary.fees, 0);
      expect(block.summary.boutique, 5000);
    });

    test('la liste vide reste une lecture valide', () {
      expect(_entity(statsNoCurrencyJson).byCurrency, isEmpty);
    });
  });

  group('tolérance de lecture', () {
    test('un fuseau absent se tait, il ne se devine pas', () {
      final till = _entity(_jsonWith(withTimeZone: false));

      expect(till.timeZone, isEmpty);
      expect(
        till.hasTimeZone,
        isFalse,
        reason:
            'affirmer « heure de Kinshasa » sans l’avoir reçu serait inventer '
            'le découpage d’une journée de caisse',
      );
    });

    test('un libellé absent retombe sur le code', () {
      final block = _entity(
        _jsonWith(feeCodeLine: '{ "code": "UNIFORM", "amount": 100000 }'),
      ).byCurrency.single;

      expect(block.summary.byFeeCode.single.label, 'UNIFORM');
    });

    test('le code de devise est normalisé, jamais refusé', () {
      expect(
        _entity(_jsonWith(currency: 'cdf')).byCurrency.single.currency,
        'CDF',
      );
    });

    test('les montants flottants redeviennent des centimes entiers', () {
      final block = _entity(
        _jsonWith(total: 123450, fees: 100000, boutique: 23450, floating: true),
      ).byCurrency.single;

      expect(block.summary.total, 123450);
      expect(block.summary.boutique, 23450);
      expect(block.buckets.single.total, 123450);
    });

    test('un axe absent rend un graphique vide, pas une erreur', () {
      final block = _entity(_jsonWith(withBuckets: false)).byCurrency.single;

      expect(block.buckets, isEmpty);
      expect(
        block.summary.total,
        123450,
        reason: 'l’axe est un ornement, le total du tiroir est le chiffre',
      );
    });

    test('un résumé absent lève — jamais un tiroir vide fabriqué', () {
      expect(
        () => _entity('''
          {
            "context": {
              "schoolYear": "2025-2026", "period": "day",
              "periodStart": "2026-05-15", "periodEnd": "2026-05-15",
              "generatedAt": "2026-05-15T18:04:11Z"
            },
            "timeZone": "Africa/Kinshasa",
            "byCurrency": [{ "currency": "USD", "buckets": [] }]
          }
        '''),
        throwsA(isA<TypeError>()),
        reason:
            'dire « rien n’est entré aujourd’hui » à un caissier qui a le '
            'tiroir ouvert devant lui est pire que dire « erreur »',
      );
    });
  });
}

/// Une caisse taillée pour un cas précis, sur la forme du contrat.
///
/// Écrite à la main plutôt que dérivée d'une entité : une fixture construite en
/// Dart n'exercerait jamais `fromJson`, qui est exactement ce qu'on vérifie.
String _jsonWith({
  String currency = 'USD',
  int total = 123450,
  int fees = 100000,
  int boutique = 23450,
  String? feeCodeLine,
  bool withTimeZone = true,
  bool withBuckets = true,
  bool floating = false,
}) {
  String amount(int value) => floating ? '$value.0' : '$value';

  final timeZone = withTimeZone ? '"timeZone": "Africa/Kinshasa",' : '';
  final buckets = withBuckets
      ? '''
        [
          {
            "key": "2026-05-15", "total": ${amount(total)},
            "fees": ${amount(fees)}, "boutique": ${amount(boutique)},
            "isCurrent": true
          }
        ]
      '''
      : 'null';

  return '''
  {
    "context": {
      "schoolYear": "2025-2026", "period": "day",
      "periodStart": "2026-05-15", "periodEnd": "2026-05-15",
      "generatedAt": "2026-05-15T18:04:11Z"
    },
    $timeZone
    "byCurrency": [
      {
        "currency": "$currency",
        "summary": {
          "total": ${amount(total)},
          "fees": ${amount(fees)},
          "boutique": ${amount(boutique)},
          "byFeeCode": [${feeCodeLine ?? '''
            { "code": "TUITION", "label": "Minerval", "amount": ${amount(fees)} }
          '''}]
        },
        "buckets": $buckets
      }
    ]
  }
  ''';
}
