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

  test('markAcked gardé par created_at : n\'acquitte PAS une entrée ré-enfilée '
      'en vol (anti-TOCTOU)', () async {
    // Dispatch en cours sur l'entrée created_at=1000.
    await dao.enqueue(entry(id: 'agg', createdAt: 1000));
    // Pendant le dispatch, une nouvelle écriture ré-enfile le MÊME id
    // (ConflictAlgorithm.replace) avec un nouveau created_at → PENDING.
    await dao.enqueue(entry(id: 'agg', createdAt: 2000));
    // L'ACK du dispatch en vol tente d'acquitter l'ancienne version.
    await dao.markAcked('agg', expectedCreatedAt: 1000);
    // La garde protège l'entrée fraîche : elle reste PENDING (re-poussable).
    final pending = await dao.pendingReady(5000);
    expect(pending, hasLength(1));
    expect(pending.first.createdAt, 2000);
    expect(await dao.pendingCount(), 1);
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

  group('reprise manuelle d\'une entrée terminale', () {
    test(
      'errors() ne remonte que les SYNC_ERROR, plus récent d\'abord',
      () async {
        await dao.enqueue(entry(id: 'ok', createdAt: 1000));
        await dao.enqueue(entry(id: 'vieux', createdAt: 1000));
        await dao.enqueue(entry(id: 'recent', createdAt: 3000));
        await dao.markSyncError('vieux', 'rejet A');
        await dao.markSyncError('recent', 'rejet B');

        final errors = await dao.errors();
        expect(errors.map((e) => e.id), ['recent', 'vieux']);
        expect(errors.first.lastError, 'rejet B');
      },
    );

    test(
      'requeue remet en PENDING et efface backoff/tentatives/erreur',
      () async {
        await dao.enqueue(entry(id: 'e1'));
        await dao.reschedule(
          'e1',
          attempts: 7,
          nextAttemptAt: 999999,
          lastError: 'réseau',
        );
        await dao.markSyncError('e1', 'rejet métier');

        expect(await dao.requeue('e1'), 1);

        final rows = await db.query(
          'outbox',
          where: 'id = ?',
          whereArgs: ['e1'],
        );
        expect(rows.first['status'], OutboxStatus.pending.dbValue);
        expect(rows.first['attempts'], 0);
        expect(rows.first['next_attempt_at'], 0);
        expect(rows.first['last_error'], isNull);
        // Et elle repart bien au prochain flush.
        expect((await dao.pendingReady(0)).map((e) => e.id), ['e1']);
      },
    );

    test(
      'requeue est un no-op sur une entrée PENDING (pas de reset du backoff)',
      () async {
        await dao.enqueue(entry(id: 'e1'));
        await dao.reschedule(
          'e1',
          attempts: 3,
          nextAttemptAt: 999999,
          lastError: 'réseau',
        );

        expect(await dao.requeue('e1'), 0);

        final rows = await db.query(
          'outbox',
          where: 'id = ?',
          whereArgs: ['e1'],
        );
        expect(rows.first['attempts'], 3);
        expect(rows.first['next_attempt_at'], 999999);
      },
    );

    test(
      'ré-enfiler le même id sort une entrée de SYNC_ERROR (chemin de reprise '
      'par ré-écriture)',
      () async {
        // Invariant dont dépend toute la reprise « rouvrez la journée et
        // revalidez » : pour les agrégats à id déterministe, refaire le geste
        // métier doit ramener l'entrée terminale en file, sans requeue manuel.
        await dao.enqueue(entry(id: 'ATTENDANCE:c1|2026-06-15|y1'));
        await dao.markSyncError('ATTENDANCE:c1|2026-06-15|y1', 'superseded');
        expect(await dao.errorCount(), 1);

        await dao.enqueue(
          entry(id: 'ATTENDANCE:c1|2026-06-15|y1', createdAt: 9000),
        );

        expect(await dao.errorCount(), 0);
        expect(await dao.pendingCount(), 1);
        final ready = await dao.pendingReady(999999);
        expect(ready.single.lastError, isNull);
        expect(ready.single.attempts, 0);
      },
    );

    test('une entrée en erreur n\'est jamais supprimée du socle', () async {
      // Garde-fou de conception : supprimer une entrée détruirait son
      // `aggregate_id`, seule clé d'idempotence du contrat, et laisserait
      // l'agrégat local en PENDING_SYNC — donc immunisé contre le pull.
      // `deleteAcked` ne doit toucher QUE les entrées acquittées.
      await dao.enqueue(entry(id: 'ko'));
      await dao.markSyncError('ko', 'rejet');

      expect(await dao.deleteAcked(), 0);
      expect(await dao.errorCount(), 1);
    });
  });
}
