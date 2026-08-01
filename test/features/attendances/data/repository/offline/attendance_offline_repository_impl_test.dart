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

  group('conformité régime C (payload exhaustif + horloge monotone)', () {
    test(
      'une absence NON AFFICHEE mais toujours au roster est PRESERVEE',
      () async {
        // s3 est absent le 15/06 : la ligne existe en base.
        await repo.recordDailyAttendance(
          classroomId: classroomId,
          date: date,
          academicYearId: yearId,
          updates: [
            update('s1', present: true),
            update('s2', present: true),
            update('s3', present: false),
          ],
        );

        // L'enseignant corrige s1 depuis une vue qui n'affiche PAS s3 (filtre,
        // pagination) : s3 est toujours membre actif, il n'a simplement jamais
        // ete sous les yeux de l'utilisateur.
        clock = 6000;
        await repo.recordDailyAttendance(
          classroomId: classroomId,
          date: date,
          academicYearId: yearId,
          updates: [update('s1', present: false), update('s2', present: true)],
        );

        // Omettre s3 du payload le ferait SUPPRIMER cote serveur par
        // reconciliation par difference, alors que personne n'a voulu le retirer.
        final rows = await db.query(
          'attendance_records',
          where: 'attendance_date = ?',
          whereArgs: ['2026-06-15'],
        );
        expect(rows.map((r) => r['student_id']).toSet(), {'s1', 's3'});

        final entry = (await outbox.pendingReady(999999)).single;
        expect(entry.payload, contains('s3'));
      },
    );

    test(
      'un élève affiché et marqué présent est bien retiré (suppression voulue)',
      () async {
        await repo.recordDailyAttendance(
          classroomId: classroomId,
          date: date,
          academicYearId: yearId,
          updates: [update('s1', present: false), update('s2', present: true)],
        );
        clock = 6000;
        await repo.recordDailyAttendance(
          classroomId: classroomId,
          date: date,
          academicYearId: yearId,
          updates: [update('s1', present: true), update('s2', present: true)],
        );

        final rows = await db.query('attendance_records');
        expect(rows, isEmpty, reason: 'retard corrigé = non-ligne');
      },
    );

    test(
      'horloge monotone : correction non perdue quand updated_at vient du serveur',
      () async {
        await repo.recordDailyAttendance(
          classroomId: classroomId,
          date: date,
          academicYearId: yearId,
          updates: [update('s1', present: false)],
        );
        // La session est réalignée sur un temps SERVEUR très en avance sur
        // l'horloge du device (cas nominal : pull au temps serveur).
        await db.update('attendance_sessions', {'updated_at': 900000});

        clock = 6000; // device en retard
        final result = await repo.recordDailyAttendance(
          classroomId: classroomId,
          date: date,
          academicYearId: yearId,
          updates: [update('s1', present: true)],
        );

        expect(result.isRight(), isTrue);
        final session = (await db.query('attendance_sessions')).single;
        expect(
          session['updated_at'] as int,
          greaterThan(900000),
          reason:
              'sans horloge monotone, la garde locale sauterait l\'écriture '
              'et le serveur arbitrerait SUPERSEDED',
        );
      },
    );

    test('takenAt garde l\'heure du premier appel', () async {
      await repo.recordDailyAttendance(
        classroomId: classroomId,
        date: date,
        academicYearId: yearId,
        updates: [update('s1', present: false)],
      );
      final firstTakenAt =
          (await db.query('attendance_sessions')).single['taken_at'] as int;

      clock = 88000;
      await repo.recordDailyAttendance(
        classroomId: classroomId,
        date: date,
        academicYearId: yearId,
        updates: [update('s2', present: false)],
      );

      expect(
        (await db.query('attendance_sessions')).single['taken_at'],
        firstTakenAt,
        reason: 'une correction ne redate pas l\'appel d\'origine',
      );
    });

    test(
      'un eleve SORTI du roster n est PAS reinjecte (sinon 422 sans issue)',
      () async {
        await repo.recordDailyAttendance(
          classroomId: classroomId,
          date: date,
          academicYearId: yearId,
          updates: [update('s1', present: true), update('s3', present: false)],
        );

        // s3 quitte la classe (transfert) : il sort du roster ACTIF.
        await db.update(
          'ref_classroom_members',
          {'classroom_id': 'c2'},
          where: 'student_id = ?',
          whereArgs: ['s3'],
        );

        clock = 6000;
        await repo.recordDailyAttendance(
          classroomId: classroomId,
          date: date,
          academicYearId: yearId,
          updates: [update('s1', present: false)],
        );

        // Le serveur valide requireAllInRoster sur son roster ACTIF courant et
        // rejette l AGREGAT ENTIER en 422 s il voit s3. Comme ATTENDANCE n est
        // pas rejouable et que la ligne survivrait a chaque revalidation, le
        // 422 serait deterministe et sans aucune sortie depuis l application.
        final entry = (await outbox.pendingReady(999999)).single;
        expect(entry.payload, isNot(contains('s3')));
      },
    );
  });
}
