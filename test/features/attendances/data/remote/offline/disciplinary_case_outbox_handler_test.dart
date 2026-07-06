import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/create_disciplinary_case_offline_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/update_disciplinary_case_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/disciplinary_case_remote_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_case_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/disciplinary_local_data_source.dart';

class MockRemote extends Mock implements DisciplinaryCaseRemoteDataSource {}

class MockLocal extends Mock implements DisciplinaryLocalDataSource {}

class FakeCreate extends Fake
    implements CreateDisciplinaryCaseOfflineRequestModel {}

class FakeUpdate extends Fake implements UpdateDisciplinaryCaseRequestModel {}

void main() {
  late MockRemote remote;
  late MockLocal local;
  late DisciplinaryCaseOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(FakeCreate());
    registerFallbackValue(FakeUpdate());
  });

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    handler = DisciplinaryCaseOutboxHandler(
      remoteDataSource: remote,
      localDataSource: local,
      requiredAuth: auth,
      now: () => 7000,
    );
    when(
      () => local.markCaseSynced(
        any(),
        version: any(named: 'version'),
        syncedAt: any(named: 'syncedAt'),
      ),
    ).thenAnswer((_) async {});
  });

  final createPayload = const CreateDisciplinaryCaseOfflineRequestModel(
    id: 'case-1',
    studentId: 's1',
    studentFirstName: 'A',
    studentLastName: 'B',
    studentGender: 'MALE',
    disciplinaryCaseDate: '2026-06-10',
    academicYearId: 'year-1',
    title: 'T',
    content: 'C',
    category: 'FIGHTING',
    severity: 'SERIOUS',
    sanction: 'DETENTION',
  ).toJsonString();

  final updatePayload = const UpdateDisciplinaryCaseRequestModel(
    status: 'RESOLVED',
    sanction: 'DETENTION',
  ).toJsonString();

  OutboxEntry createEntry() => OutboxEntry(
    id: 'DISCIPLINARY_CASE:CREATE:case-1',
    aggregateType: 'DISCIPLINARY_CASE',
    aggregateId: 'case-1',
    operation: OutboxOperation.create,
    payload: createPayload,
    createdAt: 1,
  );

  OutboxEntry updateEntry() => OutboxEntry(
    id: 'DISCIPLINARY_CASE:UPDATE:case-1',
    aggregateType: 'DISCIPLINARY_CASE',
    aggregateId: 'case-1',
    operation: OutboxOperation.update,
    payload: updatePayload,
    createdAt: 2,
  );

  DioException dio(Object? error) => DioException(
    requestOptions: RequestOptions(path: '/disciplinary-cases'),
    error: error,
  );

  test('type d\'agrégat = DISCIPLINARY_CASE', () {
    expect(handler.aggregateType, 'DISCIPLINARY_CASE');
  });

  test('CREATE OK (régime A, id client) → acked + synced', () async {
    when(
      () => remote.createCaseWithClientId(any(), any()),
    ).thenAnswer((_) async {});

    final result = await handler.dispatch(createEntry());

    expect(result.outcome, OutboxDispatchOutcome.acked);
    verify(() => local.markCaseSynced('case-1', syncedAt: 7000)).called(1);
  });

  test('UPDATE OK (régime C) → acked + synced', () async {
    when(
      () => remote.updateDisciplinaryCase(any(), any(), any()),
    ).thenAnswer((_) async {});

    final result = await handler.dispatch(updateEntry());

    expect(result.outcome, OutboxDispatchOutcome.acked);
    verify(
      () => remote.updateDisciplinaryCase(auth, 'case-1', any()),
    ).called(1);
  });

  test('UPDATE 409 (ConflictFailure) → refetch + retry', () async {
    when(
      () => remote.updateDisciplinaryCase(any(), any(), any()),
    ).thenThrow(dio(const ConflictFailure()));
    when(
      () => remote.getCaseById(any(), any()),
    ).thenThrow(Exception('offline'));

    final result = await handler.dispatch(updateEntry());

    expect(result.outcome, OutboxDispatchOutcome.retry);
    verify(() => remote.getCaseById(auth, 'case-1')).called(1);
  });

  test('CREATE rejet métier (ValidationFailure) → failed', () async {
    when(
      () => remote.createCaseWithClientId(any(), any()),
    ).thenThrow(dio(const ValidationFailure('bad')));

    final result = await handler.dispatch(createEntry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('CREATE réseau → retry', () async {
    when(
      () => remote.createCaseWithClientId(any(), any()),
    ).thenThrow(dio(const NetworkFailure()));

    final result = await handler.dispatch(createEntry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('payload corrompu → failed', () async {
    const entry = OutboxEntry(
      id: 'x',
      aggregateType: 'DISCIPLINARY_CASE',
      aggregateId: 'case-1',
      operation: OutboxOperation.create,
      payload: 'not-json',
      createdAt: 1,
    );
    final result = await handler.dispatch(entry);
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });
}
