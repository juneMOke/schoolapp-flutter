import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_notes_sync_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/notes_batch_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/notes_batch_push_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/notes_offline_repository_impl.dart'
    show kNotesBatchAggregateType;

import '../../../../../core/offline/offline_full_test_db.dart';

class MockNotesSyncApi extends Mock implements AcademicsNotesSyncApi {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const NotesBatchPushRequestModel(evaluationId: 'fallback'),
    );
  });

  late Database db;
  late AcademicsLocalDataSource local;
  late MockNotesSyncApi api;
  late CurrentUserContext currentUser;
  late NotesBatchOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUp(() async {
    db = await openFullOfflineDb();
    local = AcademicsLocalDataSource(db);
    api = MockNotesSyncApi();
    currentUser = CurrentUserContext()..set('me');
    handler = NotesBatchOutboxHandler(
      syncApi: api,
      localDataSource: local,
      requiredAuth: auth,
      currentUser: currentUser,
      now: () => 30000,
    );
  });

  tearDown(() async => db.close());

  Future<void> insertEvaluation(String id, {String syncStatus = 'SYNCED'}) =>
      db.insert('evaluation', {
        'id': id,
        'cours_id': 'co1',
        'type': 'INTERRO',
        'eval_date': 1,
        'max_points': 20.0,
        'poids': 1,
        'updated_at': 1000,
        'sync_status': syncStatus,
        'chapitre_ids_json': '[]',
      });

  Future<void> insertNote(
    String evaluationId,
    String studentId, {
    int updatedAt = 5000,
  }) => db.insert('note_evaluation', {
    'id': '$evaluationId-$studentId',
    'evaluation_id': evaluationId,
    'student_id': studentId,
    'points_obtenus': 12.0,
    'statut': 'NOTEE',
    'updated_at': updatedAt,
    'sync_status': 'PENDING_SYNC',
  });

  NoteInputModel note(
    String evaluationId,
    String studentId, {
    int updatedAt = 5000,
  }) => NoteInputModel(
    evaluationId: evaluationId,
    studentId: studentId,
    statut: 'NOTEE',
    pointsObtenus: 12,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      updatedAt,
      isUtc: true,
    ).toIso8601String(),
  );

  OutboxEntry entry(String evaluationId, List<NoteInputModel> notes) =>
      OutboxEntry(
        id: '$kNotesBatchAggregateType:$evaluationId',
        aggregateType: kNotesBatchAggregateType,
        aggregateId: evaluationId,
        operation: OutboxOperation.upsert,
        payload: NotesBatchPushRequestModel(
          authorId: 'me',
          evaluationId: evaluationId,
          notes: notes,
        ).toJsonString(),
        createdAt: 1000,
      );

  DioException status(int code) => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: code,
    ),
  );

  group('garde de dépendance ÉVALUATION→NOTE', () {
    test('évaluation PENDING_SYNC → blocked, auto-cicatrisant', () async {
      await insertEvaluation('ev-1', syncStatus: 'PENDING_SYNC');
      await insertNote('ev-1', 's1');

      final result = await handler.dispatch(
        entry('ev-1', [note('ev-1', 's1')]),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.submitNotes(any(), any()));
    });

    test(
      'évaluation SYNC_ERROR (rejetée) → failed, jamais bloqué à vie',
      () async {
        await insertEvaluation('ev-1', syncStatus: 'SYNC_ERROR');
        await insertNote('ev-1', 's1');

        final result = await handler.dispatch(
          entry('ev-1', [note('ev-1', 's1')]),
        );

        expect(result.outcome, OutboxDispatchOutcome.failed);
        verifyNever(() => api.submitNotes(any(), any()));
      },
    );
  });

  test('outcome APPLIED : note SYNCED, entrée acked', () async {
    await insertEvaluation('ev-1');
    await insertNote('ev-1', 's1');
    when(() => api.submitNotes(auth, any())).thenAnswer(
      (_) async => const NotesBatchResponseModel(
        outcomes: [NoteOutcomeModel(studentId: 's1', outcome: 'APPLIED')],
      ),
    );

    final result = await handler.dispatch(entry('ev-1', [note('ev-1', 's1')]));

    expect(result.outcome, OutboxDispatchOutcome.acked);
    final notes = await local.getNotesForEvaluation('ev-1');
    expect(notes.single.syncState, SyncState.synced);
  });

  test('outcome REJECTED : note SYNC_ERROR + motif persisté (surfacé UI, '
      'jamais perdu)', () async {
    await insertEvaluation('ev-1');
    await insertNote('ev-1', 's1');
    when(() => api.submitNotes(auth, any())).thenAnswer(
      (_) async => const NotesBatchResponseModel(
        outcomes: [
          NoteOutcomeModel(
            studentId: 's1',
            outcome: 'REJECTED',
            reason: 'PERIODE_CLOSE',
          ),
        ],
      ),
    );

    final result = await handler.dispatch(entry('ev-1', [note('ev-1', 's1')]));

    expect(result.outcome, OutboxDispatchOutcome.acked);
    final notes = await local.getNotesForEvaluation('ev-1');
    expect(notes.single.syncState, SyncState.syncError);
    expect(notes.single.rejectionReason, 'PERIODE_CLOSE');
  });

  test(
    'lot mixte : chaque ligne réconciliée selon SON outcome propre',
    () async {
      await insertEvaluation('ev-1');
      await insertNote('ev-1', 's1');
      await insertNote('ev-1', 's2');
      when(() => api.submitNotes(auth, any())).thenAnswer(
        (_) async => const NotesBatchResponseModel(
          outcomes: [
            NoteOutcomeModel(studentId: 's1', outcome: 'APPLIED'),
            NoteOutcomeModel(
              studentId: 's2',
              outcome: 'REJECTED',
              reason: 'INVALID: hors bornes',
            ),
          ],
        ),
      );

      final result = await handler.dispatch(
        entry('ev-1', [note('ev-1', 's1'), note('ev-1', 's2')]),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final byStudent = {
        for (final n in await local.getNotesForEvaluation('ev-1'))
          n.studentId: n,
      };
      expect(byStudent['s1']!.syncState, SyncState.synced);
      expect(byStudent['s2']!.syncState, SyncState.syncError);
      expect(byStudent['s2']!.rejectionReason, 'INVALID: hors bornes');
    },
  );

  test('APPLIED gagne même si le REJECTED du même studentId arrive AVANT dans '
      'la réponse (ordre non garanti par le contrat) : jamais gelée en '
      'SYNC_ERROR', () async {
    await insertEvaluation('ev-1');
    await insertNote('ev-1', 's1');
    when(() => api.submitNotes(auth, any())).thenAnswer(
      (_) async => const NotesBatchResponseModel(
        outcomes: [
          // REJECTED en premier, APPLIED en second — ordre inverse du cas
          // nominal, pour ne pas dépendre de la garde SQL/ordre d'appel.
          NoteOutcomeModel(
            studentId: 's1',
            outcome: 'REJECTED',
            reason: 'PERIODE_CLOSE',
          ),
          NoteOutcomeModel(studentId: 's1', outcome: 'APPLIED'),
        ],
      ),
    );

    final result = await handler.dispatch(entry('ev-1', [note('ev-1', 's1')]));

    expect(result.outcome, OutboxDispatchOutcome.acked);
    final notes = await local.getNotesForEvaluation('ev-1');
    expect(notes.single.syncState, SyncState.synced);
    expect(notes.single.rejectionReason, isNull);
  });

  test('outcomes incomplets (réponse serveur partielle) : retry, aucune note '
      'orpheline', () async {
    await insertEvaluation('ev-1');
    await insertNote('ev-1', 's1');
    await insertNote('ev-1', 's2');
    when(() => api.submitNotes(auth, any())).thenAnswer(
      (_) async => const NotesBatchResponseModel(
        outcomes: [NoteOutcomeModel(studentId: 's1', outcome: 'APPLIED')],
      ),
    );

    final result = await handler.dispatch(
      entry('ev-1', [note('ev-1', 's1'), note('ev-1', 's2')]),
    );

    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('réseau / 5xx : retry', () async {
    await insertEvaluation('ev-1');
    await insertNote('ev-1', 's1');
    when(() => api.submitNotes(auth, any())).thenThrow(status(503));

    final result = await handler.dispatch(entry('ev-1', [note('ev-1', 's1')]));

    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('authorId ≠ uid courant (tablette partagée) : blocked, jamais poussée '
      'sous ce JWT', () async {
    await insertEvaluation('ev-1');
    await insertNote('ev-1', 's1');
    final foreign = OutboxEntry(
      id: '$kNotesBatchAggregateType:ev-1',
      aggregateType: kNotesBatchAggregateType,
      aggregateId: 'ev-1',
      operation: OutboxOperation.upsert,
      payload: NotesBatchPushRequestModel(
        authorId: 'other',
        evaluationId: 'ev-1',
        notes: [note('ev-1', 's1')],
      ).toJsonString(),
      createdAt: 1000,
    );

    final result = await handler.dispatch(foreign);

    expect(result.outcome, OutboxDispatchOutcome.blocked);
    verifyNever(() => api.submitNotes(any(), any()));
  });

  test('outcome SUPERSEDED : le local est réaligné sur l\'état CANONIQUE '
      'serveur (pas la valeur poussée par ce client)', () async {
    await insertEvaluation('ev-1');
    await insertNote('ev-1', 's1'); // local pousse points=12, statut=NOTEE
    when(() => api.submitNotes(auth, any())).thenAnswer(
      (_) async => const NotesBatchResponseModel(
        outcomes: [
          NoteOutcomeModel(
            studentId: 's1',
            outcome: 'SUPERSEDED',
            note: NoteSyncViewModel(
              studentId: 's1',
              statut: 'NOTEE',
              pointsObtenus: 17, // un autre appareil a gagné le LWW
              updatedAt: '2026-07-23T09:00:00.000Z',
              serverUpdatedAt: '2026-07-23T09:00:01.000Z',
            ),
          ),
        ],
      ),
    );

    final result = await handler.dispatch(entry('ev-1', [note('ev-1', 's1')]));

    expect(result.outcome, OutboxDispatchOutcome.acked);
    final row = (await local.getNotesForEvaluation('ev-1')).single;
    expect(row.syncState, SyncState.synced);
    expect(row.pointsObtenus, 17);
    expect(row.serverUpdatedAt, isNotNull);
  });

  test('round-trip JSON réel (contrat wire) : status/note/serverTime — pas '
      '"outcome"/"serverUpdatedAt" — sinon aucune note ne se synchronise '
      'jamais contre un vrai serveur', () async {
    await insertEvaluation('ev-1');
    await insertNote('ev-1', 's1');
    // Shape EXACTE du contrat NoteBatchSyncResponse (openapi_notes_sync.yaml) :
    // outcomes[].status (pas .outcome), outcomes[].note (NoteSyncView),
    // serverTime au niveau racine (pas serverUpdatedAt).
    final rawResponse =
        jsonDecode('''
      {
        "outcomes": [
          {
            "evaluationId": "ev-1",
            "studentId": "s1",
            "status": "APPLIED",
            "note": {
              "id": "n1",
              "evaluationId": "ev-1",
              "studentId": "s1",
              "statut": "NOTEE",
              "pointsObtenus": 12,
              "updatedAt": "2026-07-23T09:00:00.000Z",
              "serverUpdatedAt": "2026-07-23T09:00:01.000Z"
            },
            "reason": null
          }
        ],
        "serverTime": "2026-07-23T09:00:01.000Z"
      }
      ''')
            as Map<String, dynamic>;
    when(
      () => api.submitNotes(auth, any()),
    ).thenAnswer((_) async => NotesBatchResponseModel.fromJson(rawResponse));

    final result = await handler.dispatch(entry('ev-1', [note('ev-1', 's1')]));

    expect(result.outcome, OutboxDispatchOutcome.acked);
    final row = (await local.getNotesForEvaluation('ev-1')).single;
    expect(row.syncState, SyncState.synced);
    expect(row.pointsObtenus, 12);
  });
}
