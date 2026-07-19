import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_notes_sync_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/notes_batch_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/notes_batch_push_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notes_offline_repository_impl.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockIdGenerator extends Mock implements IdGenerator {}

class MockNotesSyncApi extends Mock implements AcademicsNotesSyncApi {}

void main() {
  late Database db;
  late AcademicsLocalDataSource local;
  late OutboxDao outbox;
  late MockIdGenerator idGen;
  late NotesOfflineRepositoryImpl repo;
  late MockNotesSyncApi syncApi;
  late NotesBatchOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};
  var idSeq = 0;

  setUpAll(() {
    registerFallbackValue(const NotesBatchPushRequestModel(evaluationId: 'x'));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    db = await openFullOfflineDb();
    local = AcademicsLocalDataSource(db);
    outbox = OutboxDao(db);
    idGen = MockIdGenerator();
    idSeq = 0;
    when(() => idGen.newId()).thenAnswer((_) => 'n${idSeq++}');
    repo = NotesOfflineRepositoryImpl(
      localDataSource: local,
      idGenerator: idGen,
      currentUser: CurrentUserContext()..set('teacher-uid'),
      now: () => 1000,
    );
    syncApi = MockNotesSyncApi();
    handler = NotesBatchOutboxHandler(
      syncApi: syncApi,
      localDataSource: local,
      requiredAuth: auth,
      now: () => 9000,
    );
  });

  tearDown(() async => db.close());

  Future<void> insertEval(String state) => db.insert('evaluation', {
    'id': 'ev-1',
    'cours_id': 'c-1',
    'type': 'INTERRO',
    'eval_date': 500,
    'max_points': 20.0,
    'poids': 1,
    'updated_at': 1000,
    'sync_status': state,
  });

  DioException dioWith(Failure f) => DioException(
    requestOptions: RequestOptions(path: '/'),
    error: f,
  );

  NoteOutcomeModel outcome(String studentId, String o, {String? reason}) =>
      NoteOutcomeModel(studentId: studentId, outcome: o, reason: reason);

  Future<OutboxEntry> saveSample() async {
    await repo.saveNotes(
      evaluationId: 'ev-1',
      notes: const [
        NoteSaveInput(studentId: 's1', statut: 'NOTEE', pointsObtenus: 12),
        NoteSaveInput(studentId: 's2', statut: 'NOTEE', pointsObtenus: 15),
      ],
    );
    return (await outbox.pendingReady(9999)).single;
  }

  group('saveNotes (régime C)', () {
    test('matérialise les notes PENDING + enveloppe estampillée', () async {
      await repo.saveNotes(
        evaluationId: 'ev-1',
        notes: const [
          NoteSaveInput(studentId: 's1', statut: 'NOTEE', pointsObtenus: 12),
        ],
      );

      final stored = await local.getNotesForEvaluation('ev-1');
      expect(stored.single.syncState, SyncState.pendingSync);
      final entry = (await outbox.pendingReady(9999)).single;
      expect(entry.aggregateType, kNotesBatchAggregateType);
      expect(entry.aggregateId, 'ev-1');
      final payload = NotesBatchPushRequestModel.fromJsonString(entry.payload);
      expect(payload.authorId, 'teacher-uid');
      expect(payload.evaluationId, 'ev-1');
      expect(payload.notes.single.studentId, 's1');
    });
  });

  group('garde de dépendance ÉVALUATION→NOTE', () {
    test('évaluation PENDING → blocked (attente propre)', () async {
      await insertEval('PENDING_SYNC');
      final entry = await saveSample();

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => syncApi.submitNotes(any(), any()));
    });

    test('évaluation SYNC_ERROR → failed', () async {
      await insertEval('SYNC_ERROR');
      final entry = await saveSample();

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.failed);
    });
  });

  group('réconciliation par ligne (acceptation partielle)', () {
    test('tout APPLIED → acked + notes SYNCED', () async {
      await insertEval('SYNCED');
      final entry = await saveSample();
      when(() => syncApi.submitNotes(any(), any())).thenAnswer(
        (_) async => NotesBatchResponseModel(
          serverUpdatedAt: '2026-06-10T08:00:00Z',
          outcomes: [outcome('s1', 'APPLIED'), outcome('s2', 'SUPERSEDED')],
        ),
      );

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final byStudent = {
        for (final n in await local.getNotesForEvaluation('ev-1'))
          n.studentId: n,
      };
      expect(byStudent['s1']!.syncState, SyncState.synced);
      expect(byStudent['s2']!.syncState, SyncState.synced);
    });

    test('une note REJECTED (période close) → SYNC_ERROR, les autres SYNCED, '
        'lot acked (jamais all-or-nothing)', () async {
      await insertEval('SYNCED');
      final entry = await saveSample();
      when(() => syncApi.submitNotes(any(), any())).thenAnswer(
        (_) async => NotesBatchResponseModel(
          outcomes: [
            outcome('s1', 'APPLIED'),
            outcome('s2', 'REJECTED', reason: 'PERIODE_CLOSE'),
          ],
        ),
      );

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final byStudent = {
        for (final n in await local.getNotesForEvaluation('ev-1'))
          n.studentId: n,
      };
      expect(byStudent['s1']!.syncState, SyncState.synced);
      expect(byStudent['s2']!.syncState, SyncState.syncError);
    });

    test(
      'réponse incomplète (outcome manquant) → retry, aucune note orpheline',
      () async {
        await insertEval('SYNCED');
        final entry = await saveSample();
        when(() => syncApi.submitNotes(any(), any())).thenAnswer(
          (_) async =>
              NotesBatchResponseModel(outcomes: [outcome('s1', 'APPLIED')]),
        );

        final result = await handler.dispatch(entry);

        expect(result.outcome, OutboxDispatchOutcome.retry);
      },
    );

    test('payload corrompu → failed', () async {
      const entry = OutboxEntry(
        id: 'x',
        aggregateType: kNotesBatchAggregateType,
        aggregateId: 'ev-1',
        operation: OutboxOperation.upsert,
        payload: 'not-json',
        createdAt: 1,
      );

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.failed);
    });

    test('réseau / 5xx → retry', () async {
      await insertEval('SYNCED');
      final entry = await saveSample();
      when(
        () => syncApi.submitNotes(any(), any()),
      ).thenThrow(dioWith(const ServerFailure('503')));

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.retry);
    });
  });
}
