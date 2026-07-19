import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_aggregate_response_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_case_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_comment_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_case_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_sync_api.dart';

class MockSyncApi extends Mock implements DisciplinarySyncApi {}

class MockLocal extends Mock implements DisciplinaryLocalDataSource {}

class FakeAggregate extends Fake
    implements DisciplinaryCaseAggregateRequestModel {}

void main() {
  late MockSyncApi syncApi;
  late MockLocal local;
  late DisciplinaryCaseOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(FakeAggregate());
  });

  setUp(() {
    syncApi = MockSyncApi();
    local = MockLocal();
    handler = DisciplinaryCaseOutboxHandler(
      syncApi: syncApi,
      localDataSource: local,
      requiredAuth: auth,
      now: () => 7000,
    );
    when(
      () => local.markAggregateSynced(
        caseId: any(named: 'caseId'),
        commentIds: any(named: 'commentIds'),
        updatedAtGuard: any(named: 'updatedAtGuard'),
        serverUpdatedAt: any(named: 'serverUpdatedAt'),
        winningStatus: any(named: 'winningStatus'),
        winningSanction: any(named: 'winningSanction'),
        applyWinningTreatment: any(named: 'applyWinningTreatment'),
        syncedAt: any(named: 'syncedAt'),
      ),
    ).thenAnswer((_) async {});
  });

  // Agrégat {case, comments[]} : clientUpdatedAt = 3000 ms (ISO), un commentaire.
  final aggregatePayload = DisciplinaryCaseAggregateRequestModel(
    caseInput: DisciplinaryCaseInputModel(
      id: 'case-1',
      studentId: 's1',
      academicYearId: 'year-1',
      category: 'FIGHTING',
      severity: 'SERIOUS',
      title: 'T',
      content: 'C',
      disciplinaryCaseDate: '2026-06-10',
      status: 'RESOLVED',
      sanction: 'DETENTION',
      clientUpdatedAt: EpochIsoHelper.toIso(3000),
    ),
    comments: [
      DisciplinaryCommentInputModel(
        id: 'cm-1',
        content: 'note',
        createdAt: EpochIsoHelper.toIso(2500),
      ),
    ],
  ).toJsonString();

  OutboxEntry entry() => OutboxEntry(
    id: 'DISCIPLINARY_CASE:case-1',
    aggregateType: 'DISCIPLINARY_CASE',
    aggregateId: 'case-1',
    operation: OutboxOperation.upsert,
    payload: aggregatePayload,
    createdAt: 1,
  );

  DioException dio(Object? error) => DioException(
    requestOptions: RequestOptions(path: '/sync/disciplinary-cases'),
    error: error,
  );

  DisciplinaryCaseAggregateResponseModel response(String outcome) =>
      DisciplinaryCaseAggregateResponseModel(
        caseId: 'case-1',
        status: 'RESOLVED',
        sanction: 'DETENTION',
        serverUpdatedAt: EpochIsoHelper.toIso(9000),
        lwwOutcome: outcome,
      );

  test('type d\'agrégat = DISCIPLINARY_CASE', () {
    expect(handler.aggregateType, 'DISCIPLINARY_CASE');
  });

  test(
    'APPLIED → acked + markAggregateSynced (garde LWW + serverUpdatedAt)',
    () async {
      when(
        () => syncApi.submitDisciplinaryCase(any(), any()),
      ).thenAnswer((_) async => response('APPLIED'));

      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      verify(
        () => local.markAggregateSynced(
          caseId: 'case-1',
          commentIds: ['cm-1'],
          updatedAtGuard: 3000,
          serverUpdatedAt: 9000,
          applyWinningTreatment: false,
          winningStatus: null,
          winningSanction: null,
          syncedAt: 7000,
        ),
      ).called(1);
    },
  );

  test('SUPERSEDED → acked + adopte le traitement gagnant serveur', () async {
    when(
      () => syncApi.submitDisciplinaryCase(any(), any()),
    ).thenAnswer((_) async => response('SUPERSEDED'));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.acked);
    verify(
      () => local.markAggregateSynced(
        caseId: 'case-1',
        commentIds: ['cm-1'],
        updatedAtGuard: 3000,
        serverUpdatedAt: 9000,
        applyWinningTreatment: true,
        winningStatus: 'RESOLVED',
        winningSanction: 'DETENTION',
        syncedAt: 7000,
      ),
    ).called(1);
  });

  test(
    '403 (UnauthorizedFailure) permanent → failed (pas 50 retries)',
    () async {
      when(
        () => syncApi.submitDisciplinaryCase(any(), any()),
      ).thenThrow(dio(const UnauthorizedFailure('Access forbidden')));

      final result = await handler.dispatch(entry());
      expect(result.outcome, OutboxDispatchOutcome.failed);
    },
  );

  test('rejet métier 422 (ValidationFailure) → failed', () async {
    when(
      () => syncApi.submitDisciplinaryCase(any(), any()),
    ).thenThrow(dio(const ValidationFailure('bad')));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('réseau → retry', () async {
    when(
      () => syncApi.submitDisciplinaryCase(any(), any()),
    ).thenThrow(dio(const NetworkFailure()));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('payload corrompu / ancien format → failed', () async {
    const badEntry = OutboxEntry(
      id: 'x',
      aggregateType: 'DISCIPLINARY_CASE',
      aggregateId: 'case-1',
      operation: OutboxOperation.upsert,
      payload: 'not-json',
      createdAt: 1,
    );
    final result = await handler.dispatch(badEntry);
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });
}
