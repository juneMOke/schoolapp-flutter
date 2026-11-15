import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/treasury/data/local/treasury_closure_dao.dart';
import 'package:school_app_flutter/features/treasury/data/online/treasury_day_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_day_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../offline_full_db.dart';
import '../treasury_fixtures.dart';

class _MockApi extends Mock implements TreasuryDayApi {}

/// Le verrou des encaissements suit chaque lecture en ligne d'aujourd'hui :
/// une clôture lue le pose, une caisse servie ouverte le lève.
void main() {
  late Database db;
  late _MockApi api;
  late TreasuryClosureDao dao;
  late TreasuryDayRepositoryImpl repository;
  var tick = 0;

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() async {
    db = await openTenantTestDb();
    api = _MockApi();
    dao = TreasuryClosureDao(
      db,
      CurrentUserContext()..set('u1', schoolId: 'school-1'),
      // Une horloge qui avance : une lecture part toujours après ce qui a été
      // écrit avant elle.
      now: () => DateTime.utc(2026, 10, 22, 17).add(Duration(seconds: tick++)),
    );
    repository = TreasuryDayRepositoryImpl(api, closures: dao);
  });
  tearDown(() => db.close());

  test('la journée lue avec la caisse CDF close pose le verrou', () async {
    when(() => api.day(any())).thenAnswer(
      (_) async => treasuryDay([usdDay(), cdfDay(closure: closedWithGap)]),
    );
    await repository.day(demoDay);
    expect(await dao.closedToday(), {'CDF'});
  });

  test('rouverte ailleurs : la relecture lève le verrou', () async {
    await dao.recordLocal([closedWithGap]);
    when(
      () => api.day(any()),
    ).thenAnswer((_) async => treasuryDay([usdDay(), cdfDay()]));
    await repository.day(demoDay);
    expect(await dao.closedToday(), isEmpty);
  });

  test('une lecture qui échoue ne touche pas au verrou', () async {
    await dao.recordLocal([closedWithGap]);
    when(() => api.day(any())).thenAnswer(
      (_) => Future.error(
        DioException(requestOptions: RequestOptions(path: '/x')),
      ),
    );
    await repository.day(demoDay);
    expect(await dao.closedToday(), {'CDF'});
  });

  test('une clôture faite ici pose le verrou sans attendre le flux', () async {
    when(
      () => api.close(
        any(),
        id: any(named: 'id'),
        registerId: any(named: 'registerId'),
        matches: any(named: 'matches'),
        shownExpectedInCents: any(named: 'shownExpectedInCents'),
        declaredAmountInCents: any(named: 'declaredAmountInCents'),
        justification: any(named: 'justification'),
      ),
    ).thenAnswer((_) async => closedWithGap);
    await repository.close(
      demoDay,
      id: 'u1',
      registerId: 'reg-cdf',
      matches: false,
      shownExpectedInCents: 345000000,
      declaredAmountInCents: 344500000,
      justification: 'Erreur de rendu de monnaie',
    );
    expect(await dao.closedToday(), {'CDF'});
  });

  test(
    '« déjà clôturée » : la clôture que porte le refus pose le verrou',
    () async {
      when(
        () => api.close(
          any(),
          id: any(named: 'id'),
          registerId: any(named: 'registerId'),
          matches: any(named: 'matches'),
          shownExpectedInCents: any(named: 'shownExpectedInCents'),
          declaredAmountInCents: any(named: 'declaredAmountInCents'),
          justification: any(named: 'justification'),
        ),
      ).thenAnswer(
        (_) => Future.error(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            response: Response(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: 409,
              data: {
                'detailCode': 'CASH_DAY_ALREADY_CLOSED',
                'closure': {
                  'id': 'clo-1',
                  'registerId': 'reg-cdf',
                  'currency': 'CDF',
                  'cashDay': '2026-10-22',
                  'closedAt': '2026-10-22T16:45:00Z',
                  'closedByName': 'Ilunga Céline',
                  'closedByRole': 'ACCOUNTANT',
                  'matches': true,
                  'expectedInCents': 345000000,
                  'declaredInCents': 345000000,
                  'gapInCents': 0,
                },
              },
            ),
          ),
        ),
      );
      final result = await repository.close(
        demoDay,
        id: 'u1',
        registerId: 'reg-cdf',
        matches: true,
        shownExpectedInCents: 345000000,
      );
      expect(result.isLeft(), isTrue);
      expect(await dao.closedToday(), {'CDF'});
    },
  );
}
