import 'package:flutter_test/flutter_test.dart';

import 'finance_stats_fixtures.dart';

/// Les fixtures avant les modèles.
///
/// Tout ce qui suit dans la feature — modèles, entités, BLoCs, écrans — se
/// vérifiera contre ces charges utiles. Une fixture qui violerait un invariant
/// du serveur ferait passer au vert un code qui ne pourrait pas marcher en
/// production, ou rougir un code juste. On les tient donc pour ce qu'elles
/// sont : la copie locale du contrat, à garder honnête.
void main() {
  group('recouvrement', () {
    test('les trois fixtures décodent et portent la forme du contrat', () {
      for (final raw in [
        recoverySingleCurrencyJson,
        recoveryDormantCurrencyJson,
        recoveryOverCollectedJson,
        recoveryFloatingAmountsJson,
      ]) {
        final json = decodeFixture(raw);
        expect(json['context'], isA<Map<String, dynamic>>());
        expect((json['context'] as Map)['period'], 'year');
        for (final block in json['byCurrency'] as List) {
          final map = block as Map<String, dynamic>;
          expect(map['kpis'], isA<Map<String, dynamic>>());
          expect(map['byFeeCode'], isA<List<dynamic>>());
          expect(map['monthlyCollected'], isA<Map<String, dynamic>>());
        }
      }
    });

    test('`granularity` vaut toujours `month`', () {
      for (final raw in [
        recoverySingleCurrencyJson,
        recoveryDormantCurrencyJson,
        recoveryOverCollectedJson,
      ]) {
        for (final block in decodeFixture(raw)['byCurrency'] as List) {
          final axis =
              (block as Map<String, dynamic>)['monthlyCollected']
                  as Map<String, dynamic>;
          expect(axis['granularity'], 'month');
        }
      }
    });

    test(
      '`outstanding` est plancherisé : jamais négatif, jamais > expected',
      () {
        for (final raw in [
          recoverySingleCurrencyJson,
          recoveryDormantCurrencyJson,
          recoveryOverCollectedJson,
        ]) {
          for (final block in decodeFixture(raw)['byCurrency'] as List) {
            final map = block as Map<String, dynamic>;
            final kpis = map['kpis'] as Map<String, dynamic>;
            _expectFlooredOutstanding(kpis);
            for (final line in map['byFeeCode'] as List) {
              _expectFlooredOutstanding(line as Map<String, dynamic>);
            }
          }
        }
      },
    );

    test('un encaissé supérieur à l’attendu laisse le taux sous 100', () {
      final block =
          (decodeFixture(recoveryOverCollectedJson)['byCurrency'] as List)
                  .single
              as Map<String, dynamic>;
      final kpis = block['kpis'] as Map<String, dynamic>;

      expect(
        (kpis['collected'] as num) > (kpis['expected'] as num),
        isTrue,
        reason: 'la fixture doit porter le cas de l’arriéré qui se solde',
      );
      expect((kpis['collectionRate'] as num) < 100, isTrue);
    });

    test('une devise dormante rend un taux de 100 sur un attendu nul', () {
      final dormant =
          (decodeFixture(recoveryDormantCurrencyJson)['byCurrency'] as List)
                  .first
              as Map<String, dynamic>;
      final kpis = dormant['kpis'] as Map<String, dynamic>;

      expect(kpis['expected'], 0);
      expect(
        kpis['collectionRate'],
        100,
        reason:
            'le serveur rend 100 quand rien n’est attendu — c’est « rien ne '
            'manque », pas « tout a été recouvré »',
      );
    });
  });

  group('caisse', () {
    test('`total` vaut toujours `fees + boutique`', () {
      for (final raw in [
        tillDayJson,
        tillMonthJson,
        tillEmptyDayJson,
        tillYearJson,
      ]) {
        for (final block in decodeFixture(raw)['encaisse'] as List) {
          final map = block as Map<String, dynamic>;
          final summary = map['summary'] as Map<String, dynamic>;
          expect(
            summary['total'],
            (summary['fees'] as num) + (summary['boutique'] as num),
          );
          for (final bucket in map['buckets'] as List) {
            final b = bucket as Map<String, dynamic>;
            expect(b['total'], (b['fees'] as num) + (b['boutique'] as num));
          }
        }
      }
    });

    test('`summary.total` vaut la somme des `buckets[].total`', () {
      for (final raw in [
        tillDayJson,
        tillMonthJson,
        tillEmptyDayJson,
        tillYearJson,
      ]) {
        for (final block in decodeFixture(raw)['encaisse'] as List) {
          final map = block as Map<String, dynamic>;
          final summed = (map['buckets'] as List).fold<num>(
            0,
            (sum, bucket) =>
                sum + ((bucket as Map<String, dynamic>)['total'] as num),
          );
          expect((map['summary'] as Map<String, dynamic>)['total'], summed);
        }
      }
    });

    test('un bloc d’imputation somme exactement à son total', () {
      for (final raw in [tillDayJson, tillMonthJson, tillYearJson]) {
        for (final block in decodeFixture(raw)['impute'] as List) {
          final map = block as Map<String, dynamic>;
          final summed = (map['byFeeCode'] as List).fold<num>(
            0,
            (sum, line) =>
                sum + ((line as Map<String, dynamic>)['amount'] as num),
          );
          expect(
            summed,
            map['total'],
            reason:
                'chaque bloc reste cohérent en interne : le total y retombe '
                'sur la somme de ce qu’il affiche dessous',
          );
        }
      }
    });

    test('l’imputé ne se déduit pas de l’encaissé — la fixture nominale porte '
        'l’écart', () {
      final json = decodeFixture(tillDayJson);
      final usdReceived =
          ((json['encaisse'] as List)
                      .map((b) => b as Map<String, dynamic>)
                      .firstWhere((b) => b['currency'] == 'USD')['summary']
                  as Map<String, dynamic>)['fees']
              as num;
      final usdSettled =
          (json['impute'] as List)
                  .map((b) => b as Map<String, dynamic>)
                  .firstWhere((b) => b['currency'] == 'USD')['total']
              as num;

      expect(
        usdSettled,
        greaterThan(usdReceived),
        reason:
            'une créance en dollars réglée en francs : c’est le cas qui a '
            'fait scinder la réponse en deux tableaux, et la fixture doit '
            'le porter — sans quoi un contrôle « imputé == frais » '
            'repasserait au vert',
      );
    });

    test('la boutique n’apparaît dans aucune imputation', () {
      for (final raw in [tillDayJson, tillMonthJson, tillYearJson]) {
        for (final block in decodeFixture(raw)['impute'] as List) {
          final codes = ((block as Map<String, dynamic>)['byFeeCode'] as List)
              .map((line) => (line as Map<String, dynamic>)['code']);
          expect(
            codes,
            isNot(contains('BOUTIQUE')),
            reason: 'une vente comptant n’est imputée sur aucune créance',
          );
        }
      }
    });

    test('`buckets` n’est jamais vide, même sur une journée creuse', () {
      for (final raw in [
        tillDayJson,
        tillMonthJson,
        tillEmptyDayJson,
        tillYearJson,
      ]) {
        for (final block in decodeFixture(raw)['encaisse'] as List) {
          expect(
            (block as Map<String, dynamic>)['buckets'],
            isNotEmpty,
            reason:
                'une réponse dont la forme change avec la période obligerait '
                'l’écran à tenir deux branches d’affichage',
          );
        }
      }
    });

    test('la clé est journalière partout sauf sur l’axe annuel', () {
      for (final raw in [tillDayJson, tillMonthJson, tillEmptyDayJson]) {
        for (final block in decodeFixture(raw)['encaisse'] as List) {
          for (final bucket
              in (block as Map<String, dynamic>)['buckets'] as List) {
            expect(
              (bucket as Map<String, dynamic>)['key'],
              matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
            );
          }
        }
      }

      for (final block in decodeFixture(tillYearJson)['encaisse'] as List) {
        for (final bucket
            in (block as Map<String, dynamic>)['buckets'] as List) {
          expect(
            (bucket as Map<String, dynamic>)['key'],
            matches(RegExp(r'^\d{4}-\d{2}$')),
          );
        }
      }
    });

    test('le mois se lit jour par jour : 31 barres, une seule courante', () {
      final block =
          (decodeFixture(tillMonthJson)['encaisse'] as List).single
              as Map<String, dynamic>;
      final buckets = block['buckets'] as List;

      expect(buckets.length, 31);
      expect(
        buckets
            .where((b) => (b as Map<String, dynamic>)['isCurrent'] == true)
            .length,
        1,
      );
    });

    test('le fuseau est publié, et c’est celui de l’école', () {
      for (final raw in [
        tillDayJson,
        tillMonthJson,
        tillEmptyDayJson,
        tillYearJson,
      ]) {
        expect(decodeFixture(raw)['timeZone'], 'Africa/Kinshasa');
      }
    });
  });

  group('commun', () {
    test('une liste de devises vide est une réponse valide, pas une erreur', () {
      final recovery = decodeFixture(statsNoCurrencyJson);
      expect(recovery['byCurrency'], isEmpty);
      expect(recovery['context'], isA<Map<String, dynamic>>());

      // Côté caisse, les DEUX tableaux sont vides — et c'est bien un état, pas
      // le corps d'un serveur resté sur l'ancien contrat, qui lui LÈVE.
      final till = decodeFixture(tillNoCurrencyJson);
      expect(till['encaisse'], isEmpty);
      expect(till['impute'], isEmpty);
      expect(till.containsKey('byCurrency'), isFalse);
    });

    test('la fixture d’hier porte bien l’ancienne clé, et rien d’autre', () {
      final legacy = decodeFixture(tillLegacyByCurrencyJson);

      expect(legacy['byCurrency'], isNotEmpty);
      expect(legacy.containsKey('encaisse'), isFalse);
      expect(
        legacy.containsKey('impute'),
        isFalse,
        reason:
            'c’est ce corps-là que la lecture doit refuser : il porte de '
            'l’argent réel sous un nom que le client ne lit plus',
      );
    });

    test('les bornes de fenêtre sont des dates nues, pas des instants', () {
      for (final raw in [
        recoverySingleCurrencyJson,
        tillDayJson,
        tillYearJson,
      ]) {
        final context = decodeFixture(raw)['context'] as Map<String, dynamic>;
        expect(context['periodStart'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        expect(context['periodEnd'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
        expect(context['generatedAt'], contains('T'));
      }
    });

    test('les montants flottants restent des entiers de centimes', () {
      final block =
          (decodeFixture(recoveryFloatingAmountsJson)['byCurrency'] as List)
                  .single
              as Map<String, dynamic>;
      final collected = (block['kpis'] as Map<String, dynamic>)['collected'];

      expect(collected, isA<double>());
      expect((collected as num).toInt(), 5240000);
    });
  });
}

void _expectFlooredOutstanding(Map<String, dynamic> line) {
  final outstanding = line['outstanding'] as num;
  expect(outstanding >= 0, isTrue);
  expect(outstanding <= (line['expected'] as num), isTrue);
}
