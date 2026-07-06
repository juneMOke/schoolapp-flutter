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

  SyncEngine buildEngine() => SyncEngine(
    outbox: dao,
    connectivity: connectivityService,
    now: () => fixedNow,
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
