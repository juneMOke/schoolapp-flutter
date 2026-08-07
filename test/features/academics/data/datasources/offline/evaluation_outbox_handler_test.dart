import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sync_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_push_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart'
    show kEvaluationAggregateType;

import '../../../../../core/offline/offline_full_test_db.dart';

class MockEvaluationSyncApi extends Mock
    implements AcademicsEvaluationSyncApi {}

class MockAcademicsLocalDataSource extends Mock
    implements AcademicsLocalDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      EvaluationPushRequestModel(
        coursId: 'co1',
        evaluation: EvaluationInputModel(
          id: 'fallback',
          coursId: 'co1',
          type: 'INTERRO',
          date: DateTime.utc(2026, 1, 1),
          maxPoints: 20,
          poids: 1,
        ),
      ),
    );
  });

  late Database db;
  late AcademicsLocalDataSource local;
  late MockEvaluationSyncApi api;
  late CurrentUserContext currentUser;
  late EvaluationOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUp(() async {
    db = await openFullOfflineDb();
    local = AcademicsLocalDataSource(db);
    api = MockEvaluationSyncApi();
    currentUser = CurrentUserContext()..set('me');
    handler = EvaluationOutboxHandler(
      syncApi: api,
      localDataSource: local,
      requiredAuth: auth,
      currentUser: currentUser,
      now: () => 20000,
    );
  });

  tearDown(() async => db.close());

  Future<void> insertEval(String id) async {
    await db.insert('evaluation', {
      'id': id,
      'cours_id': 'co1',
      'type': 'INTERRO',
      'eval_date': 1,
      'max_points': 20.0,
      'poids': 1,
      'updated_at': 1000,
      'sync_status': 'PENDING_SYNC',
      'chapitre_ids_json': '[]',
    });
  }

  OutboxEntry entry(String evalId, {String? authorId = 'me'}) => OutboxEntry(
    id: '$kEvaluationAggregateType:$evalId',
    aggregateType: kEvaluationAggregateType,
    aggregateId: evalId,
    operation: OutboxOperation.create,
    payload: EvaluationPushRequestModel(
      authorId: authorId,
      coursId: 'co1',
      evaluation: EvaluationInputModel(
        id: evalId,
        coursId: 'co1',
        type: 'INTERRO',
        date: DateTime.utc(2026, 1, 1),
        maxPoints: 20,
        poids: 1,
      ),
    ).toJsonString(),
    createdAt: 1000,
  );

  // `error` reproduit ce que pose le vrai intercepteur Dio global (mapping
  // statusCode → Failure typée) — le handler le lit via `e.error` pour les
  // branches hors 422 (celle-ci lit `e.response` directement).
  DioException status(int code, {Object? data, Failure? error}) => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: code,
      data: data,
    ),
    error: error,
  );

  test('succès (201/200) : évaluation SYNCED + server_updated_at', () async {
    await insertEval('ev-1');
    when(() => api.submitEvaluation(auth, any())).thenAnswer(
      (_) async => const EvaluationPushResponseModel(
        id: 'ev-1',
        serverUpdatedAt: '2026-07-23T08:00:00Z',
      ),
    );

    final result = await handler.dispatch(entry('ev-1'));

    expect(result.outcome, OutboxDispatchOutcome.acked);
    final row = await local.getEvaluation('ev-1');
    expect(row!.syncState, SyncState.synced);
    expect(row.serverUpdatedAt, isNotNull);
  });

  group('backstops 422 (DF-N)', () {
    for (final code in EvaluationOutboxHandler.backstopCodes) {
      test('$code : failed terminal, SYNC_ERROR + code persisté', () async {
        await insertEval('ev-1');
        when(
          () => api.submitEvaluation(auth, any()),
        ).thenThrow(status(422, data: {'message': '$code: message lisible'}));

        final result = await handler.dispatch(entry('ev-1'));

        expect(result.outcome, OutboxDispatchOutcome.failed);
        final row = await local.getEvaluation('ev-1');
        expect(row!.syncState, SyncState.syncError);
        expect(row.rejectionCode, code);
      });
    }

    test('422 message non reconnu (contrat inattendu) : failed avec code '
        'générique REJECTED', () async {
      await insertEval('ev-1');
      when(
        () => api.submitEvaluation(auth, any()),
      ).thenThrow(status(422, data: {'message': 'SOMETHING_ELSE'}));

      final result = await handler.dispatch(entry('ev-1'));

      expect(result.outcome, OutboxDispatchOutcome.failed);
      final row = await local.getEvaluation('ev-1');
      expect(row!.syncState, SyncState.syncError);
      expect(row.rejectionCode, 'REJECTED');
    });

    test('422 sans corps JSON exploitable : failed sans lever', () async {
      await insertEval('ev-1');
      when(() => api.submitEvaluation(auth, any())).thenThrow(status(422));

      final result = await handler.dispatch(entry('ev-1'));

      expect(result.outcome, OutboxDispatchOutcome.failed);
      final row = await local.getEvaluation('ev-1');
      expect(row!.syncState, SyncState.syncError);
      expect(row.rejectionCode, 'REJECTED');
    });

    test('écriture locale (markEvaluationSyncError) en échec : reste failed, '
        'JAMAIS retry — un 422 déterministe ne doit jamais boucler', () async {
      final throwingLocal = MockAcademicsLocalDataSource();
      when(
        () => throwingLocal.markEvaluationSyncError(
          id: any(named: 'id'),
          rejectionCode: any(named: 'rejectionCode'),
        ),
      ).thenThrow(Exception('DB busy'));
      final throwingHandler = EvaluationOutboxHandler(
        syncApi: api,
        localDataSource: throwingLocal,
        requiredAuth: auth,
        currentUser: currentUser,
        now: () => 20000,
      );
      when(() => api.submitEvaluation(auth, any())).thenThrow(
        status(422, data: {'message': 'PERIOD_CLOSED: message lisible'}),
      );

      final result = await throwingHandler.dispatch(entry('ev-1'));

      expect(result.outcome, OutboxDispatchOutcome.failed);
    });
  });

  test('404 (cours inconnu) : failed terminal, pas de retry', () async {
    await insertEval('ev-1');
    when(() => api.submitEvaluation(auth, any())).thenThrow(
      status(404, error: const NotFoundFailure('Resource not found')),
    );

    final result = await handler.dispatch(entry('ev-1'));

    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('400 (rattachement incohérent / poids<=0) : failed terminal', () async {
    await insertEval('ev-1');
    when(() => api.submitEvaluation(auth, any())).thenThrow(
      status(400, error: const ValidationFailure('Invalid request data')),
    );

    final result = await handler.dispatch(entry('ev-1'));

    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('réseau / 5xx : retry, jamais terminal', () async {
    await insertEval('ev-1');
    when(() => api.submitEvaluation(auth, any())).thenThrow(status(503));

    final result = await handler.dispatch(entry('ev-1'));

    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('authorId ≠ uid courant (tablette partagée) : blocked, jamais poussée '
      'sous ce JWT', () async {
    await insertEval('ev-1');

    final result = await handler.dispatch(entry('ev-1', authorId: 'other'));

    expect(result.outcome, OutboxDispatchOutcome.blocked);
    verifyNever(() => api.submitEvaluation(any(), any()));
  });
}
