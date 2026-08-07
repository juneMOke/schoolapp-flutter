import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
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

  // `authorId` estampillé à la SAISIE (ADR-010 D-05) : c'est lui que le serveur
  // compare à l'uid du jeton présenté.
  const aggregate = AttendanceAggregateRequestModel(
    authorId: 'author-1',
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
    String? updatedAt,
    List<AttendanceAbsenceAck> absences = const [],
  }) => AttendanceAggregateResponseModel(
    sessionId: 'sess-1',
    serverUpdatedAt: serverUpdatedAt,
    expectedCount: expectedCount,
    lwwOutcome: outcome,
    updatedAt: updatedAt,
    absences: absences,
  );

  OutboxEntry entry({String? payload}) => OutboxEntry(
    id: 'ATTENDANCE:c1|2026-06-15|year-1',
    aggregateType: 'ATTENDANCE',
    aggregateId: 'c1|2026-06-15|year-1',
    operation: OutboxOperation.upsert,
    payload: payload ?? aggregate.toJsonString(),
    createdAt: 1000,
  );

  /// Handler dont le porteur du jeton est [uid] — permet de distinguer un 403
  /// d'attribution (auteur absent de la session courante) d'un 403 réellement
  /// terminal.
  AttendanceOutboxHandler handlerFor({required String uid}) {
    final ctx = CurrentUserContext()..set(uid);
    return AttendanceOutboxHandler(
      syncApi: api,
      localDataSource: local,
      requiredAuth: auth,
      currentUser: ctx,
      now: () => 7000,
    );
  }

  DioException dio(Object? error, {int? status}) => DioException(
    requestOptions: RequestOptions(path: '/sync/attendance'),
    error: error,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: RequestOptions(path: '/sync/attendance'),
            statusCode: status,
          ),
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

  test(
    'SUPERSEDED → adopte l\'état canonique du gagnant, jamais markDaySynced',
    () async {
      // Le serveur sort AVANT toute écriture : notre version a perdu. On ne
      // doit ni sceller nos valeurs (divergence muette), ni laisser la session
      // PENDING_SYNC (elle deviendrait invisible au pull, donc irréparable).
      when(() => api.submitAttendance(any(), any())).thenAnswer(
        (_) async => response(
          outcome: 'SUPERSEDED',
          updatedAt: '2026-06-15T10:00:00.000Z',
          absences: const [
            AttendanceAbsenceAck(
              studentId: 's9',
              absenceReason: 'LATE',
              updatedAt: '2026-06-15T10:00:00.000Z',
            ),
          ],
        ),
      );
      when(
        () => local.adoptCanonicalDay(
          classroomId: any(named: 'classroomId'),
          dateStr: any(named: 'dateStr'),
          academicYearId: any(named: 'academicYearId'),
          canonicalAbsences: any(named: 'canonicalAbsences'),
          updatedAt: any(named: 'updatedAt'),
          syncedAt: any(named: 'syncedAt'),
          serverUpdatedAt: any(named: 'serverUpdatedAt'),
          expectedCount: any(named: 'expectedCount'),
        ),
      ).thenAnswer((_) async {});
      stubMarkSynced();

      final result = await handler.dispatch(entry());

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final captured =
          verify(
                () => local.adoptCanonicalDay(
                  classroomId: 'c1',
                  dateStr: '2026-06-15',
                  academicYearId: 'year-1',
                  canonicalAbsences: captureAny(named: 'canonicalAbsences'),
                  // Jeton du GAGNANT : rester sur le nôtre ferait reperdre tous les
                  // arbitrages suivants.
                  updatedAt: DateTime.utc(
                    2026,
                    6,
                    15,
                    10,
                  ).millisecondsSinceEpoch,
                  syncedAt: 7000,
                  serverUpdatedAt: any(named: 'serverUpdatedAt'),
                  expectedCount: any(named: 'expectedCount'),
                ),
              ).captured.single
              as Map<String, CanonicalAbsence>;
      expect(captured.keys, ['s9']);
      expect(captured['s9']!.absenceReason, 'LATE');

      verifyNever(
        () => local.markDaySynced(
          classroomId: any(named: 'classroomId'),
          dateStr: any(named: 'dateStr'),
          academicYearId: any(named: 'academicYearId'),
          syncedAt: any(named: 'syncedAt'),
          serverUpdatedAt: any(named: 'serverUpdatedAt'),
          expectedCount: any(named: 'expectedCount'),
        ),
      );
    },
  );

  test('réseau (NetworkFailure) → retry', () async {
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const NetworkFailure()));

    final result = await handler.dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.retry);
  });

  test('403 auteur == utilisateur courant → failed (pas 50 retries)', () async {
    // Le refus ne vient pas de l'attribution : il ne se réparera pas seul.
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const UnauthorizedFailure('forbidden'), status: 403));

    final result = await handlerFor(uid: 'author-1').dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.failed);
  });

  test('403 auteur != utilisateur courant → blocked (tablette partagée)', () async {
    // `SyncAttributionGuard` refuse le JETON PRÉSENTÉ, pas l'écriture : l'appel
    // de A flushé sous la session de B repartira tel quel à la reconnexion de A.
    // Le classer terminal brûlerait un appel parfaitement valide.
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const UnauthorizedFailure('forbidden'), status: 403));

    final result = await handlerFor(uid: 'someone-else').dispatch(entry());
    expect(result.outcome, OutboxDispatchOutcome.blocked);
  });

  test('401 (ré-auth) reste transitoire', () async {
    when(
      () => api.submitAttendance(any(), any()),
    ).thenThrow(dio(const UnauthorizedFailure('expired'), status: 401));

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
