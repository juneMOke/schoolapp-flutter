import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

/// Fabrique un OutboxEntry de test (payload arbitraire — la couche wire est
/// livrée aux lots push NF-5/6). L'id est déterministe pour asserter le
/// coalescing sur `aggregate_id`.
OutboxEntry _entry({
  required String id,
  required String type,
  required String aggregateId,
  required OutboxOperation op,
  String payload = '{}',
}) => OutboxEntry(
  id: id,
  aggregateType: type,
  aggregateId: aggregateId,
  operation: op,
  payload: payload,
  createdAt: 1000,
);

void main() {
  late Database db;
  late AcademicsLocalDataSource local;
  late OutboxDao outbox;

  setUp(() async {
    db = await openFullOfflineDb();
    local = AcademicsLocalDataSource(db);
    outbox = OutboxDao(db);
  });

  tearDown(() async => db.close());

  EvaluationRow evalRow({
    int updatedAt = 1000,
    String status = 'PENDING_SYNC',
  }) => EvaluationRow(
    id: 'ev-1',
    coursId: 'c-1',
    type: 'INTERRO',
    evalDate: 500,
    maxPoints: 20,
    poids: 1,
    sousPeriodeId: 'sp-1',
    updatedAt: updatedAt,
    syncStatus: status,
  );

  NoteEvaluationRow note(
    String studentId, {
    required String id,
    double? points,
    String statut = 'NOTEE',
    int updatedAt = 1000,
  }) => NoteEvaluationRow(
    id: id,
    evaluationId: 'ev-1',
    studentId: studentId,
    pointsObtenus: points,
    statut: statut,
    updatedAt: updatedAt,
  );

  group('createEvaluationWithOutbox (régime A)', () {
    test(
      'INSERT évaluation PENDING_SYNC + entrée outbox CREATE, 1 txn',
      () async {
        await local.createEvaluationWithOutbox(
          row: evalRow(),
          outboxEntry: _entry(
            id: 'obx-ev-1',
            type: 'ACADEMICS_EVALUATION',
            aggregateId: 'ev-1',
            op: OutboxOperation.create,
          ),
        );

        final stored = await local.getEvaluation('ev-1');
        expect(stored, isNotNull);
        expect(stored!.syncState, SyncState.pendingSync);

        final pending = await outbox.pendingReady(2000);
        expect(pending.length, 1);
        expect(pending.single.aggregateType, 'ACADEMICS_EVALUATION');
        expect(pending.single.aggregateId, 'ev-1');
      },
    );

    test('idempotent sur l\'uuid client (rejeu ne duplique pas)', () async {
      await local.createEvaluationWithOutbox(
        row: evalRow(),
        outboxEntry: _entry(
          id: 'obx-ev-1',
          type: 'ACADEMICS_EVALUATION',
          aggregateId: 'ev-1',
          op: OutboxOperation.create,
        ),
      );
      await local.createEvaluationWithOutbox(
        row: evalRow(),
        outboxEntry: _entry(
          id: 'obx-ev-1',
          type: 'ACADEMICS_EVALUATION',
          aggregateId: 'ev-1',
          op: OutboxOperation.create,
        ),
      );

      final all = await db.query('evaluation');
      expect(all.length, 1);
      final pending = await outbox.pendingReady(2000);
      expect(pending.length, 1);
    });
  });

  group('upsertNotesWithOutbox (régime C, LWW, coalescing)', () {
    Future<List<NoteEvaluationRow>> save(
      List<NoteEvaluationRow> notes, {
      String entryId = 'obx-notes-1',
    }) => local.upsertNotesWithOutbox(
      evaluationId: 'ev-1',
      incoming: notes,
      buildOutboxEntry: (pending) => _entry(
        id: entryId,
        type: 'ACADEMICS_NOTES_BATCH',
        aggregateId: 'ev-1',
        op: OutboxOperation.upsert,
      ),
    );

    test(
      'insère les notes PENDING_SYNC + une entrée outbox coalescée',
      () async {
        final pending = await save([
          note('s1', id: 'n1', points: 12),
          note('s2', id: 'n2', points: 15),
        ]);

        expect(pending.length, 2);
        final stored = await local.getNotesForEvaluation('ev-1');
        expect(stored.length, 2);
        expect(
          stored.every((n) => n.syncState == SyncState.pendingSync),
          isTrue,
        );

        final obx = await outbox.pendingReady(2000);
        expect(obx.length, 1);
        expect(obx.single.aggregateId, 'ev-1');
      },
    );

    test(
      'LWW : une correction plus récente écrase, une note stale est ignorée',
      () async {
        await save([note('s1', id: 'n1', points: 10, updatedAt: 1000)]);

        // Correction plus récente → appliquée.
        await save([note('s1', id: 'n1b', points: 18, updatedAt: 2000)]);
        var stored = await local.getNotesForEvaluation('ev-1');
        expect(stored.single.pointsObtenus, 18);

        // Note stale (updatedAt plus ancien) → ignorée.
        await save([note('s1', id: 'n1c', points: 5, updatedAt: 1500)]);
        stored = await local.getNotesForEvaluation('ev-1');
        expect(stored.single.pointsObtenus, 18, reason: 'stale ignorée');
        // Toujours une seule ligne (upsert clé naturelle, pas de doublon).
        expect(stored.length, 1);
      },
    );

    test('coalescing : la 2ᵉ sauvegarde gèle TOUTES les notes pending, pas '
        'seulement les siennes', () async {
      await save([note('s1', id: 'n1', points: 10)]);
      final pendingAfterSecond = await save([note('s2', id: 'n2', points: 20)]);

      // Le payload coalescé (même aggregate_id) porte s1 ET s2.
      expect(pendingAfterSecond.map((n) => n.studentId).toSet(), {'s1', 's2'});
      final obx = await outbox.pendingReady(2000);
      expect(obx.length, 1, reason: 'coalescé sur aggregate_id ev-1');
    });
  });

  group('réalignement post-ACK', () {
    test('markEvaluationSynced passe SYNCED sous garde updated_at', () async {
      await local.createEvaluationWithOutbox(
        row: evalRow(updatedAt: 1000),
        outboxEntry: _entry(
          id: 'obx-ev-1',
          type: 'ACADEMICS_EVALUATION',
          aggregateId: 'ev-1',
          op: OutboxOperation.create,
        ),
      );

      // Garde périmée → aucun effet.
      await local.markEvaluationSynced(
        id: 'ev-1',
        updatedAtGuard: 999,
        serverUpdatedAt: 5000,
        syncedAt: 6000,
      );
      expect(
        (await local.getEvaluation('ev-1'))!.syncState,
        SyncState.pendingSync,
      );

      // Garde correcte → SYNCED + server_updated_at.
      await local.markEvaluationSynced(
        id: 'ev-1',
        updatedAtGuard: 1000,
        serverUpdatedAt: 5000,
        syncedAt: 6000,
      );
      final synced = await local.getEvaluation('ev-1');
      expect(synced!.syncState, SyncState.synced);
      expect(synced.serverUpdatedAt, 5000);
    });

    test(
      'markNotesSynced ne marque QUE les notes non ré-éditées depuis le push',
      () async {
        await local.upsertNotesWithOutbox(
          evaluationId: 'ev-1',
          incoming: [
            note('s1', id: 'n1', points: 10, updatedAt: 1000),
            note('s2', id: 'n2', points: 12, updatedAt: 1000),
          ],
          buildOutboxEntry: (_) => _entry(
            id: 'obx-notes-1',
            type: 'ACADEMICS_NOTES_BATCH',
            aggregateId: 'ev-1',
            op: OutboxOperation.upsert,
          ),
        );
        final byStudent = {
          for (final n in await local.getNotesForEvaluation('ev-1'))
            n.studentId: n,
        };

        // s2 est ré-éditée pendant le dispatch (nouvel updated_at).
        await local.upsertNotesWithOutbox(
          evaluationId: 'ev-1',
          incoming: [note('s2', id: 'n2', points: 19, updatedAt: 3000)],
          buildOutboxEntry: (_) => _entry(
            id: 'obx-notes-1',
            type: 'ACADEMICS_NOTES_BATCH',
            aggregateId: 'ev-1',
            op: OutboxOperation.upsert,
          ),
        );

        // L'ACK réaligne s1 et s2 aux updated_at POUSSÉS (1000).
        await local.markNotesSynced(
          idToPushedUpdatedAt: {
            byStudent['s1']!.id: 1000,
            byStudent['s2']!.id: 1000,
          },
          serverUpdatedAt: 8000,
          syncedAt: 9000,
        );

        final after = {
          for (final n in await local.getNotesForEvaluation('ev-1'))
            n.studentId: n,
        };
        expect(after['s1']!.syncState, SyncState.synced);
        // s2 a bougé (updated_at 3000 ≠ 1000 poussé) → reste à re-pousser.
        expect(after['s2']!.syncState, SyncState.pendingSync);
        expect(after['s2']!.pointsObtenus, 19);
      },
    );

    test(
      'markNotesSyncError bascule les notes rejetées en SYNC_ERROR',
      () async {
        await local.upsertNotesWithOutbox(
          evaluationId: 'ev-1',
          incoming: [note('s1', id: 'n1', points: 10, updatedAt: 1000)],
          buildOutboxEntry: (_) => _entry(
            id: 'obx-notes-1',
            type: 'ACADEMICS_NOTES_BATCH',
            aggregateId: 'ev-1',
            op: OutboxOperation.upsert,
          ),
        );
        final n1 = (await local.getNotesForEvaluation('ev-1')).single;

        await local.markNotesSyncError(idToPushedUpdatedAt: {n1.id: 1000});

        expect(
          (await local.getNotesForEvaluation('ev-1')).single.syncState,
          SyncState.syncError,
        );
      },
    );
  });
}
