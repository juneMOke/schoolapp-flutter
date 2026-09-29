import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_gesture_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_lock_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_settings_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_gesture_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_lock_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_settings_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_settings_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_sync_api.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../staff_fixtures.dart';

class _MockApi extends Mock implements StaffAttendanceSyncApi {}

DioException _http(int status, {String? detailCode}) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
    data: detailCode == null ? null : {'detailCode': detailCode},
  ),
);

StaffAttendanceDto _record(
  String id, {
  String member = 'm-1',
  String day = '2026-09-29',
  String clock = '2026-09-29T08:00:00.000Z',
}) => StaffAttendanceDto(
  id: id,
  staffMemberId: member,
  workDate: day,
  status: 'PRESENT',
  arrivalTime: '07:30',
  clientUpdatedAt: clock,
);

void main() {
  late Database db;
  late _MockApi api;
  late OutboxDao outbox;
  late StaffAttendanceLockDao locks;
  late StaffAttendanceGestureDao gestureDao;
  late StaffAttendanceGestureOutboxHandler gestures;
  late StaffAttendanceOutboxHandler records;
  final user = CurrentUserContext()..set('u-1', schoolId: 's-1');

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    outbox = OutboxDao(db);
    locks = StaffAttendanceLockDao(db);
    gestureDao = StaffAttendanceGestureDao(db);
    records = StaffAttendanceOutboxHandler(
      api: api,
      dao: StaffAttendanceSyncDao(db),
      gestures: gestureDao,
      members: StaffMemberDao(db),
      currentUser: user,
      extras: const {},
      now: () => 5,
    );
    gestures = StaffAttendanceGestureOutboxHandler(
      api: api,
      locks: locks,
      gestures: gestureDao,
      records: StaffAttendanceDao(db),
      members: StaffMemberDao(db),
      currentUser: user,
      extras: const {},
      now: () => 5,
    );
  });
  tearDown(() async => db.close());

  Future<void> seedMember(String id, {bool acked = true}) async {
    await StaffMemberDao(db).applyPulled(
      [StaffMemberDeltaDto.tryParse(staffMemberJson(id))!],
      schoolId: 's-1',
      nowMs: 1,
    );
    if (!acked) {
      await db.update(
        'staff_members',
        {'version': null, 'sync_status': 'SYNC_ERROR'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> writeRecord(
    StaffAttendanceDto record, {
    int nowMs = 10,
  }) => StaffAttendanceWriteDao(db).save(
    [StaffAttendanceSyncRequestDto(staffAttendance: record, authorId: 'u-1')],
    schoolId: 's-1',
    nowMs: nowMs,
  );

  Future<void> addGesture(
    String id,
    StaffAttendanceGesture gesture, {
    String date = '2026-09-29',
    int nowMs = 20,
  }) => gestureDao.add(
    StaffAttendanceGestureRequestDto(
      gestureId: id,
      gesture: gesture.wire,
      date: date,
      clientRecordedAt: '2026-09-29T16:00:00.000Z',
      authorId: 'u-1',
    ),
    kind: gesture.kind,
    authorName: null,
    recordedAt: '2026-09-29T16:00:00Z',
    schoolId: 's-1',
    nowMs: nowMs,
  );

  Future<OutboxEntry> entry(String id) async =>
      (await outbox.pendingAll()).firstWhere((e) => e.id == id);

  Future<Map<String, Object?>> recordRow(String id) async => (await db.query(
    'staff_attendance_records',
    where: 'id = ?',
    whereArgs: [id],
  )).single;

  group('pointage', () {
    test(
      'attend la fiche de l\'agent tant qu\'elle n\'est pas accusée',
      () async {
        await seedMember('m-1', acked: false);
        await writeRecord(_record('r-1'));

        final result = await records.dispatch(
          await entry(StaffAttendanceWriteDao.entryId('r-1')),
        );

        expect(result.outcome, OutboxDispatchOutcome.blocked);
        verifyNever(() => api.submitAttendance(any(), any()));
      },
    );

    test('attend derrière une réouverture du jour encore en vol', () async {
      await seedMember('m-1');
      await addGesture('g-1', StaffAttendanceGesture.reopenDay, nowMs: 5);
      await writeRecord(_record('r-1'));

      final result = await records.dispatch(
        await entry(StaffAttendanceWriteDao.entryId('r-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });

    test('accusé : la ligne passe au serveur', () async {
      await seedMember('m-1');
      await writeRecord(_record('r-1'));
      when(() => api.submitAttendance(any(), any())).thenAnswer(
        (_) async => StaffAttendanceSyncResponseDto(
          staffAttendance: _record('r-1'),
          lwwOutcome: 'APPLIED',
        ),
      );

      final result = await records.dispatch(
        await entry(StaffAttendanceWriteDao.entryId('r-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect((await recordRow('r-1'))['sync_status'], 'SYNCED');
    });

    test('DAY_LOCKED est définitif et rangé sur la ligne', () async {
      await seedMember('m-1');
      await writeRecord(_record('r-1'));
      when(
        () => api.submitAttendance(any(), any()),
      ).thenThrow(_http(422, detailCode: 'DAY_LOCKED'));

      final result = await records.dispatch(
        await entry(StaffAttendanceWriteDao.entryId('r-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.failed);
      final row = await recordRow('r-1');
      expect(row['sync_status'], 'SYNC_ERROR');
      expect(row['sync_error_code'], 'DAY_LOCKED');
    });

    test('retouché pendant le vol : le refus ne gèle pas la saisie', () async {
      await seedMember('m-1');
      await writeRecord(_record('r-1'));
      final sent = await entry(StaffAttendanceWriteDao.entryId('r-1'));
      await writeRecord(
        _record('r-1', clock: '2026-09-29T09:00:00.000Z'),
        nowMs: 11,
      );
      when(
        () => api.submitAttendance(any(), any()),
      ).thenThrow(_http(422, detailCode: 'INCOHERENT_ATTENDANCE'));

      final result = await records.dispatch(sent);

      expect(result.outcome, OutboxDispatchOutcome.retry);
      expect((await recordRow('r-1'))['sync_status'], 'PENDING_SYNC');
    });
  });

  group('contrat v3', () {
    test('un geste porte clientRecordedAt, exigé par le serveur', () async {
      await addGesture('g-1', StaffAttendanceGesture.validateDay);

      final payload =
          jsonDecode(
                (await entry(StaffAttendanceGestureDao.entryId('g-1'))).payload,
              )
              as Map<String, dynamic>;

      expect(payload['clientRecordedAt'], '2026-09-29T16:00:00.000Z');
      expect(payload.keys, containsAll(['gestureId', 'gesture', 'date']));
    });

    test('les réglages partent sous `settings`, l\'ancienne clé se relit', () {
      const request = StaffAttendanceSettingsRequestDto(
        startTime: '07:30',
        toleranceMinutes: 10,
        clientUpdatedAt: '2026-09-29T08:00:00.000Z',
        authorId: 'u-1',
      );

      expect(request.toJson().keys, containsAll(['settings', 'authorId']));
      expect(
        StaffAttendanceSettingsRequestDto.tryParse({
          'staffAttendanceSettings': {
            'startTime': '07:45',
            'toleranceMinutes': 5,
            'clientUpdatedAt': '2026-09-29T08:00:00.000Z',
          },
          'authorId': 'u-1',
        })?.startTime,
        '07:45',
      );
    });

    test('un réglage SUPERSEDED cède la place à celui du serveur', () async {
      final dao = StaffAttendanceSettingsDao(db);
      await dao.save(
        const StaffAttendanceSettingsRequestDto(
          startTime: '07:30',
          toleranceMinutes: 10,
          clientUpdatedAt: '2026-09-29T08:00:00.000Z',
          authorId: 'u-1',
        ),
        schoolId: 's-1',
        nowMs: 1,
      );
      when(() => api.putSettings(any(), any())).thenAnswer(
        (_) async => const StaffAttendanceSettingsResponseDto(
          startTime: '08:00',
          toleranceMinutes: 15,
          lwwOutcome: 'SUPERSEDED',
        ),
      );
      final handler = StaffAttendanceSettingsOutboxHandler(
        api: api,
        dao: dao,
        currentUser: user,
        extras: const {},
      );

      final result = await handler.dispatch(
        await entry(StaffAttendanceSettingsDao.entryId('s-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final settings = await dao.read('s-1');
      expect(settings.start.wire, '08:00');
      expect(settings.toleranceMinutes, 15);
    });
  });

  group('geste de verrou', () {
    void answerLocked(String state) =>
        when(() => api.submitGesture(any(), any())).thenAnswer(
          (_) async => StaffAttendanceLockDto(
            kind: 'DAY',
            periodStart: '2026-09-29',
            state: state,
          ),
        );

    test('une validation attend les pointages du jour en file', () async {
      await seedMember('m-1');
      await writeRecord(_record('r-1'));
      await addGesture('g-1', StaffAttendanceGesture.validateDay);

      final result = await gestures.dispatch(
        await entry(StaffAttendanceGestureDao.entryId('g-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
      verifyNever(() => api.submitGesture(any(), any()));
    });

    test('sortie de secours : un pointage dont la fiche est refusée ne '
        'retient pas la validation', () async {
      await seedMember('m-2', acked: false);
      await writeRecord(_record('r-2', member: 'm-2'));
      await addGesture('g-1', StaffAttendanceGesture.validateDay);
      answerLocked('LOCKED');

      final result = await gestures.dispatch(
        await entry(StaffAttendanceGestureDao.entryId('g-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      final shown = await locks.effective(
        's-1',
        from: '2026-09-01',
        to: '2026-09-30',
      );
      expect(shown.single.locked, isTrue);
    });

    test('un geste attend son aîné encore en file', () async {
      await addGesture('g-1', StaffAttendanceGesture.validateDay, nowMs: 20);
      await addGesture('g-2', StaffAttendanceGesture.reopenDay, nowMs: 30);

      final result = await gestures.dispatch(
        await entry(StaffAttendanceGestureDao.entryId('g-2')),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });

    test('une réouverture accusée remet en file les pointages refusés '
        'DAY_LOCKED du jour', () async {
      await seedMember('m-1');
      await writeRecord(_record('r-1'));
      await StaffAttendanceSyncDao(db).markRejected(
        'r-1',
        sentClientUpdatedAt: '2026-09-29T08:00:00.000Z',
        code: 'DAY_LOCKED',
        reason: 'DAY_LOCKED',
        nowMs: 12,
      );
      await outbox.markSyncError(StaffAttendanceWriteDao.entryId('r-1'), 'x');
      await addGesture('g-1', StaffAttendanceGesture.reopenDay);
      answerLocked('OPEN');

      final result = await gestures.dispatch(
        await entry(StaffAttendanceGestureDao.entryId('g-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
      expect((await recordRow('r-1'))['sync_status'], 'PENDING_SYNC');
      expect(
        (await outbox.pendingAll()).map((e) => e.id),
        contains(StaffAttendanceWriteDao.entryId('r-1')),
      );
    });

    test(
      'valider, rouvrir, corriger : aucun interblocage, dans l\'ordre',
      () async {
        await seedMember('m-1');
        await addGesture('v', StaffAttendanceGesture.validateDay, nowMs: 20);
        await addGesture('r', StaffAttendanceGesture.reopenDay, nowMs: 30);
        await writeRecord(_record('r-1'), nowMs: 40);

        // La correction attend la réouverture, qui attend la validation…
        expect(
          (await records.dispatch(
            await entry(StaffAttendanceWriteDao.entryId('r-1')),
          )).outcome,
          OutboxDispatchOutcome.blocked,
        );
        expect(
          (await gestures.dispatch(
            await entry(StaffAttendanceGestureDao.entryId('r')),
          )).outcome,
          OutboxDispatchOutcome.blocked,
        );
        // … mais la validation, antérieure à la correction, ne l'attend pas.
        answerLocked('LOCKED');
        expect(
          (await gestures.dispatch(
            await entry(StaffAttendanceGestureDao.entryId('v')),
          )).outcome,
          OutboxDispatchOutcome.acked,
        );
        answerLocked('OPEN');
        expect(
          (await gestures.dispatch(
            await entry(StaffAttendanceGestureDao.entryId('r')),
          )).outcome,
          OutboxDispatchOutcome.acked,
        );
      },
    );

    test('une fiche accusée puis refusée ne dispense pas la validation '
        'd\'attendre ses pointages', () async {
      await seedMember('m-1');
      await db.update(
        'staff_members',
        {'sync_status': 'SYNC_ERROR'},
        where: 'id = ?',
        whereArgs: ['m-1'],
      );
      await writeRecord(_record('r-1'));
      await addGesture('g-1', StaffAttendanceGesture.validateDay);

      final result = await gestures.dispatch(
        await entry(StaffAttendanceGestureDao.entryId('g-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.blocked);
    });

    test('deux gestes de la même milliseconde ne s\'attendent pas l\'un '
        'l\'autre', () async {
      await addGesture('g-1', StaffAttendanceGesture.validateDay, nowMs: 20);
      await addGesture('g-2', StaffAttendanceGesture.reopenDay, nowMs: 20);
      answerLocked('LOCKED');

      final first = await gestures.dispatch(
        await entry(StaffAttendanceGestureDao.entryId('g-1')),
      );

      expect(first.outcome, OutboxDispatchOutcome.acked);
    });

    test('un aîné sorti de la file (empoisonné) ne gèle pas les suivants, '
        'et se lit en échec', () async {
      await addGesture('g-1', StaffAttendanceGesture.validateDay, nowMs: 20);
      await addGesture('g-2', StaffAttendanceGesture.reopenDay, nowMs: 30);
      await outbox.markSyncError(StaffAttendanceGestureDao.entryId('g-1'), 'x');
      answerLocked('OPEN');

      final result = await gestures.dispatch(
        await entry(StaffAttendanceGestureDao.entryId('g-2')),
      );

      expect(result.outcome, OutboxDispatchOutcome.acked);
    });

    test('une réouverture venue d\'une autre tablette remet en file les '
        'pointages DAY_LOCKED', () async {
      await seedMember('m-1');
      await locks.applyServer(
        [
          const StaffAttendanceLockDto(
            kind: 'DAY',
            periodStart: '2026-09-29',
            state: 'LOCKED',
          ),
        ],
        schoolId: 's-1',
        nowMs: 1,
      );
      await writeRecord(_record('r-1'));
      await StaffAttendanceSyncDao(db).markRejected(
        'r-1',
        sentClientUpdatedAt: '2026-09-29T08:00:00.000Z',
        code: 'DAY_LOCKED',
        reason: 'DAY_LOCKED',
        nowMs: 12,
      );
      await outbox.markSyncError(StaffAttendanceWriteDao.entryId('r-1'), 'x');

      await locks.applyServer(
        [
          const StaffAttendanceLockDto(
            kind: 'DAY',
            periodStart: '2026-09-29',
            state: 'OPEN',
          ),
        ],
        schoolId: 's-1',
        nowMs: 13,
      );

      expect((await recordRow('r-1'))['sync_status'], 'PENDING_SYNC');
      expect(
        (await outbox.pendingAll()).map((e) => e.id),
        contains(StaffAttendanceWriteDao.entryId('r-1')),
      );
    });

    test('un refus laisse l\'état du serveur, marqué en échec', () async {
      await addGesture('g-1', StaffAttendanceGesture.validateDay);
      when(
        () => api.submitGesture(any(), any()),
      ).thenThrow(_http(422, detailCode: 'MONTH_CLOSED'));

      final result = await gestures.dispatch(
        await entry(StaffAttendanceGestureDao.entryId('g-1')),
      );

      expect(result.outcome, OutboxDispatchOutcome.failed);
      final shown = await locks.effective(
        's-1',
        from: '2026-09-01',
        to: '2026-09-30',
      );
      expect(shown.single.locked, isFalse);
    });
  });
}
