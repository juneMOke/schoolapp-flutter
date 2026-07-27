import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_update.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/daily_attendance.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart'
    show kClassroomMembersResource;

import '../../../../../core/offline/offline_full_test_db.dart';

class MockIdGenerator extends Mock implements IdGenerator {}

void main() {
  late Database db;
  late ClassroomLocalDataSource roster;
  late AttendanceLocalDataSource local;
  late SyncMetaDao syncMeta;
  late OutboxDao outbox;
  late MockIdGenerator idGen;
  late AttendanceOfflineRepositoryImpl repo;

  const classroomId = 'c1';
  const yearId = 'year-1';
  final date = DateTime.utc(2026, 6, 15);
  var clock = 5000;

  ClassroomMemberDto member(String sid, {String gender = 'MALE'}) =>
      ClassroomMemberDto(
        id: 'm-$sid',
        studentId: sid,
        classroomId: classroomId,
        academicYearId: yearId,
        studentFirstName: 'First$sid',
        studentLastName: 'Last$sid',
        studentGender: gender,
      );

  AttendanceUpdate update(String sid, {required bool present}) =>
      AttendanceUpdate(
        studentId: sid,
        studentFirstName: 'First$sid',
        studentLastName: 'Last$sid',
        studentGender: StudentGender.male,
        present: present,
        absenceReason: present ? null : AbsenceReason.sickness,
      );

  setUp(() async {
    db = await openFullOfflineDb();
    roster = ClassroomLocalDataSource(db);
    local = AttendanceLocalDataSource(db);
    syncMeta = SyncMetaDao(db);
    outbox = OutboxDao(db);
    idGen = MockIdGenerator();
    clock = 5000;
    var counter = 0;
    when(() => idGen.newId()).thenAnswer((_) => 'id-${counter++}');

    repo = AttendanceOfflineRepositoryImpl(
      localDataSource: local,
      rosterDataSource: roster,
      syncMetaDao: syncMeta,
      idGenerator: idGen,
      now: () => clock,
    );

    await roster.upsertMembers(
      members: [member('s1'), member('s2'), member('s3')],
      syncedAt: 9999,
    );
    await syncMeta.setCursor(
      kClassroomMembersResource,
      cursor: '2026-06-05T08:00:00.000Z',
      syncedAt: 9999,
    );
  });

  tearDown(() async => db.close());

  const emptyDaily = DailyAttendance(taken: false, records: []);

  test(
    'loadDailyAttendance : pas de session ⇒ appel non fait, roster présent',
    () async {
      final daily = (await repo.loadDailyAttendance(
        classroomId: classroomId,
        date: date,
        academicYearId: yearId,
      )).getOrElse(() => emptyDaily);
      // Invariant #1 : aucune session ⇒ appel non fait (jamais « tous présents »).
      expect(daily.taken, isFalse);
      expect(daily.records, hasLength(3));
      expect(daily.records.every((r) => r.present), isTrue);
    },
  );

  test(
    'recordDailyAttendance : seul l\'absent est matérialisé (par exception)',
    () async {
      await repo.recordDailyAttendance(
        classroomId: classroomId,
        date: date,
        academicYearId: yearId,
        updates: [
          update('s1', present: false),
          update('s2', present: true),
          update('s3', present: true),
        ],
      );

      final rows = await local.getDayRecords(
        classroomId: classroomId,
        dateStr: '2026-06-15',
        academicYearId: yearId,
      );
      expect(rows, hasLength(1));
      expect(rows.first.studentId, 's1');
      expect(rows.first.present, isFalse);
      expect(rows.first.absenceReason, 'SICKNESS');

      // 1 entrée outbox ATTENDANCE (full-write).
      expect(await outbox.pendingCount(), 1);
      final entries = await outbox.pendingReady(clock + 1);
      expect(entries.first.aggregateType, 'ATTENDANCE');
      expect(entries.first.aggregateId, 'c1|2026-06-15|year-1');
    },
  );

  test('loadDailyAttendance fusionne les absences locales', () async {
    await repo.recordDailyAttendance(
      classroomId: classroomId,
      date: date,
      academicYearId: yearId,
      updates: [
        update('s1', present: false),
        update('s2', present: true),
        update('s3', present: true),
      ],
    );

    final daily = (await repo.loadDailyAttendance(
      classroomId: classroomId,
      date: date,
      academicYearId: yearId,
    )).getOrElse(() => emptyDaily);
    // Session créée ⇒ appel fait.
    expect(daily.taken, isTrue);
    final s1 = daily.records.firstWhere((r) => r.studentId == 's1');
    expect(s1.present, isFalse);
    expect(daily.records.where((r) => r.present).length, 2);
  });

  test(
    'correction (retard) : l\'élève sort des exceptions (présent = non-ligne)',
    () async {
      await repo.recordDailyAttendance(
        classroomId: classroomId,
        date: date,
        academicYearId: yearId,
        updates: [update('s1', present: false)],
      );
      clock = 6000; // horloge plus récente
      // Réconciliation par différence : s1 redevenu présent sort de la liste.
      await repo.recordDailyAttendance(
        classroomId: classroomId,
        date: date,
        academicYearId: yearId,
        updates: [update('s1', present: true)],
      );

      final rows = await local.getDayRecords(
        classroomId: classroomId,
        dateStr: '2026-06-15',
        academicYearId: yearId,
      );
      expect(rows, isEmpty);

      final daily = (await repo.loadDailyAttendance(
        classroomId: classroomId,
        date: date,
        academicYearId: yearId,
      )).getOrElse(() => emptyDaily);
      expect(daily.taken, isTrue);
      expect(
        daily.records.firstWhere((r) => r.studentId == 's1').present,
        isTrue,
      );
    },
  );

  test('outbox coalescé : ré-appel du même jour = 1 seule entrée', () async {
    await repo.recordDailyAttendance(
      classroomId: classroomId,
      date: date,
      academicYearId: yearId,
      updates: [update('s1', present: false)],
    );
    clock = 6000;
    await repo.recordDailyAttendance(
      classroomId: classroomId,
      date: date,
      academicYearId: yearId,
      updates: [update('s1', present: false), update('s2', present: false)],
    );
    expect(await outbox.pendingCount(), 1);
  });

  test('getAttendanceRate : (effectif − absences) / effectif', () async {
    await repo.recordDailyAttendance(
      classroomId: classroomId,
      date: date,
      academicYearId: yearId,
      updates: [update('s1', present: false)],
    );

    final rate = (await repo.getAttendanceRate(
      classroomId: classroomId,
      date: date,
      academicYearId: yearId,
    )).getOrElse(() => throw StateError('left'));

    expect(rate.effectif, 3);
    expect(rate.absences, 1);
    expect(rate.present, 2);
    expect(rate.rate, closeTo(2 / 3, 0.0001));
    expect(rate.syncedAt, 9999);
  });
}
