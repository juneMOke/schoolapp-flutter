import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

import 'offline_test_db.dart';

class MockConnectivity extends Mock implements Connectivity {}

/// Handler configurable qui enregistre l'ordre global de dispatch.
class RecordingHandler implements OutboxSyncHandler {
  RecordingHandler(this.aggregateType, this._result, this.log);

  @override
  final String aggregateType;
  final OutboxDispatchResult _result;
  final List<String> log;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    log.add(entry.id);
    return _result;
  }
}

/// Handler qui lève, pour vérifier la conversion en retry.
class ThrowingHandler implements OutboxSyncHandler {
  @override
  String get aggregateType => 'BOOM';

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    throw StateError('réseau coupé');
  }
}

void main() {
  late Database db;
  late OutboxDao dao;
  late MockConnectivity connectivity;
  late ConnectivityService connectivityService;

  const int fixedNow = 100000;

  OutboxEntry entry({
    required String id,
    String type = 'ENROLLMENT',
    int createdAt = 1000,
    int attempts = 0,
  }) => OutboxEntry(
    id: id,
    aggregateType: type,
    aggregateId: 'agg-$id',
    operation: OutboxOperation.create,
    payload: '{}',
    createdAt: createdAt,
    attempts: attempts,
  );

  SyncEngine buildEngine({int maxAttempts = 50}) => SyncEngine(
    outbox: dao,
    connectivity: connectivityService,
    now: () => fixedNow,
    maxAttempts: maxAttempts,
  );

  void goOnline() {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
  }

  void goOffline() {
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);
  }

  setUp(() async {
    db = await openInMemoryOfflineDb();
    dao = OutboxDao(db);
    connectivity = MockConnectivity();
    connectivityService = ConnectivityService(connectivity);
  });

  tearDown(() async {
    await db.close();
  });

  test('hors ligne : ne dispatch rien', () async {
    goOffline();
    await dao.enqueue(entry(id: 'e1'));
    final engine = buildEngine();
    final report = await engine.flush();
    expect(report.offline, isTrue);
    expect(await dao.pendingCount(), 1);
  });

  test('acked : marque ACKED et retire du pending', () async {
    goOnline();
    await dao.enqueue(entry(id: 'e1'));
    final engine = buildEngine()
      ..registerHandler(
        RecordingHandler('ENROLLMENT', const OutboxDispatchResult.acked(), []),
      );
    final report = await engine.flush();
    expect(report.acked, 1);
    expect(await dao.pendingCount(), 0);
  });

  test('retry : reste PENDING avec backoff et attempts++', () async {
    goOnline();
    await dao.enqueue(entry(id: 'e1', attempts: 0));
    final engine = buildEngine()
      ..registerHandler(
        RecordingHandler(
          'ENROLLMENT',
          const OutboxDispatchResult.retry('timeout'),
          [],
        ),
      );
    final report = await engine.flush();
    expect(report.retried, 1);

    final rows = await db.query('outbox', where: 'id = ?', whereArgs: ['e1']);
    expect(rows.first['status'], OutboxStatus.pending.dbValue);
    expect(rows.first['attempts'], 1);
    // Barrière repoussée dans le futur (now + backoff(1) = 100000 + 2000).
    expect(rows.first['next_attempt_at'], fixedNow + SyncEngine.backoffMs(1));
    expect(rows.first['last_error'], 'timeout');
  });

  test(
    'blocked : reste PENDING, délai fixe, SANS attempts++ ni poison',
    () async {
      goOnline();
      // attempts DÉJÀ au-delà du seuil poison : un `retry` basculerait en
      // SYNC_ERROR ; un `blocked` (attente d'une dépendance) ne doit JAMAIS
      // poisonner ni consommer de tentative (FRONT §6.3).
      await dao.enqueue(entry(id: 'e1', attempts: 60));
      final engine = buildEngine(maxAttempts: 50)
        ..registerHandler(
          RecordingHandler(
            'ENROLLMENT',
            const OutboxDispatchResult.blocked('inscription non ACKED'),
            [],
          ),
        );
      final report = await engine.flush();
      expect(report.blocked, 1);
      expect(report.poisoned, 0);

      final rows = await db.query('outbox', where: 'id = ?', whereArgs: ['e1']);
      expect(rows.first['status'], OutboxStatus.pending.dbValue);
      expect(rows.first['attempts'], 60, reason: 'aucune tentative consommée');
      expect(rows.first['next_attempt_at'], fixedNow + 5000);
      expect(rows.first['last_error'], 'inscription non ACKED');
    },
  );

  test('failed : passe SYNC_ERROR (rejet métier)', () async {
    goOnline();
    await dao.enqueue(entry(id: 'e1'));
    final engine = buildEngine()
      ..registerHandler(
        RecordingHandler(
          'ENROLLMENT',
          const OutboxDispatchResult.failed('champ requis'),
          [],
        ),
      );
    final report = await engine.flush();
    expect(report.failed, 1);
    final rows = await db.query('outbox', where: 'id = ?', whereArgs: ['e1']);
    expect(rows.first['status'], OutboxStatus.syncError.dbValue);
  });

  test('handler qui lève est traité en retry', () async {
    goOnline();
    await dao.enqueue(entry(id: 'e1', type: 'BOOM'));
    final engine = buildEngine()..registerHandler(ThrowingHandler());
    final report = await engine.flush();
    expect(report.retried, 1);
    expect(await dao.pendingCount(), 1); // toujours en attente
  });

  test('FIFO : ENROLLMENT (créé avant) est dispatché avant PAYMENT', () async {
    goOnline();
    final log = <String>[];
    // Inséré dans le désordre ; l'ordre de dispatch suit created_at.
    await dao.enqueue(entry(id: 'pay', type: 'PAYMENT', createdAt: 3000));
    await dao.enqueue(entry(id: 'enr', type: 'ENROLLMENT', createdAt: 1000));
    final engine = buildEngine()
      ..registerHandler(
        RecordingHandler('ENROLLMENT', const OutboxDispatchResult.acked(), log),
      )
      ..registerHandler(
        RecordingHandler('PAYMENT', const OutboxDispatchResult.acked(), log),
      );
    await engine.flush();
    expect(log, ['enr', 'pay']);
  });

  test('sans handler : entrée laissée PENDING, comptée noHandler', () async {
    goOnline();
    await dao.enqueue(entry(id: 'e1', type: 'UNKNOWN'));
    final engine = buildEngine();
    final report = await engine.flush();
    expect(report.noHandler, 1);
    expect(await dao.pendingCount(), 1);
  });

  test(
    'poison : au-delà de maxAttempts → SYNC_ERROR (plus de retry)',
    () async {
      goOnline();
      // attempts déjà à 2 ; maxAttempts=2 → la prochaine tentative (3) dépasse.
      await dao.enqueue(entry(id: 'e1', attempts: 2));
      final engine = buildEngine(maxAttempts: 2)
        ..registerHandler(
          RecordingHandler(
            'ENROLLMENT',
            const OutboxDispatchResult.retry('timeout'),
            [],
          ),
        );
      final report = await engine.flush();
      expect(report.poisoned, 1);
      expect(report.retried, 0);
      final rows = await db.query('outbox', where: 'id = ?', whereArgs: ['e1']);
      expect(rows.first['status'], OutboxStatus.syncError.dbValue);
      expect(rows.first['last_error'], contains('poison'));
    },
  );

  test('en dessous du seuil : reste en retry (non poisonné)', () async {
    goOnline();
    await dao.enqueue(entry(id: 'e1', attempts: 1));
    final engine = buildEngine(maxAttempts: 5)
      ..registerHandler(
        RecordingHandler(
          'ENROLLMENT',
          const OutboxDispatchResult.retry('timeout'),
          [],
        ),
      );
    final report = await engine.flush();
    expect(report.retried, 1);
    expect(report.poisoned, 0);
    final rows = await db.query('outbox', where: 'id = ?', whereArgs: ['e1']);
    expect(rows.first['status'], OutboxStatus.pending.dbValue);
  });

  test('purge : une entrée ACKED est supprimée après le flush', () async {
    goOnline();
    await dao.enqueue(entry(id: 'e1'));
    final engine = buildEngine()
      ..registerHandler(
        RecordingHandler('ENROLLMENT', const OutboxDispatchResult.acked(), []),
      );
    await engine.flush();
    final rows = await db.query('outbox', where: 'id = ?', whereArgs: ['e1']);
    expect(rows, isEmpty);
  });

  test('flush concurrent : le second est skipped', () async {
    goOnline();
    final engine = buildEngine()
      ..registerHandler(
        RecordingHandler('ENROLLMENT', const OutboxDispatchResult.acked(), []),
      );
    final first = engine.flush();
    final second = engine.flush();
    final results = await Future.wait([first, second]);
    // L'un des deux au moins est skipped (verrou _flushing).
    expect(results.where((r) => r.skipped), hasLength(1));
  });

  group('backoffMs', () {
    test('exponentiel borné', () {
      expect(SyncEngine.backoffMs(0), 1000);
      expect(SyncEngine.backoffMs(1), 2000);
      expect(SyncEngine.backoffMs(2), 4000);
      expect(SyncEngine.backoffMs(20), lessThanOrEqualTo(300000));
      expect(SyncEngine.backoffMs(20), SyncEngine.backoffMs(8));
    });
  });
}
