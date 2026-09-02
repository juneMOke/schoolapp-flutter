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
///
/// Depuis la bascule perçu/imputé, la réponse porte **deux tableaux** : ce qui
/// est entré (devise **reçue**) et ce que ça a éteint (devise de **créance**).
/// Ils ne se déduisent pas l'un de l'autre, et les tests qui suivent
/// l'imposent.
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
        expect(till.encaisse.map((block) => block.currency), ['CDF', 'USD']);
      },
    );

    test('le total et ses deux moitiés arrivent entiers', () {
      final usd = _entity(tillDayJson).encaisse.last;

      expect(usd.summary.total, 123450);
      expect(usd.summary.fees, 100000);
      expect(usd.summary.boutique, 23450);
      expect(usd.summary.total, usd.summary.fees + usd.summary.boutique);
    });

    test('le total du résumé vaut la somme des barres', () {
      for (final raw in [tillDayJson, tillMonthJson, tillYearJson]) {
        for (final block in _entity(raw).encaisse) {
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

  group('l’imputation — l’autre unité', () {
    test('chaque bloc est cohérent en interne : le total vaut ses lignes', () {
      for (final imputation in _entity(tillDayJson).impute) {
        final ventilated = imputation.byFeeCode.fold<int>(
          0,
          (sum, line) => sum + line.amount,
        );
        expect(imputation.total, ventilated);
      }
    });

    test('l’imputé ne se déduit PAS de l’encaissé : les deux comptent dans des '
        'unités différentes', () {
      final till = _entity(tillDayJson);
      final usdReceived = till.encaisse
          .firstWhere((block) => block.currency == 'USD')
          .summary
          .fees;
      final usdSettled = till.impute
          .firstWhere((imputation) => imputation.currency == 'USD')
          .total;

      expect(
        usdSettled,
        greaterThan(usdReceived),
        reason:
            'une partie des créances en dollars a été réglée en francs : '
            'recontrôler « imputé == frais encaissés » serait rétablir '
            'l’erreur que la bascule corrige',
      );
    });

    test('la boutique ne s’impute nulle part', () {
      final till = _entity(tillDayJson);
      final boutique = till.encaisse.fold<int>(
        0,
        (sum, block) => sum + block.summary.boutique,
      );
      final settled = till.impute.fold<int>(
        0,
        (sum, imputation) => sum + imputation.total,
      );

      expect(boutique, greaterThan(0));
      expect(
        till.impute
            .expand((imputation) => imputation.byFeeCode)
            .map((line) => line.code),
        isNot(contains('BOUTIQUE')),
      );
      expect(settled, isNot(0));
    });

    test('les postes gardent l’ordre du serveur, et leur libellé', () {
      final usd = _entity(
        tillDayJson,
      ).impute.firstWhere((imputation) => imputation.currency == 'USD');

      expect(usd.byFeeCode.map((line) => line.label), [
        'Minerval',
        "Frais d'inscription",
      ]);
    });
  });

  group('l’axe', () {
    test('une journée rend une barre, pas zéro', () {
      final buckets = _entity(tillDayJson).encaisse.first.buckets;

      expect(buckets.single.key, '2026-05-15');
      expect(buckets.single.isCurrent, isTrue);
    });

    test('un mois se lit jour par jour : 31 barres, une seule courante', () {
      final buckets = _entity(tillMonthJson).encaisse.single.buckets;

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
      final buckets = _entity(tillYearJson).encaisse.single.buckets;

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
        final buckets = _entity(tillMonthJson).encaisse.single.buckets;

        expect(buckets.where((bucket) => bucket.total == 0), isNotEmpty);
      },
    );
  });

  group('le bloc à zéro', () {
    test('une journée creuse se dit, elle ne disparaît pas', () {
      final till = _entity(tillEmptyDayJson);
      final block = till.encaisse.single;

      expect(block.hasNoMovement, isTrue);
      expect(till.impute, isEmpty, reason: 'rien reçu, donc rien éteint');
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
      ).encaisse.single;

      expect(block.hasNoMovement, isFalse);
      expect(block.summary.fees, 0);
      expect(block.summary.boutique, 5000);
    });

    test('les deux listes vides restent une lecture valide', () {
      final till = _entity(tillNoCurrencyJson);

      expect(till.encaisse, isEmpty);
      expect(till.impute, isEmpty);
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
      final imputation = _entity(
        _jsonWith(feeCodeLine: '{ "code": "UNIFORM", "amount": 100000 }'),
      ).impute.single;

      expect(imputation.byFeeCode.single.label, 'UNIFORM');
    });

    test('le code de devise est normalisé, jamais refusé', () {
      final till = _entity(_jsonWith(currency: 'cdf'));

      expect(till.encaisse.single.currency, 'CDF');
      expect(till.impute.single.currency, 'CDF');
    });

    test('les montants flottants redeviennent des centimes entiers', () {
      final block = _entity(
        _jsonWith(total: 123450, fees: 100000, boutique: 23450, floating: true),
      ).encaisse.single;

      expect(block.summary.total, 123450);
      expect(block.summary.boutique, 23450);
      expect(block.buckets.single.total, 123450);
    });

    test('un axe absent rend un graphique vide, pas une erreur', () {
      final block = _entity(_jsonWith(withBuckets: false)).encaisse.single;

      expect(block.buckets, isEmpty);
      expect(
        block.summary.total,
        123450,
        reason: 'l’axe est un ornement, le total du tiroir est le chiffre',
      );
    });

    test(
      'l’imputation absente cède : l’écran perd une section, pas son chiffre',
      () {
        final till = _entity(_jsonWith(withImpute: false));

        expect(till.impute, isEmpty);
        expect(till.encaisse.single.summary.total, 123450);
      },
    );

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
            "encaisse": [{ "currency": "USD", "buckets": [] }],
            "impute": []
          }
        '''),
        throwsA(isA<TypeError>()),
        reason:
            'dire « rien n’est entré aujourd’hui » à un caissier qui a le '
            'tiroir ouvert devant lui est pire que dire « erreur »',
      );
    });

    test(
      'un total d’imputation absent lève : il ne se refabrique pas depuis ses '
      'lignes',
      () {
        expect(
          () => _entity(_jsonWith(imputationTotal: 'null')),
          throwsA(isA<TypeError>()),
          reason:
              'sommer les lignes pour reconstituer le total masquerait '
              'précisément le jour où les deux divergent',
        );
      },
    );
  });

  group('la rupture de contrat', () {
    test('un corps d’hier (`byCurrency`) LÈVE — il ne se lit pas comme une '
        'journée creuse', () {
      expect(
        () => _entity(tillLegacyByCurrencyJson),
        throwsA(isA<FormatException>()),
        reason:
            'ce corps porte 90 000 FC bien réels ; une tolérance sur '
            '`encaisse` les afficherait comme « aucun mouvement », et '
            'personne ne saurait que le serveur est resté en arrière',
      );
    });

    test('aucune voie de lecture de secours n’est conservée', () {
      final legacy = decodeFixture(tillLegacyByCurrencyJson);

      expect(
        legacy.containsKey('byCurrency'),
        isTrue,
        reason: 'la fixture doit bien porter l’ancienne clé',
      );
      expect(
        () => FinanceTillResponseModel.fromJson(legacy),
        throwsA(isA<FormatException>()),
        reason:
            'un repli `encaisse ?? byCurrency` ferait vivre deux contrats à '
            'la fois, et l’écran montrerait de l’imputé sous le mot encaissé',
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
  String? imputationTotal,
  bool withTimeZone = true,
  bool withBuckets = true,
  bool withImpute = true,
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
  final impute = withImpute
      ? '''
    "impute": [
      {
        "currency": "$currency",
        "total": ${imputationTotal ?? amount(fees)},
        "byFeeCode": [${feeCodeLine ?? '''
          { "code": "TUITION", "label": "Minerval", "amount": ${amount(fees)} }
        '''}]
      }
    ],
  '''
      : '';

  return '''
  {
    "context": {
      "schoolYear": "2025-2026", "period": "day",
      "periodStart": "2026-05-15", "periodEnd": "2026-05-15",
      "generatedAt": "2026-05-15T18:04:11Z"
    },
    $timeZone
    $impute
    "encaisse": [
      {
        "currency": "$currency",
        "summary": {
          "total": ${amount(total)},
          "fees": ${amount(fees)},
          "boutique": ${amount(boutique)}
        },
        "buckets": $buckets
      }
    ]
  }
  ''';
}
