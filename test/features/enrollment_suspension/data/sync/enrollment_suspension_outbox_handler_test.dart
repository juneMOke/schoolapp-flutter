import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/enrollment_suspension_change_bus.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_sync_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_api.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/enrollment_suspension_outbox_handler.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_gesture.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_period_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../suspension_fixtures.dart';

class _MockApi extends Mock implements EnrollmentSuspensionApi {}

SuspensionPeriodDto _period(
  String student, {
  required String id,
  String? reactivatedAt,
}) => SuspensionPeriodDto(
  id: id,
  enrollmentId: enrollmentOf(student),
  studentId: student,
  academicYearId: kYear,
  suspendedAt: '2026-10-08T08:00:00.000Z',
  reactivationId: reactivatedAt == null ? null : 'rea-$student',
  reactivatedAt: reactivatedAt,
  reactivatedBy: reactivatedAt == null ? null : kAuthor,
);

DioException _refused(int status, String code) => DioException(
  requestOptions: RequestOptions(),
  response: Response(
    requestOptions: RequestOptions(),
    statusCode: status,
    data: {'detailCode': code, 'message': code},
  ),
);

void main() {
  late Database db;
  late _MockApi api;
  late EnrollmentSuspensionWriteDao writer;
  late EnrollmentSuspensionReadDao reader;
  late OutboxDependencyState dependency;
  late EnrollmentSuspensionOutboxHandler handler;

  setUpAll(() => registerFallbackValue(suspendGesture('fallback')));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    writer = EnrollmentSuspensionWriteDao(db);
    reader = EnrollmentSuspensionReadDao(db);
    dependency = OutboxDependencyState.ready;
    await insertMember(db, 's1');
    handler = EnrollmentSuspensionOutboxHandler(
      api: api,
      sync: EnrollmentSuspensionSyncDao(db),
      outbox: OutboxDao(db),
      dependency: (_, _) async => dependency,
      bus: EnrollmentSuspensionChangeBus(),
      currentUser: CurrentUserContext()..set(kAuthor, schoolId: kSchool),
      extras: const {},
      now: () => 99,
    );
  });
  tearDown(() => db.close());

  Future<OutboxEntry> entryOf(String gestureId) async => (await OutboxDao(
    db,
  ).byId(EnrollmentSuspensionWriteDao.entryId(gestureId)))!;

  Future<OutboxDispatchResult> dispatch(String gestureId) async =>
      handler.dispatch(await entryOf(gestureId));

  Future<void> suspend() =>
      writer.suspend([suspendGesture('s1')], schoolId: kSchool, nowMs: 1);

  Future<void> reactivate() =>
      writer.reactivate([reactivateGesture('s1')], schoolId: kSchool, nowMs: 2);

  void answers(SuspensionPeriodDto? period, {bool suspended = true}) =>
      when(() => api.push(any(), any())).thenAnswer(
        (_) async => SuspensionGestureAckDto(
          enrollmentId: enrollmentOf('s1'),
          suspended: suspended,
          period: period,
        ),
      );

  test('accusé : la période devient la vérité du serveur', () async {
    await suspend();
    answers(_period('s1', id: 'sus-s1'));

    final result = await dispatch('sus-s1');

    expect(result.outcome, OutboxDispatchOutcome.acked);
    final latest = await reader.latestFor(enrollmentOf('s1'));
    expect(latest!.syncState, RecordSyncState.synced);
    expect(await memberStatus(db, 's1'), 'INACTIVE');
    final sent = verify(() => api.push(any(), captureAny())).captured.single;
    expect((sent as SuspensionGesture).op, SuspensionGestureOp.suspend);
  });

  test(
    'absorbée : la tablette se recale sur la période d\'une autre',
    () async {
      await suspend();
      answers(_period('s1', id: 'autre-tablette'));

      await dispatch('sus-s1');

      final open = await reader.openByEnrollment(
        schoolId: kSchool,
        academicYearId: kYear,
      );
      expect(open[enrollmentOf('s1')]!.id, 'autre-tablette');
      expect(await memberStatus(db, 's1'), 'INACTIVE');
    },
  );

  test('la réactivation attend la désactivation qui la précède', () async {
    await suspend();
    await reactivate();

    final result = await dispatch('rea-s1');

    expect(result.outcome, OutboxDispatchOutcome.blocked);
    verifyNever(() => api.push(any(), any()));
  });

  test(
    'un accusé intermédiaire ne défait pas un geste encore en file',
    () async {
      await suspend();
      await reactivate();
      answers(_period('s1', id: 'sus-s1'));

      await dispatch('sus-s1');

      // La réactivation attend encore : l'élève reste visible.
      expect(await memberStatus(db, 's1'), 'ACTIVE');
      expect((await reader.latestFor(enrollmentOf('s1')))!.isOpen, isFalse);
    },
  );

  test('dossier pas encore accusé : attente, sans envoi', () async {
    await suspend();
    dependency = OutboxDependencyState.waiting;

    expect((await dispatch('sus-s1')).outcome, OutboxDispatchOutcome.blocked);
    verifyNever(() => api.push(any(), any()));
  });

  test('409 ENROLLMENT_NOT_YET_SYNCED : attente', () async {
    await suspend();
    when(
      () => api.push(any(), any()),
    ).thenThrow(_refused(409, 'ENROLLMENT_NOT_YET_SYNCED'));

    expect((await dispatch('sus-s1')).outcome, OutboxDispatchOutcome.blocked);
    expect(await memberStatus(db, 's1'), 'INACTIVE');
  });

  test('5xx : rejoué, rien n\'est défait', () async {
    await suspend();
    when(() => api.push(any(), any())).thenThrow(_refused(503, 'DOWN'));

    expect((await dispatch('sus-s1')).outcome, OutboxDispatchOutcome.retry);
    expect(await memberStatus(db, 's1'), 'INACTIVE');
  });

  test(
    '422 sur une désactivation : la période s\'efface, l\'élève revient',
    () async {
      await suspend();
      when(
        () => api.push(any(), any()),
      ).thenThrow(_refused(422, 'ENROLLMENT_NOT_SUSPENDABLE'));

      final result = await dispatch('sus-s1');

      expect(result.outcome, OutboxDispatchOutcome.failed);
      expect(await reader.latestFor(enrollmentOf('s1')), isNull);
      expect(await memberStatus(db, 's1'), 'ACTIVE');
    },
  );

  test(
    '422 sur une réactivation : la période rouvre, marquée en échec',
    () async {
      await suspend();
      answers(_period('s1', id: 'sus-s1'));
      await dispatch('sus-s1');
      // Le moteur acquitte l'entrée après un `acked`.
      await OutboxDao(
        db,
      ).markAcked(EnrollmentSuspensionWriteDao.entryId('sus-s1'));
      await reactivate();
      when(
        () => api.push(any(), any()),
      ).thenThrow(_refused(422, 'SUSPENSION_ID_CONFLICT'));

      final result = await dispatch('rea-s1');

      expect(result.outcome, OutboxDispatchOutcome.failed);
      final latest = await reader.latestFor(enrollmentOf('s1'));
      expect(latest!.isOpen, isTrue);
      expect(latest.syncState, RecordSyncState.failed);
      expect(await memberStatus(db, 's1'), 'INACTIVE');
    },
  );

  test('ligne disparue : rien à envoyer', () async {
    await suspend();
    await db.delete('enrollment_suspensions');

    expect((await dispatch('sus-s1')).outcome, OutboxDispatchOutcome.acked);
    verifyNever(() => api.push(any(), any()));
  });

  test('geste d\'un autre utilisateur : attente de sa session', () async {
    await writer.suspend(
      [
        SuspensionGesture(
          op: SuspensionGestureOp.suspend,
          id: 'sus-x',
          enrollmentId: enrollmentOf('s1'),
          studentId: 's1',
          academicYearId: kYear,
          at: '2026-10-08T08:00:00.000Z',
          authorId: 'u-autre',
        ),
      ],
      schoolId: kSchool,
      nowMs: 1,
    );

    expect((await dispatch('sus-x')).outcome, OutboxDispatchOutcome.blocked);
  });
}
