import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_attendance_update_model.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_daily_attendance_command_model.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_sync_api.dart';

class MockAttendanceSyncApi extends Mock implements AttendanceSyncApi {}

class MockAttendanceLocalDataSource extends Mock
    implements AttendanceLocalDataSource {}

class FakeCommand extends Fake implements OfflineDailyAttendanceCommandModel {}

void main() {
  late MockAttendanceSyncApi api;
  late MockAttendanceLocalDataSource local;
  late AttendanceOutboxHandler handler;

  const auth = <String, dynamic>{'requiresAuth': true};

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(FakeCommand());
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

  const command = OfflineDailyAttendanceCommandModel(
    classroomId: 'c1',
    date: '2026-06-15',
    academicYearId: 'year-1',
    updates: [
      OfflineAttendanceUpdateModel(
        studentId: 's1',
        studentFirstName: 'A',
        studentLastName: 'B',
        studentGender: 'MALE',
        present: false,
        absenceReason: 'SICKNESS',
        updatedAt: '2026-06-15T00:00:00.000Z',
      ),
    ],
  );

  OutboxEntry entry({String? payload}) => OutboxEntry(
    id: 'ATTENDANCE:c1|2026-06-15|year-1',
    aggregateType: 'ATTENDANCE',
    aggregateId: 'c1|2026-06-15|year-1',
    operation: OutboxOperation.upsert,
    payload: payload ?? command.toJsonString(),
    createdAt: 1000,
  );

  DioException dio(Object? error) => DioException(
    requestOptions: RequestOptions(path: '/attendances'),
    error: error,
  );

  test('type d\'agrégat = ATTENDANCE', () {
    expect(handler.aggregateType, 'ATTENDANCE');
  });

  test('push OK → marque le jour synced + acked', () async {
    when(() => api.pushDailyAttendance(any(), any())).thenAnswer((_) async {});
    when(
      () => local.markDaySynced(
        classroomId: any(named: 'classroomId'),
        dateStr: any(named: 'dateStr'),
        academicYearId: any(named: 'academicYearId'),
        syncedAt: any(named: 'syncedAt'),
      ),
    ).thenAnswer((_) async {});

    final result = await handler.dispatch(entry());

    expect(result.outcome, OutboxDispatchOutcome.acked);
    verify(
      () => local.markDaySynced(
        classroomId: 'c1',
        dateStr: '2026-06-15',
        academicYearId: 'year-1',
        syncedAt: 7000,
      ),
    ).called(1);
  });

  test('réseau (NetworkFailure) → retry', () async {
    when(
      () => api.pushDailyAttendance(any(), any()),
    ).thenThrow(dio(const NetworkFailure()));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('rejet métier (ValidationFailure) → failed', () async {
    when(
      () => api.pushDailyAttendance(any(), any()),
    ).thenThrow(dio(const ValidationFailure('bad')));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('payload corrompu → failed (jamais rejouable)', () async {
    final result = await handler.dispatch(entry(payload: 'not-json'));
    expect(result.outcome, OutboxDispatchOutcome.failed);
    verifyNever(() => api.pushDailyAttendance(any(), any()));
  });
}
