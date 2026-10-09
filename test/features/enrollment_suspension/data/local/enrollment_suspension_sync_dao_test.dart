import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_sync_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/local/enrollment_suspension_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_suspension/data/sync/suspension_period_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../suspension_fixtures.dart';

SuspensionPeriodDto _pulled(String student, {String? reactivatedAt}) =>
    SuspensionPeriodDto(
      id: 'srv-$student',
      enrollmentId: enrollmentOf(student),
      studentId: student,
      academicYearId: kYear,
      suspendedAt: '2026-10-01T08:00:00.000Z',
      reactivationId: reactivatedAt == null ? null : 'srv-rea-$student',
      reactivatedAt: reactivatedAt,
      reactivatedBy: reactivatedAt == null ? null : kAuthor,
    );

void main() {
  late Database db;
  late EnrollmentSuspensionSyncDao sync;
  late EnrollmentSuspensionReadDao reader;

  setUp(() async {
    db = await openFullOfflineDb();
    sync = EnrollmentSuspensionSyncDao(db);
    reader = EnrollmentSuspensionReadDao(db);
    await insertMember(db, 's1');
    await insertMember(db, 's2');
  });
  tearDown(() => db.close());

  test('le flux écrit les périodes et laisse les membres au serveur', () async {
    final written = await sync.applyPulled(
      [_pulled('s1'), _pulled('s2', reactivatedAt: '2026-10-02T08:00:00Z')],
      schoolId: kSchool,
      nowMs: 1,
    );

    expect(written, 2);
    // Le serveur projette lui-même ; le flux des membres apporte le statut.
    expect(await memberStatus(db, 's1'), 'ACTIVE');
    expect(await memberStatus(db, 's2'), 'ACTIVE');
    expect(
      (await reader.latestFor(enrollmentOf('s1')))!.syncState,
      RecordSyncState.synced,
    );
  });

  test('le flux n\'écrase pas un geste local en attente', () async {
    await EnrollmentSuspensionWriteDao(
      db,
    ).suspend([suspendGesture('s1')], schoolId: kSchool, nowMs: 1);

    final written = await sync.applyPulled(
      [_pulled('s1', reactivatedAt: '2026-10-02T08:00:00Z')],
      schoolId: kSchool,
      nowMs: 2,
    );

    expect(written, 0);
    expect((await reader.latestFor(enrollmentOf('s1')))!.id, 'sus-s1');
    expect(await memberStatus(db, 's1'), 'INACTIVE');
  });

  test('une période ouverte du serveur chasse une ouverte périmée', () async {
    await sync.applyPulled([_pulled('s1')], schoolId: kSchool, nowMs: 1);
    final other = SuspensionPeriodDto(
      id: 'srv-2',
      enrollmentId: enrollmentOf('s1'),
      studentId: 's1',
      academicYearId: kYear,
      suspendedAt: '2026-10-05T08:00:00.000Z',
    );

    await sync.applyPulled([other], schoolId: kSchool, nowMs: 2);

    expect((await reader.latestFor(enrollmentOf('s1')))!.id, 'srv-2');
  });

  test('le pull des membres garde la désactivation posée hors ligne', () async {
    await EnrollmentSuspensionWriteDao(
      db,
    ).suspend([suspendGesture('s1')], schoolId: kSchool, nowMs: 1);

    await ClassroomLocalDataSource(db).upsertMembers(
      members: [
        ClassroomMemberDto.fromJson({
          'id': 'm-s1-$kYear',
          'studentId': 's1',
          'classroomId': 'class-1',
          'academicYearId': kYear,
          'studentFirstName': 'Prénom',
          'studentLastName': 'Nom',
          'status': 'ACTIVE',
        }),
      ],
      syncedAt: 2,
    );

    expect(await memberStatus(db, 's1'), 'INACTIVE');
  });

  test(
    'un refus efface le curseur du flux : le prochain pull relit tout',
    () async {
      await db.insert('sync_meta', {
        'resource': 'enrollment_suspensions@$kSchool',
        'cursor': 'opaque',
        'synced_at': 1,
      });
      await EnrollmentSuspensionWriteDao(
        db,
      ).suspend([suspendGesture('s1')], schoolId: kSchool, nowMs: 1);

      await sync.undoRefused(
        suspendGesture('s1'),
        schoolId: kSchool,
        code: 'HTTP_403',
        reason: 'refus',
        nowMs: 2,
      );

      expect(await db.query('sync_meta'), isEmpty);
      expect(await memberStatus(db, 's1'), 'ACTIVE');
    },
  );

  test(
    'une entrée empoisonnée ne fait plus sauter l\'inscription au flux',
    () async {
      await EnrollmentSuspensionWriteDao(
        db,
      ).suspend([suspendGesture('s1')], schoolId: kSchool, nowMs: 1);
      await db.update('outbox', {'status': 'SYNC_ERROR'});

      final written = await sync.applyPulled(
        [_pulled('s1', reactivatedAt: '2026-10-02T08:00:00Z')],
        schoolId: kSchool,
        nowMs: 2,
      );

      expect(written, 1);
    },
  );
}
