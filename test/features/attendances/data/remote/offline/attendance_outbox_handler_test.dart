import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_absence_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_request_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_aggregate_response_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_input_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_sync_api.dart';

class MockAttendanceSyncApi extends Mock implements AttendanceSyncApi {}

class MockAttendanceLocalDataSource extends Mock
    implements AttendanceLocalDataSource {}

class FakeAggregate extends Fake implements AttendanceAggregateRequestModel {}

void main() {
  late MockAttendanceSyncApi api;
  late MockAttendanceLocalDataSource local;
  late AttendanceOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(FakeAggregate());
  });

  setUp(() {
    api = MockAttendanceSyncApi();
    local = MockAttendanceLocalDataSource();
    handler = AttendanceOutboxHandler(
      syncApi: api,
      localDataSource: local,
      requiredAuth: auth,
      now: () => 7000,
    );
  });

  const aggregate = AttendanceAggregateRequestModel(
    session: AttendanceSessionInputModel(
      id: 'sess-1',
      classroomId: 'c1',
      attendanceDate: '2026-06-15',
      academicYearId: 'year-1',
      takenAt: '2026-06-15T00:00:00.000Z',
      updatedAt: '2026-06-15T00:00:00.000Z',
    ),
    absences: [
      AttendanceAbsenceInputModel(
        id: 'abs-1',
        studentId: 's1',
        absenceReason: 'SICKNESS',
        updatedAt: '2026-06-15T00:00:00.000Z',
      ),
    ],
  );

  AttendanceAggregateResponseModel response({
    String outcome = 'APPLIED',
    String? serverUpdatedAt = '2026-06-15T09:00:00.000Z',
    int? expectedCount = 40,
  }) => AttendanceAggregateResponseModel(
    sessionId: 'sess-1',
    serverUpdatedAt: serverUpdatedAt,
    expectedCount: expectedCount,
    lwwOutcome: outcome,
  );

  OutboxEntry entry({String? payload}) => OutboxEntry(
    id: 'ATTENDANCE:c1|2026-06-15|year-1',
    aggregateType: 'ATTENDANCE',
    aggregateId: 'c1|2026-06-15|year-1',
    operation: OutboxOperation.upsert,
    payload: payload ?? aggregate.toJsonString(),
    createdAt: 1000,
  );

  DioException dio(Object? error) => DioException(
    requestOptions: RequestOptions(path: '/sync/attendance'),
    error: error,
  );

  void stubMarkSynced() {
    when(
      () => local.markDaySynced(
        classroomId: any(named: 'classroomId'),
        dateStr: any(named: 'dateStr'),
        academicYearId: any(named: 'academicYearId'),
        syncedAt: any(named: 'syncedAt'),
        serverUpdatedAt: any(named: 'serverUpdatedAt'),
        expectedCount: any(named: 'expectedCount'),
      ),
    ).thenAnswer((_) async {});
  }

  test('type d\'agrégat = ATTENDANCE', () {
    expect(handler.aggregateType, 'ATTENDANCE');
  });

  test(
    'APPLIED → synced + rapatrie serverUpdatedAt/expectedCount (AG-3)',
    () async {
      when(
        () => api.submitAttendance(any(), any()),
      ).thenAnswer((_) async => response());
      stubMarkSynced();

      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      verify(
        () => local.markDaySynced(
          classroomId: 'c1',
          dateStr: '2026-06-15',
          academicYearId: 'year-1',
          syncedAt: 7000,
          serverUpdatedAt: '2026-06-15T09:00:00.000Z',
          expectedCount: 40,
        ),
      ).called(1);
    },
  );

  test('SUPERSEDED → traité comme succès (filet mono-tablette)', () async {
    when(
      () => api.submitAttendance(any(), any()),
    ).thenAnswer((_) async => response(outcome: 'SUPERSEDED'));
    stubMarkSynced();

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.acked);
  });

  test('réseau (NetworkFailure) → retry', () async {
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const NetworkFailure()));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('rejet métier (ValidationFailure) → failed', () async {
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const ValidationFailure('bad')));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('payload corrompu → failed (jamais rejouable)', () async {
    final result = await handler.dispatch(entry(payload: 'not-json'));
    expect(result.outcome, OutboxDispatchOutcome.failed);
    verifyNever(() => api.submitAttendance(any(), any()));
  });
}
