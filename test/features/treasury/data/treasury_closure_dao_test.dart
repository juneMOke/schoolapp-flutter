import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/treasury/data/local/treasury_closure_dao.dart';
import 'package:school_app_flutter/features/treasury/data/sync/treasury_closure_puller.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_closure.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../offline_full_db.dart';

/// Jeudi 22 octobre 2026, 15 h à Kinshasa.
final _thursday = DateTime.utc(2026, 10, 22, 14);

CashClosure _closure(
  String id, {
  TreasuryCurrency currency = TreasuryCurrency.usd,
  DateTime? day,
  DateTime? reopenedAt,
}) => CashClosure(
  id: id,
  registerId: 'reg-${currency.code}',
  currency: currency,
  cashDay: day ?? DateTime(2026, 10, 22),
  closedAt: DateTime.utc(2026, 10, 22, 16, 45),
  closedByName: 'Ilunga Céline',
  closedByRole: 'ACCOUNTANT',
  matches: true,
  expectedInCents: 1000,
  declaredInCents: 1000,
  gapInCents: 0,
  reopenedAt: reopenedAt,
);

void main() {
  late Database db;
  late CurrentUserContext user;
  late TreasuryClosureDao dao;
  var now = _thursday;

  setUp(() async {
    db = await openTenantTestDb();
    user = CurrentUserContext()..set('u1', schoolId: 'school-1');
    now = _thursday;
    dao = TreasuryClosureDao(db, user, now: () => now);
  });
  tearDown(() => db.close());

  test('rien de clos : le guichet est ouvert', () async {
    expect(await dao.closedToday(), isEmpty);
  });

  test(
    'la caisse USD close aujourd hui retient les dollars seulement',
    () async {
      await dao.recordLocal([_closure('c1')]);
      expect(await dao.closedToday(), {'USD'});
    },
  );

  test('une clôture d hier ne retient rien aujourd hui', () async {
    await dao.recordLocal([_closure('c1', day: DateTime(2026, 10, 21))]);
    expect(await dao.closedToday(), isEmpty);
  });

  test('une réouverture redescend sur la même clôture et libère', () async {
    await dao.recordLocal([_closure('c1')]);
    await dao.recordLocal([
      _closure('c1', reopenedAt: DateTime.utc(2026, 10, 22, 17)),
    ]);
    expect(await dao.closedToday(), isEmpty);
  });

  test('rouverte puis reclôturée : la nouvelle clôture retient', () async {
    await dao.recordLocal([
      _closure('c1', reopenedAt: DateTime.utc(2026, 10, 22, 17)),
      _closure('c2'),
    ]);
    expect(await dao.closedToday(), {'USD'});
  });

  test(
    'servie ouverte en ligne : le verrou tombe sans attendre le flux',
    () async {
      await dao.recordLocal([_closure('c1')]);
      now = _thursday.add(const Duration(minutes: 5));
      await dao.recordRead(
        DateTime(2026, 10, 22),
        live: const [],
        openRegisterIds: ['reg-USD'],
        readStartedMs: dao.nowMs(),
      );
      expect(await dao.closedToday(), isEmpty);
    },
  );

  test('une lecture partie AVANT un tirage ne lève pas la clôture qu il a '
      'apportée', () async {
    final readStartedMs = dao.nowMs(); // la lecture part…
    now = _thursday.add(const Duration(seconds: 2));
    await dao.applyPulled(
      [_closure('c1')],
      schoolId: 'school-1',
      nowMs: dao.nowMs(),
    ); // …le flux descend la clôture faite ailleurs…
    await dao.recordRead(
      DateTime(2026, 10, 22),
      live: const [],
      openRegisterIds: ['reg-USD'],
      readStartedMs: readStartedMs,
    ); // …et la réponse, plus ancienne, arrive après.
    expect(await dao.closedToday(), {'USD'});
  });

  test('une recopie plus ancienne ne défait jamais une réouverture', () async {
    await dao.recordLocal([
      _closure('c1', reopenedAt: DateTime.utc(2026, 10, 22, 17)),
    ]);
    await dao.recordRead(
      DateTime(2026, 10, 22),
      live: [_closure('c1')],
      openRegisterIds: const [],
      readStartedMs: 0,
    );
    expect(await dao.closedToday(), isEmpty);
  });

  test('servie ouverte : seule la journée lue est touchée', () async {
    await dao.recordLocal([_closure('c1', day: DateTime(2026, 10, 21))]);
    now = _thursday.add(const Duration(minutes: 5));
    await dao.recordRead(
      DateTime(2026, 10, 22),
      live: const [],
      openRegisterIds: ['reg-USD'],
      readStartedMs: dao.nowMs(),
    );
    final rows = await db.query('treasury_closures');
    expect(rows.single['reopened_at'], isNull);
  });

  test('une autre école ne retient pas celle-ci', () async {
    await dao.applyPulled([_closure('c1')], schoolId: 'school-2', nowMs: 0);
    expect(await dao.closedToday(), isEmpty);
  });

  test('un dimanche compte pour le lundi, comme côté serveur', () async {
    await dao.recordLocal([_closure('c1', day: DateTime(2026, 10, 26))]);
    now = DateTime.utc(2026, 10, 25, 10); // dimanche, 11 h à Kinshasa
    expect(await dao.closedToday(), {'USD'});
  });

  test('une page du flux saute la ligne illisible, garde les autres', () {
    final page = TreasuryClosurePageDto.fromJson({
      'items': [
        {'id': 'broken'},
        {
          'id': 'c1',
          'registerId': 'reg-USD',
          'currency': 'USD',
          'cashDay': '2026-10-22',
          'closedAt': '2026-10-22T16:45:00Z',
          'closedByName': 'Ilunga Céline',
          'closedByRole': 'ACCOUNTANT',
          'matches': true,
          'expectedInCents': 1000,
          'declaredInCents': 1000,
          'gapInCents': 0,
        },
      ],
      'hasMore': false,
      'serverTime': '2026-10-22T17:00:00Z',
    });
    expect(page.items.map((c) => c.id), ['c1']);
    expect(page.skipped, 1);
  });
}
