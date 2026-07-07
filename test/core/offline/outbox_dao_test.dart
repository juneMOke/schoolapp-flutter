import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

import 'offline_test_db.dart';

void main() {
  late Database db;
  late OutboxDao dao;

  OutboxEntry entry({
    required String id,
    String type = 'ENROLLMENT',
    String aggregateId = 'agg-1',
    int createdAt = 1000,
    int nextAttemptAt = 0,
    OutboxStatus status = OutboxStatus.pending,
    int attempts = 0,
    String? schoolId,
  }) => OutboxEntry(
    id: id,
    aggregateType: type,
    aggregateId: aggregateId,
    operation: OutboxOperation.create,
    payload: '{"k":"v"}',
    createdAt: createdAt,
    nextAttemptAt: nextAttemptAt,
    status: status,
    attempts: attempts,
    schoolId: schoolId,
  );

  setUp(() async {
    db = await openInMemoryOfflineDb();
    dao = OutboxDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('enqueue puis pendingReady retourne l\'entrée', () async {
    await dao.enqueue(entry(id: 'e1'));
    final pending = await dao.pendingReady(2000);
    expect(pending, hasLength(1));
    expect(pending.first.id, 'e1');
    expect(pending.first.status, OutboxStatus.pending);
  });

  test('toMap/fromMap conserve tous les champs (round-trip DB)', () async {
    final original = entry(
      id: 'e-rt',
      aggregateId: 'agg-rt',
      attempts: 3,
      schoolId: 'school-42',
    );
    await dao.enqueue(original);
    final loaded = (await dao.pendingReady(2000)).first;
    expect(loaded.aggregateId, 'agg-rt');
    expect(loaded.attempts, 3);
    expect(loaded.schoolId, 'school-42');
    expect(loaded.operation, OutboxOperation.create);
    expect(loaded.payload, '{"k":"v"}');
  });

  test('pendingReady ordonne en FIFO par created_at', () async {
    await dao.enqueue(entry(id: 'later', createdAt: 3000));
    await dao.enqueue(entry(id: 'earlier', createdAt: 1000));
    await dao.enqueue(entry(id: 'middle', createdAt: 2000));
    final pending = await dao.pendingReady(5000);
    expect(pending.map((e) => e.id), ['earlier', 'middle', 'later']);
  });

  test(
    'pendingReady respecte la barrière de backoff (next_attempt_at)',
    () async {
      await dao.enqueue(entry(id: 'ready', nextAttemptAt: 500));
      await dao.enqueue(entry(id: 'gated', nextAttemptAt: 9000));
      final pending = await dao.pendingReady(1000);
      expect(pending.map((e) => e.id), ['ready']);
    },
  );

  test('markAcked sort l\'entrée du pending', () async {
    await dao.enqueue(entry(id: 'e1'));
    await dao.markAcked('e1');
    expect(await dao.pendingReady(2000), isEmpty);
    expect(await dao.pendingCount(), 0);
  });

  test('markSyncError passe l\'entrée en SYNC_ERROR avec message', () async {
    await dao.enqueue(entry(id: 'e1'));
    await dao.markSyncError('e1', 'champ requis manquant');
    final rows = await db.query('outbox', where: 'id = ?', whereArgs: ['e1']);
    expect(rows.first['status'], OutboxStatus.syncError.dbValue);
    expect(rows.first['last_error'], 'champ requis manquant');
    expect(await dao.pendingReady(2000), isEmpty);
  });

  test(
    'reschedule garde PENDING, incrémente attempts et repousse la barrière',
    () async {
      await dao.enqueue(entry(id: 'e1'));
      await dao.reschedule(
        'e1',
        attempts: 2,
        nextAttemptAt: 8000,
        lastError: 'net',
      );
      // Non prête à t=5000 (barrière 8000), prête à t=9000.
      expect(await dao.pendingReady(5000), isEmpty);
      final ready = await dao.pendingReady(9000);
      expect(ready, hasLength(1));
      expect(ready.first.attempts, 2);
      expect(ready.first.lastError, 'net');
    },
  );

  test('pendingReadyForSchool filtre par tenant', () async {
    await dao.enqueue(entry(id: 'a', schoolId: 'S1'));
    await dao.enqueue(entry(id: 'b', schoolId: 'S2'));
    final s1 = await dao.pendingReadyForSchool('S1', 2000);
    expect(s1.map((e) => e.id), ['a']);
  });

  test('pendingCount et deleteAcked', () async {
    await dao.enqueue(entry(id: 'a'));
    await dao.enqueue(entry(id: 'b'));
    expect(await dao.pendingCount(), 2);
    await dao.markAcked('a');
    expect(await dao.pendingCount(), 1);
    final deleted = await dao.deleteAcked();
    expect(deleted, 1);
  });

  test('errorCount ne compte que les entrées en SYNC_ERROR', () async {
    await dao.enqueue(entry(id: 'a'));
    await dao.enqueue(entry(id: 'b'));
    await dao.enqueue(entry(id: 'c'));
    expect(await dao.errorCount(), 0);
    await dao.markSyncError('a', 'rejet');
    await dao.markSyncError('b', 'rejet');
    expect(await dao.errorCount(), 2);
    // pendingCount et errorCount sont disjoints.
    expect(await dao.pendingCount(), 1);
  });

  test('enqueue avec même id remplace (idempotence de re-enqueue)', () async {
    await dao.enqueue(entry(id: 'e1', attempts: 0));
    await dao.enqueue(entry(id: 'e1', attempts: 5));
    final rows = await db.query('outbox', where: 'id = ?', whereArgs: ['e1']);
    expect(rows, hasLength(1));
    expect(rows.first['attempts'], 5);
  });
}
