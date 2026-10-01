import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_closure_models.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_api.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_outbox_handler.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_day_writer.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class _Api extends Mock implements AttendanceClosureApi {}

void main() {
  late Database db;
  late AttendanceClosureLocalDataSource closures;
  late OutboxDao outbox;
  late _Api api;
  late AttendanceClosureOutboxHandler handler;

  const request = AttendanceClosureRequestModel(
    gestureId: 'g-1',
    classroomId: 'c1',
    academicYearId: 'y1',
    month: '2026-09',
    clientRecordedAt: '2026-10-01T08:00:00Z',
    authorId: 'uid-1',
  );

  OutboxEntry closureEntry({int createdAt = 200}) => OutboxEntry(
    id: request.gestureId,
    aggregateType: kAttendanceClosureAggregateType,
    aggregateId: 'c1|2026-09|y1',
    operation: OutboxOperation.upsert,
    payload: request.toJsonString(),
    createdAt: createdAt,
  );

  Future<void> record() => closures.record(
    gestureId: request.gestureId,
    classroomId: 'c1',
    academicYearId: 'y1',
    month: '2026-09',
    closedAt: request.clientRecordedAt,
    entry: closureEntry(),
  );

  Future<bool> closed() => closures.isClosed(
    classroomId: 'c1',
    academicYearId: 'y1',
    month: '2026-09',
  );

  DioException refused(int status, Map<String, dynamic> body) => DioException(
    requestOptions: RequestOptions(path: '/sync/attendance-closures'),
    error: status == 422
        ? const ValidationFailure('Invalid request data')
        : null,
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/sync/attendance-closures'),
      statusCode: status,
      data: body,
    ),
  );

  setUpAll(() => registerFallbackValue(request));

  setUp(() async {
    db = await openFullOfflineDb();
    closures = AttendanceClosureLocalDataSource(db);
    outbox = OutboxDao(db);
    api = _Api();
    handler = AttendanceClosureOutboxHandler(
      api: api,
      closures: closures,
      outbox: outbox,
      requiredAuth: const {},
    );
  });

  tearDown(() => db.close());

  test('saisie : le mois se fige aussitôt, le geste part en file', () async {
    await record();
    expect(await closed(), isTrue);
    final entry = (await outbox.pendingReady(999999)).single;
    expect(entry.aggregateType, kAttendanceClosureAggregateType);
    expect(entry.id, 'g-1');
  });

  test('accusé : la clôture du serveur est adoptée', () async {
    await record();
    when(() => api.submitClosure(any(), any())).thenAnswer(
      (_) async => const AttendanceClosureDto(
        classroomId: 'c1',
        academicYearId: 'y1',
        month: '2026-09',
        closedAt: '2026-10-01T08:00:05Z',
        closedBy: 'Préfet Kabila',
      ),
    );

    final result = await handler.dispatch(closureEntry());

    expect(result.outcome, OutboxDispatchOutcome.acked);
    final closure = await closures.closureOf(
      classroomId: 'c1',
      academicYearId: 'y1',
      month: '2026-09',
    );
    expect(closure!.closedBy, 'Préfet Kabila');
    expect(closure.recordSync, RecordSyncState.synced);
  });

  test('un appel mis en file avant la clôture part d abord', () async {
    await outbox.enqueue(
      const OutboxEntry(
        id: 'ATTENDANCE:c1|2026-09-30|y1',
        aggregateType: kAttendanceAggregateType,
        aggregateId: 'c1|2026-09-30|y1',
        operation: OutboxOperation.upsert,
        payload: '{}',
        createdAt: 100,
      ),
    );
    await record();

    final result = await handler.dispatch(closureEntry());

    expect(result.outcome, OutboxDispatchOutcome.blocked);
    verifyNever(() => api.submitClosure(any(), any()));
  });

  test(
    'mois pas fini : refus définitif, lisible, et le mois ne se fige plus',
    () async {
      await record();
      when(() => api.submitClosure(any(), any())).thenThrow(
        refused(422, {'detailCode': 'MONTH_NOT_ENDED', 'message': 'not ended'}),
      );

      final result = await handler.dispatch(closureEntry());

      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect(result.error, contains("n'est pas terminé"));
      expect(await closed(), isFalse);
      final closure = await closures.closureOf(
        classroomId: 'c1',
        academicYearId: 'y1',
        month: '2026-09',
      );
      expect(closure!.refusal, contains("n'est pas terminé"));
    },
  );

  test('réseau : nouvel essai, le mois reste figé', () async {
    await record();
    when(() => api.submitClosure(any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/sync/attendance-closures'),
        error: const NetworkFailure('offline'),
      ),
    );

    final result = await handler.dispatch(closureEntry());

    expect(result.outcome, OutboxDispatchOutcome.retry);
    expect(await closed(), isTrue);
  });

  test('pull : la clôture d une autre tablette fige le mois', () async {
    await closures.applyPulled(const [
      AttendanceClosureDto(
        id: 'srv-1',
        classroomId: 'c1',
        academicYearId: 'y1',
        month: '2026-09',
        closedAt: '2026-10-01T09:00:00Z',
      ),
    ]);
    expect(await closed(), isTrue);
  });
}
