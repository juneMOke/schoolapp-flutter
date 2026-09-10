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

    test('sur une journée, le total du résumé ne vaut PAS la somme des barres '
        '— la série déborde la fenêtre comptée', () {
      for (final block in _entity(tillDayJson).encaisse) {
        final summed = block.buckets.fold<int>(
          0,
          (sum, bucket) => sum + bucket.total,
        );

        expect(
          block.buckets,
          hasLength(7),
          reason:
              'le serveur dessine sept jours autour de la journée demandée '
              '(début − 6 j) : un chiffre du jour, seul, ne dit pas s’il est '
              'bon',
        );
        expect(
          block.summary.total,
          lessThan(summed),
          reason:
              'le résumé porte sur la FENÊTRE, la série sur ce qu’il faut pour '
              'la lire — recoller les deux ferait échouer la journée, qui est '
              'la fenêtre par défaut de l’écran',
        );
      }
    });

    test(
      'le total affiché est celui du résumé, jamais la somme des barres',
      () {
        final usd = _entity(tillDayJson).encaisse.last;
        final today = usd.buckets.firstWhere((bucket) => bucket.isCurrent);

        expect(
          usd.summary.total,
          today.total,
          reason:
              'sur une journée, le résumé vaut exactement la barre du jour '
              'demandé — c’est ce qui rend l’écart avec les six autres lisible '
              'plutôt que suspect',
        );
      },
    );

    test('sur une fenêtre large, la série couvre exactement la fenêtre', () {
      for (final raw in [tillMonthJson, tillYearJson]) {
        for (final block in _entity(raw).encaisse) {
          final summed = block.buckets.fold<int>(
            0,
            (sum, bucket) => sum + bucket.total,
          );
          expect(
            block.summary.total,
            summed,
            reason:
                'hors journée, la série ne déborde pas : les deux se replient '
                'depuis les mêmes lignes, et l’écart de la fenêtre `day` est '
                'bien une particularité de cette fenêtre-là',
          );
        }
      }
    });
  });

  group(
    'les compteurs — celui qu’on additionne et ceux qu’on n’additionne pas',
    () {
      test('« reçus émis » ne vaut pas la somme des compteurs par caisse', () {
        final till = _entity(tillDayJson);
        final perTill = till.encaisse.fold<int>(
          0,
          (sum, block) => sum + block.summary.receiptCount,
        );

        expect(till.receiptsIssued, 7);
        expect(
          till.receiptsIssued,
          lessThan(perTill),
          reason:
              'un reçu croisé alimente deux caisses et compte une fois par '
              'caisse, mais n’est émis qu’une fois — « 40 \$ + 35 FC » au-dessus '
              'de « 70 reçus émis » a raison deux fois et paraît faux',
        );
      });

      test(
        'le ticket moyen est LU, jamais recalculé sur le compteur global',
        () {
          final usd = _entity(tillDayJson).encaisse.last;

          expect(usd.summary.averageTicket, 24690);
          expect(
            usd.summary.averageTicket,
            usd.summary.total ~/ usd.summary.receiptCount,
            reason:
                'le dénominateur est le compteur DE LA CAISSE ; diviser par les '
                'reçus émis donnerait 17 635 et sous-estimerait chaque panier',
          );
        },
      );
    },
  );

  group('ce qui se tait plutôt que de mentir', () {
    test('`trendPercent` absent reste null — jamais replié sur zéro', () {
      final blocks = _entity(tillDayJson).encaisse;
      final cdf = blocks.firstWhere((block) => block.currency == 'CDF');
      final usd = blocks.firstWhere((block) => block.currency == 'USD');

      expect(cdf.summary.trendPercent, isNull);
      expect(cdf.summary.hasTrend, isFalse);
      expect(
        usd.summary.trendPercent,
        18,
        reason: 'le cas mesuré doit rester distinct du cas tu',
      );
    });

    test('la cause du silence distingue « impossible » de « vide »', () {
      final blocks = _entity(tillDayJson).encaisse;
      final cdf = blocks.firstWhere((block) => block.currency == 'CDF');

      expect(
        cdf.summary.trendUnavailableReason,
        TillTrendUnavailableReason.beforeSchoolYear,
      );
      expect(
        cdf.summary.explainsMissingTrend,
        isTrue,
        reason:
            'la comparaison est impossible — la période antérieure tomberait '
            'avant la rentrée — et l’écran doit le dire',
      );
    });

    test('une période précédente vide se tait, elle ne s’explique pas', () {
      final block = _entity(tillEmptyDayJson).encaisse.first;

      expect(
        block.summary.trendUnavailableReason,
        TillTrendUnavailableReason.previousPeriodEmpty,
      );
      expect(
        block.summary.explainsMissingTrend,
        isFalse,
        reason:
            'c’est un fait de la période regardée, pas une limite de la '
            'mesure : l’absence se comprend d’elle-même',
      );
    });

    test('une cause inconnue se tait plutôt que d’expliquer de travers', () {
      final block = _entity(tillUnknownTrendReasonJson).encaisse.single;

      expect(
        block.summary.trendUnavailableReason,
        isNull,
        reason:
            'retomber sur une cause connue afficherait une explication fausse '
            'le jour où le serveur en ajoute une troisième',
      );
      expect(block.summary.explainsMissingTrend, isFalse);
    });

    test('`bestBucket` absent reste null sur une caisse creuse', () {
      for (final block in _entity(tillEmptyDayJson).encaisse) {
        expect(block.bestBucket, isNull);
      }
    });

    test('la part du meilleur intervalle se rapporte aux barres dessinées', () {
      final usd = _entity(tillDayJson).encaisse.last;
      final drawn = usd.buckets.fold<int>(
        0,
        (sum, bucket) => sum + bucket.total,
      );

      expect(usd.bestBucket!.key, '2026-05-14');
      expect(
        usd.bestBucket!.sharePercent,
        (usd.bestBucket!.amount * 100 / drawn).round(),
        reason:
            'rapportée à la journée comptée, la part vaudrait 100 % à chaque '
            'fois et la carte cesserait de rien dire',
      );
    });
  });

  group('le classement par classe', () {
    test('le palmarès et le montant sans classe se complètent au total', () {
      final usd = _entity(tillDayJson).encaisse.last;
      final ranked = usd.byClassroom.fold<int>(
        0,
        (sum, row) => sum + row.amount,
      );

      expect(usd.unassignedAmount, 23450);
      expect(usd.hasUnassigned, isTrue);
      expect(
        ranked + usd.unassignedAmount,
        usd.summary.total,
        reason:
            'sans la mention du montant écarté, la somme des lignes ne '
            'retombe pas sur le total et le classement passe pour un bug — '
            'une vente boutique ne désigne ni élève ni classe',
      );
    });

    test('une caisse sans vente boutique n’écarte rien', () {
      final cdf = _entity(tillDayJson).encaisse.first;

      expect(cdf.unassignedAmount, 0);
      expect(cdf.hasUnassigned, isFalse);
    });
  });

  group('les paiements croisés', () {
    test('les montants croisés gardent leur devise, jamais un total', () {
      final crossed = _entity(tillDayJson).crossed;

      expect(crossed.count, 2);
      expect(crossed.isEmpty, isFalse);
      expect(crossed.amounts.map((amount) => amount.currency), ['CDF', 'USD']);
      expect(crossed.amounts.map((amount) => amount.amount), [1150000, 13500]);
    });

    test('les taux arrivent en micro-unités, et plusieurs se signalent', () {
      final crossed = _entity(tillDayJson).crossed;

      expect(crossed.rateMicros, [2850000000, 2900000000]);
      expect(
        crossed.hasMultipleRates,
        isTrue,
        reason:
            'un taux changé en cours de fenêtre est justement ce qui explique '
            'un écart de caisse — l’encart ne peut pas en citer un seul',
      );
    });

    test(
      'un bloc `crossed` absent vaut « aucun croisement », pas une erreur',
      () {
        final crossed = _entity(tillEmptyDayJson).crossed;

        expect(crossed.isEmpty, isTrue);
        expect(crossed.rateMicros, isEmpty);
        expect(crossed.amounts, isEmpty);
      },
    );
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
    test('une journée rend sept barres, et une seule est courante', () {
      final buckets = _entity(tillDayJson).encaisse.first.buckets;

      // Ce test affirmait « une journée rend UNE barre ». Il était vert, et
      // faux : le serveur trace les six jours qui précèdent la journée
      // demandée, parce qu'un chiffre du jour, seul, ne dit pas s'il est bon.
      expect(buckets.map((bucket) => bucket.key), [
        '2026-05-09',
        '2026-05-10',
        '2026-05-11',
        '2026-05-12',
        '2026-05-13',
        '2026-05-14',
        '2026-05-15',
      ]);
      expect(
        buckets.where((bucket) => bucket.isCurrent).single.key,
        '2026-05-15',
      );
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
