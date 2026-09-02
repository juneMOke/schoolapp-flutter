import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/exchange_rate_remote_data_source.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../offline_full_db.dart';

class _MockSyncEngine extends Mock implements SyncEngine {}

class _MockRates extends Mock implements ExchangeRateRemoteDataSource {}

/// Le chemin COMPLET du taux : la direction le pose, le guichet le lit.
///
/// C'est ce que les tests d'unité ne prouvaient pas — chacun tenait sa moitié.
/// Entre les deux il y a le **scope école**, lu depuis la session : sans école
/// résolue, l'écriture est refusée et la lecture rend vide, donc la bascule du
/// guichet ne s'allume jamais. C'est exactement le mode de panne qui laisse un
/// écran « sans rien ».
void main() {
  late Database db;
  late CurrentUserContext user;
  late _MockRates rates;
  late FinanceOfflineRepositoryImpl repo;

  setUp(() async {
    db = await openFullOfflineDb();
    user = CurrentUserContext()..set('uid-1', schoolId: 'school-1');
    final engine = _MockSyncEngine();
    when(() => engine.flush()).thenAnswer((_) async => const SyncFlushReport());
    rates = _MockRates();
    when(
      () => rates.publish(
        any(),
        base: any(named: 'base'),
        quote: any(named: 'quote'),
        rateMicros: any(named: 'rateMicros'),
        divergenceBandBp: any(named: 'divergenceBandBp'),
        effectiveFrom: any(named: 'effectiveFrom'),
      ),
    ).thenAnswer((_) async {});
    repo = FinanceOfflineRepositoryImpl(
      dao: FinanceLocalDao(db, const IdGenerator(Uuid())),
      idGenerator: const IdGenerator(Uuid()),
      syncEngine: engine,
      currentUser: user,
      now: () => 1000,
      rates: rates,
      requiredAuth: const {'requiresAuth': true},
    );
  });

  tearDown(() async => db.close());

  test('un taux posé par la direction est lu par le guichet', () async {
    final saved = await repo.saveExchangeRate(
      base: 'USD',
      quote: 'CDF',
      rateMicros: 2850000000,
      effectiveFrom: DateTime.utc(2026, 9, 1, 6),
    );
    expect(saved.isRight(), isTrue);

    final read = await repo.getExchangeRates();
    final rates = read.getOrElse(() => const <ExchangeRate>[]);
    expect(rates, hasLength(1));

    // Et le guichet en tire une bascule : c'est le bout de la chaîne.
    final settlement = TenderSettlement(
      rates: rates,
      at: DateTime.utc(2026, 9, 1, 10),
    );
    expect(settlement.optionsFor('USD'), ['USD', 'CDF']);
  });

  test(
    'poser un taux le PUBLIE chez le serveur — sans quoi le pull l’effacerait',
    () async {
      // Le pull remplace `ref_exchange_rates` en bloc, école par école. Un taux
      // écrit seulement sur la tablette disparaîtrait au premier cycle réussi,
      // et la direction croirait avoir paramétré ce que le guichet n'a jamais
      // eu — sans qu'un mot soit dit.
      await repo.saveExchangeRate(
        base: 'USD',
        quote: 'CDF',
        rateMicros: 2850000000,
        effectiveFrom: DateTime.utc(2026, 9, 1, 6),
        divergenceBandBp: 200,
      );

      verify(
        () => rates.publish(
          any(),
          base: 'USD',
          quote: 'CDF',
          rateMicros: 2850000000,
          divergenceBandBp: 200,
          effectiveFrom: any(named: 'effectiveFrom'),
        ),
      ).called(1);
    },
  );

  test(
    'serveur injoignable : RIEN n’est écrit en local, et l’écran le dit',
    () async {
      when(
        () => rates.publish(
          any(),
          base: any(named: 'base'),
          quote: any(named: 'quote'),
          rateMicros: any(named: 'rateMicros'),
          divergenceBandBp: any(named: 'divergenceBandBp'),
          effectiveFrom: any(named: 'effectiveFrom'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      );

      final saved = await repo.saveExchangeRate(
        base: 'USD',
        quote: 'CDF',
        rateMicros: 2850000000,
        effectiveFrom: DateTime.utc(2026, 9, 1, 6),
      );

      expect(saved.isLeft(), isTrue);
      expect(
        await db.query('ref_exchange_rates'),
        isEmpty,
        reason:
            'un taux affiché comme posé mais absent du serveur est pire que pas '
            'de taux du tout : il disparaît au prochain cycle',
      );
    },
  );

  test('403 : le refus nomme le droit, il ne parle pas de réseau', () async {
    when(
      () => rates.publish(
        any(),
        base: any(named: 'base'),
        quote: any(named: 'quote'),
        rateMicros: any(named: 'rateMicros'),
        divergenceBandBp: any(named: 'divergenceBandBp'),
        effectiveFrom: any(named: 'effectiveFrom'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 403,
        ),
      ),
    );

    final saved = await repo.saveExchangeRate(
      base: 'USD',
      quote: 'CDF',
      rateMicros: 2850000000,
      effectiveFrom: DateTime.utc(2026, 9, 1, 6),
    );

    saved.fold(
      (failure) => expect(failure.message, contains('ne peut pas poser')),
      (_) => fail('attendu Left'),
    );
  });

  test('sans école résolue, l’écriture est refusée — et le dit', () async {
    // Le mode de panne silencieux qu'on veut rendre bruyant : une session sans
    // `schoolId` (backend hérité, claim absent) ne peut pas paramétrer de taux.
    // Refuser AVEC un message vaut mieux qu'écrire sous la clé vide, où la
    // lecture scopée ne retrouverait jamais la ligne.
    user.set('uid-1');

    final saved = await repo.saveExchangeRate(
      base: 'USD',
      quote: 'CDF',
      rateMicros: 2850000000,
      effectiveFrom: DateTime.utc(2026, 9, 1, 6),
    );

    expect(saved.isLeft(), isTrue);
    expect(await db.query('ref_exchange_rates'), isEmpty);
  });

  test('un taux d’une autre école ne remonte pas au guichet', () async {
    await repo.saveExchangeRate(
      base: 'USD',
      quote: 'CDF',
      rateMicros: 2850000000,
      effectiveFrom: DateTime.utc(2026, 9, 1, 6),
    );

    user.set('uid-2', schoolId: 'school-2');
    final read = await repo.getExchangeRates();

    expect(read.getOrElse(() => const []), isEmpty);
  });

  test('deux paliers cohabitent, le guichet lit celui de l’heure', () async {
    await repo.saveExchangeRate(
      base: 'USD',
      quote: 'CDF',
      rateMicros: 2850000000,
      effectiveFrom: DateTime.utc(2026, 9, 1, 6),
    );
    await repo.saveExchangeRate(
      base: 'USD',
      quote: 'CDF',
      rateMicros: 2900000000,
      effectiveFrom: DateTime.utc(2026, 9, 1, 12),
    );

    final rates = (await repo.getExchangeRates()).getOrElse(() => const []);
    expect(rates, hasLength(2));
    expect(
      ExchangeRates.at(
        rates,
        base: 'USD',
        quote: 'CDF',
        moment: DateTime.utc(2026, 9, 1, 9),
      )?.rateMicros,
      2850000000,
    );
  });
}
