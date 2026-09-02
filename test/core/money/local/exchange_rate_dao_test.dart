import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/local/exchange_rate_dao.dart';
import 'package:school_app_flutter/core/money/local/exchange_rate_local_model.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../features/offline_full_db.dart';

/// Le taux de guichet en local — écriture par le pull, lecture au guichet.
///
/// Deux propriétés dangereuses. **La purge est scopée par école** : la table n'a
/// pas d'année, donc aucun filtre ne viendra transformer une erreur de scope en
/// « liste vide » — elle se traduirait par l'extinction de la bascule de devise
/// à l'école d'à côté. Et **une ligne inexploitable s'écarte en silence** :
/// mieux vaut pas de taux qu'un taux qu'on ne sait pas dater.
void main() {
  late Database db;
  late ExchangeRateDao dao;

  ExchangeRateLocalModel rate(
    String schoolId, {
    String base = 'USD',
    String quote = 'CDF',
    String effectiveFrom = '2026-09-01T06:00:00Z',
    int rateMicros = 1666670000,
    int? bandBp = 200,
  }) => ExchangeRateLocalModel(
    schoolId: schoolId,
    base: base,
    quote: quote,
    effectiveFrom: effectiveFrom,
    rateMicros: rateMicros,
    divergenceBandBp: bandBp,
    setBy: 'directrice',
  );

  setUp(() async {
    db = await openFullOfflineDb();
    dao = ExchangeRateDao(db);
  });
  tearDown(() async => db.close());

  group('replaceForSchool', () {
    test('remplace la série de l\'école, pas celle des autres', () async {
      await dao.replaceForSchool([rate('A')], schoolId: 'A');
      await dao.replaceForSchool([
        rate('B', rateMicros: 2900000000),
      ], schoolId: 'B');

      // Le pull de A repasse sans aucun taux : B ne doit pas bouger.
      await dao.replaceForSchool(const [], schoolId: 'A');

      expect(await dao.ratesForSchool('A'), isEmpty);
      expect((await dao.ratesForSchool('B')).single.rateMicros, 2900000000);
    });

    test('le remplacement est intégral, pas un cumul', () async {
      await dao.replaceForSchool([
        rate('A', effectiveFrom: '2026-09-01T06:00:00Z'),
        rate('A', effectiveFrom: '2026-09-01T12:00:00Z'),
      ], schoolId: 'A');

      await dao.replaceForSchool([
        rate('A', effectiveFrom: '2026-09-02T06:00:00Z'),
      ], schoolId: 'A');

      final series = await dao.ratesForSchool('A');
      expect(series, hasLength(1));
      expect(series.single.effectiveFrom, DateTime.utc(2026, 9, 2, 6));
    });

    test('une école non résolue ne touche à rien', () async {
      // Purger sous la clé vide effacerait la série d'une base héritée.
      await dao.replaceForSchool([rate('A')], schoolId: 'A');

      await dao.replaceForSchool(const [], schoolId: '');

      expect(await dao.ratesForSchool('A'), hasLength(1));
    });

    test(
      'la série garde ses paliers, elle ne se réduit pas au dernier',
      () async {
        await dao.replaceForSchool([
          rate(
            'A',
            effectiveFrom: '2026-09-01T06:00:00Z',
            rateMicros: 2500000000,
          ),
          rate(
            'A',
            effectiveFrom: '2026-09-01T12:00:00Z',
            rateMicros: 2600000000,
          ),
        ], schoolId: 'A');

        expect(await dao.ratesForSchool('A'), hasLength(2));
      },
    );
  });

  group('ratesForSchool', () {
    test('rend la série prête pour le résolveur', () async {
      await dao.replaceForSchool([
        rate(
          'A',
          effectiveFrom: '2026-09-01T06:00:00Z',
          rateMicros: 2500000000,
        ),
        rate(
          'A',
          effectiveFrom: '2026-09-01T12:00:00Z',
          rateMicros: 2600000000,
        ),
      ], schoolId: 'A');

      final resolu = ExchangeRates.at(
        await dao.ratesForSchool('A'),
        base: 'USD',
        quote: 'CDF',
        moment: DateTime.utc(2026, 9, 1, 9),
      );

      expect(resolu?.rateMicros, 2500000000);
    });

    test('une école sans série ne rend rien, et ne lève pas', () async {
      expect(await dao.ratesForSchool('inconnue'), isEmpty);
    });

    test('une école non résolue ne rend rien', () async {
      expect(await dao.ratesForSchool(''), isEmpty);
    });

    test('une ligne à la date illisible est écartée en silence', () async {
      // On ne sait pas quand ce taux vaut : on ne l'applique jamais. La bascule
      // s'éteint, elle ne propose pas un taux mal daté.
      await db.insert('ref_exchange_rates', {
        'school_id': 'A',
        'base': 'USD',
        'quote': 'CDF',
        'effective_from': 'hier matin',
        'rate_micros': 1666670000,
      });

      expect(await dao.ratesForSchool('A'), isEmpty);
    });

    test('un taux nul ou négatif est écarté', () async {
      // Un taux de zéro diviserait de l'argent ; un négatif l'inverserait.
      for (final micros in const [0, -1666670000]) {
        await db.insert('ref_exchange_rates', {
          'school_id': 'A',
          'base': 'USD',
          'quote': 'CDF',
          'effective_from': '2026-09-0${micros == 0 ? 1 : 2}T06:00:00Z',
          'rate_micros': micros,
        });
      }

      expect(await dao.ratesForSchool('A'), isEmpty);
    });

    test('une ligne dont la devise manque est écartée', () async {
      await db.insert('ref_exchange_rates', {
        'school_id': 'A',
        'base': '',
        'quote': 'CDF',
        'effective_from': '2026-09-01T06:00:00Z',
        'rate_micros': 1666670000,
      });

      expect(await dao.ratesForSchool('A'), isEmpty);
    });

    test('une ligne saine survit à ses voisines sales', () async {
      await db.insert('ref_exchange_rates', {
        'school_id': 'A',
        'base': 'USD',
        'quote': 'CDF',
        'effective_from': 'jamais',
        'rate_micros': 1,
      });
      await dao.replaceForSchool([rate('A')], schoolId: 'A');

      // `replaceForSchool` purge d'abord : la ligne sale part avec le reste.
      // Ce que ce test tient, c'est qu'une série mixte se lit sans lever.
      expect((await dao.ratesForSchool('A')).single.rateMicros, 1666670000);
    });

    test('la bande de divergence traverse jusqu\'à l\'entité', () async {
      await dao.replaceForSchool([rate('A', bandBp: 350)], schoolId: 'A');
      expect((await dao.ratesForSchool('A')).single.divergenceBandBp, 350);
    });

    test('une bande absente reste absente — jamais zéro', () async {
      // Zéro signalerait tout ; `null` laisse le contrôle retomber sur son
      // défaut.
      await dao.replaceForSchool([rate('A', bandBp: null)], schoolId: 'A');
      expect((await dao.ratesForSchool('A')).single.divergenceBandBp, isNull);
    });
  });
}
