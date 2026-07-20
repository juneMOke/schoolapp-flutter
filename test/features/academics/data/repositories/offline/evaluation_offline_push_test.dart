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
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_evaluation_sync_api.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/academics_local_data_source.dart';
import 'package:school_app_flutter/features/academics/data/datasources/offline/evaluation_outbox_handler.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_push_models.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class MockIdGenerator extends Mock implements IdGenerator {}

class MockEvaluationSyncApi extends Mock
    implements AcademicsEvaluationSyncApi {}

void main() {
  late Database db;
  late AcademicsLocalDataSource local;
  late OutboxDao outbox;
  late MockIdGenerator idGen;
  late CurrentUserContext currentUser;
  late EvaluationOfflineRepositoryImpl repo;
  late MockEvaluationSyncApi syncApi;
  late EvaluationOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUpAll(() {
    registerFallbackValue(
      EvaluationPushRequestModel(
        evaluation: EvaluationInputModel(
          id: 'x',
          coursId: 'x',
          type: 'INTERRO',
          date: DateTime.utc(2026, 1, 1),
          maxPoints: 20,
          poids: 1,
        ),
      ),
    );
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() async {
    db = await openFullOfflineDb();
    local = AcademicsLocalDataSource(db);
    outbox = OutboxDao(db);
    idGen = MockIdGenerator();
    when(() => idGen.newId()).thenReturn('ev-1');
    currentUser = CurrentUserContext()..set('teacher-uid');
    repo = EvaluationOfflineRepositoryImpl(
      localDataSource: local,
      idGenerator: idGen,
      currentUser: currentUser,
      now: () => 5000,
    );
    syncApi = MockEvaluationSyncApi();
    handler = EvaluationOutboxHandler(
      syncApi: syncApi,
      localDataSource: local,
      requiredAuth: auth,
      currentUser: currentUser,
      now: () => 9000,
    );
  });

  tearDown(() async => db.close());

  DioException dioWith(Failure f) => DioException(
    requestOptions: RequestOptions(path: '/'),
    error: f,
  );

  Future<OutboxEntry> createSample() async {
    await repo.createEvaluation(
      coursId: 'c-1',
      type: 'INTERRO',
      date: DateTime.utc(2026, 6, 10),
      maxPoints: 20,
      poids: 1,
      sousPeriodeId: 'sp-1',
    );
    return (await outbox.pendingReady(9999)).single;
  }

  group('createEvaluation (régime A)', () {
    test(
      'matérialise la ligne PENDING + enveloppe outbox estampillée',
      () async {
        final result = await repo.createEvaluation(
          coursId: 'c-1',
          type: 'INTERRO',
          date: DateTime.utc(2026, 6, 10),
          maxPoints: 20,
          poids: 1,
          sousPeriodeId: 'sp-1',
        );

        expect(result.isRight(), isTrue);
        final stored = await local.getEvaluation('ev-1');
        expect(stored!.syncState, SyncState.pendingSync);

        final entry = (await outbox.pendingReady(9999)).single;
        expect(entry.aggregateType, kEvaluationAggregateType);
        expect(entry.aggregateId, 'ev-1');
        expect(entry.operation, OutboxOperation.create);
        final payload = EvaluationPushRequestModel.fromJsonString(
          entry.payload,
        );
        expect(payload.authorId, 'teacher-uid');
        expect(payload.evaluation.coursId, 'c-1');
        expect(payload.evaluation.type, 'INTERRO');
        expect(payload.evaluation.sousPeriodeId, 'sp-1');
      },
    );
  });

  group('EvaluationOutboxHandler.dispatch', () {
    test('succès → acked + évaluation SYNCED (+ server_updated_at)', () async {
      final entry = await createSample();
      when(() => syncApi.submitEvaluation(any(), any())).thenAnswer(
        (_) async => const EvaluationPushResponseModel(
          id: 'ev-1',
          serverUpdatedAt: '2026-06-10T08:00:00Z',
        ),
      );

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final stored = await local.getEvaluation('ev-1');
      expect(stored!.syncState, SyncState.synced);
      expect(
        stored.serverUpdatedAt,
        DateTime.utc(2026, 6, 10, 8).millisecondsSinceEpoch,
      );
    });

    test('payload corrompu → failed (poison évité)', () async {
      const entry = OutboxEntry(
        id: 'x',
        aggregateType: kEvaluationAggregateType,
        aggregateId: 'ev-1',
        operation: OutboxOperation.create,
        payload: 'not-json',
        createdAt: 1,
      );

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.failed);
    });

    test('rejet validation (422) → failed (terminal)', () async {
      final entry = await createSample();
      when(
        () => syncApi.submitEvaluation(any(), any()),
      ).thenThrow(dioWith(const ValidationFailure('Période clôturée')));

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.failed);
      // Évaluation reste PENDING (pas de faux SYNCED).
      expect(
        (await local.getEvaluation('ev-1'))!.syncState,
        SyncState.pendingSync,
      );
    });

    test('réseau / 5xx → retry (transitoire)', () async {
      final entry = await createSample();
      when(
        () => syncApi.submitEvaluation(any(), any()),
      ).thenThrow(dioWith(const ServerFailure('503')));

      final result = await handler.dispatch(entry);

      expect(result.outcome, OutboxDispatchOutcome.retry);
    });
  });
}
