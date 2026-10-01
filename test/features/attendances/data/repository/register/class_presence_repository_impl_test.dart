import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/data/presence_schedule_reader.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_closure_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_draft_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_history_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_day_writer.dart';
import 'package:school_app_flutter/features/attendances/data/repository/register/class_presence_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/register/class_presence_repository.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

class _Ids extends Mock implements IdGenerator {}

void main() {
  late Database db;
  late AttendanceLocalDataSource sessions;
  late ClassPresenceRepositoryImpl repo;
  var clock = 1000;

  const ClassDayKey key = (
    classroomId: 'c1',
    academicYearId: 'y1',
    day: '2026-09-29',
  );

  ClassroomMemberDto member(String sid, String last) => ClassroomMemberDto(
    id: 'm-$sid',
    studentId: sid,
    classroomId: key.classroomId,
    academicYearId: key.academicYearId,
    studentFirstName: 'Prénom$sid',
    studentLastName: last,
    studentGender: 'FEMALE',
  );

  setUp(() async {
    db = await openFullOfflineDb();
    clock = 1000;
    final ids = _Ids();
    var n = 0;
    when(ids.newId).thenAnswer((_) => 'id-${n++}');
    sessions = AttendanceLocalDataSource(db);
    final roster = ClassroomLocalDataSource(db);
    await roster.upsertMembers(
      // Ordre d'arrivée volontairement non alphabétique.
      members: [
        member('s2', 'Zola'),
        member('s1', 'Mbuyi'),
        member('s3', 'Ilunga'),
      ],
      syncedAt: 1,
    );
    repo = ClassPresenceRepositoryImpl(
      sessions: sessions,
      history: AttendanceHistoryLocalDataSource(db),
      drafts: AttendanceDraftLocalDataSource(db),
      closures: AttendanceClosureLocalDataSource(db),
      roster: roster,
      scheduleReader: PresenceScheduleReader(db),
      outbox: OutboxDao(db),
      ids: ids,
      writer: AttendanceDayWriter(
        localDataSource: sessions,
        rosterDataSource: roster,
        idGenerator: ids,
        now: () => clock,
      ),
      now: () => clock,
    );
  });

  tearDown(() => db.close());

  Future<ClassPresenceDay> load() async =>
      (await repo.loadDay(key)).getOrElse(() => throw StateError('lecture'));

  ClassPresenceLine lineOf(ClassPresenceDay day, String sid) =>
      day.lines.firstWhere((line) => line.student.id == sid);

  final late = PresenceMark<AbsenceReason>(
    status: PresenceStatus.late,
    arrival: ClockTime.fromMinutes(7 * 60 + 48),
    lateMinutes: 18,
  );
  const absent = PresenceMark<AbsenceReason>(status: PresenceStatus.absent);

  Future<Map<String, dynamic>> lastPayload() async {
    final row = (await db.query('outbox')).single;
    return jsonDecode(row['payload']! as String) as Map<String, dynamic>;
  }

  test(
    'sans appel : la classe entière, à pointer, par ordre alphabétique',
    () async {
      final day = await load();
      expect(day.hasSession, isFalse);
      expect(day.validated, isFalse);
      expect(day.lines.map((l) => l.student.id), ['s3', 's1', 's2']);
      expect(day.lines.map((l) => l.student.number), [1, 2, 3]);
      expect(day.lines.every((l) => l.status == PresenceStatus.none), isTrue);
    },
  );

  test('les touches vont au brouillon, rien ne part', () async {
    await repo.saveMarks(key, {'s1': late, 's2': absent});
    final day = await load();
    expect(lineOf(day, 's1').mark, late);
    expect(lineOf(day, 's1').sync, RecordSyncState.pending);
    expect(lineOf(day, 's2').status, PresenceStatus.absent);
    expect(await db.query('outbox'), isEmpty);
    expect(await db.query('attendance_sessions'), isEmpty);

    // « À pointer » retire la ligne du brouillon.
    await repo.saveMarks(key, {'s1': const PresenceMark.none()});
    expect(lineOf(await load(), 's1').status, PresenceStatus.none);
  });

  test(
    'valider : le retard part avec son heure, le brouillon se vide',
    () async {
      await repo.saveMarks(key, {'s1': late, 's2': absent});
      final day = await load();
      final lines = [
        for (final line in day.lines)
          line.status == PresenceStatus.none
              ? line.withMark(
                  const PresenceMark(status: PresenceStatus.present),
                )
              : line,
      ];

      expect(await repo.validateDay(key, lines), const Right(unit));

      final records = await db.query(
        'attendance_records',
        orderBy: 'student_id',
      );
      expect(records.map((r) => r['student_id']), ['s1', 's2']);
      expect(records.first['status'], 'LATE');
      expect(records.first['present'], 1);
      expect(records.first['arrival_time'], '07:48');
      expect(records.first['late_minutes'], 18);
      expect(records.last['status'], 'ABSENT');
      expect(records.last['present'], 0);
      expect(await db.query('attendance_draft_marks'), isEmpty);

      final payload = await lastPayload();
      final sent = {
        for (final a in payload['absences'] as List) a['studentId']: a,
      };
      expect(sent['s1'], containsPair('status', 'LATE'));
      expect(sent['s1'], containsPair('arrivalTime', '07:48'));
      expect(sent['s1'], containsPair('lateMinutes', 18));
      // Le statut part TOUJOURS : manquant, le serveur garderait le sien.
      expect(sent['s2'], containsPair('status', 'ABSENT'));
      expect(sent['s2'], isNot(contains('arrivalTime')));

      final validated = await load();
      expect(validated.validated, isTrue);
      expect(lineOf(validated, 's3').status, PresenceStatus.present);
      expect(lineOf(validated, 's1').mark.lateMinutes, 18);
    },
  );

  test('un retard ne compte pas comme une absence dans l historique', () async {
    await repo.saveMarks(key, {'s1': late, 's2': absent});
    await repo.validateDay(key, (await load()).lines);
    final history = AttendanceHistoryLocalDataSource(db);

    final absences = await db.query('attendance_records', where: 'present = 0');
    expect(absences.map((row) => row['student_id']), ['s2']);
    expect(
      await history.getStudentAbsenceRecords(
        studentId: 's1',
        academicYearId: key.academicYearId,
      ),
      isEmpty,
    );
  });

  test(
    'justifier après coup : seule la ligne touchée change d horodatage',
    () async {
      await repo.saveMarks(key, {'s1': late, 's2': absent});
      await repo.validateDay(key, (await load()).lines);
      final before = {
        for (final r in await db.query('attendance_records'))
          r['student_id']: r['updated_at'],
      };

      clock = 9000;
      final day = await load();
      final justified = [
        for (final line in day.lines)
          line.student.id == 's2'
              ? line.withMark(
                  const PresenceMark(
                    status: PresenceStatus.absent,
                    justification: PresenceJustification(
                      reason: AbsenceReason.sickness,
                      note: 'mot des parents',
                    ),
                  ),
                )
              : line,
      ];
      await repo.validateDay(key, justified);

      final after = {
        for (final r in await db.query('attendance_records'))
          r['student_id']: r,
      };
      expect(after['s1']!['updated_at'], before['s1']);
      expect(after['s2']!['updated_at'], isNot(before['s2']));
      expect(after['s2']!['absence_reason'], 'SICKNESS');
      expect((await load()).validated, isTrue);
    },
  );

  test(
    'rouvrir : l appel revient au brouillon, revalider le referme',
    () async {
      await repo.saveMarks(key, {'s1': late});
      await repo.validateDay(key, (await load()).lines);

      await repo.reopenDay(key);
      final reopened = await load();
      expect(reopened.reopened, isTrue);
      expect(reopened.validated, isFalse);
      expect(lineOf(reopened, 's1').mark.lateMinutes, 18);
      expect(lineOf(reopened, 's3').status, PresenceStatus.present);

      await repo.saveMarks(key, {'s1': absent});
      await repo.validateDay(key, (await load()).lines);
      final again = await load();
      expect(again.validated, isTrue);
      expect(again.reopened, isFalse);
      expect(lineOf(again, 's1').status, PresenceStatus.absent);
      expect(await db.query('attendance_draft_marks'), isEmpty);
    },
  );

  test(
    'un verdict d avant la v2 repart tel quel tant qu on n y touche pas',
    () async {
      await db.insert('attendance_sessions', {
        'id': 'sess',
        'classroom_id': key.classroomId,
        'attendance_date': key.day,
        'academic_year_id': key.academicYearId,
        'updated_at': 10,
        'sync_status': 'SYNCED',
      });
      await db.insert('attendance_records', {
        'id': 'r-old',
        'session_id': 'sess',
        'student_id': 's2',
        'student_first_name': 'P',
        'student_last_name': 'Zola',
        'classroom_id': key.classroomId,
        'attendance_date': key.day,
        'academic_year_id': key.academicYearId,
        'present': 0,
        'absence_reason': 'UNKNOWN',
        'absence_reason_note': 'à vérifier',
        'updated_at': 10,
        'sync_status': 'SYNCED',
      });

      final day = await load();
      final line = lineOf(day, 's2');
      expect(line.mark.justification, isNull);
      expect(line.mark.needsJustification, isTrue);

      await repo.validateDay(key, day.lines);
      final sent = (await lastPayload())['absences'] as List;
      expect(sent.single, containsPair('absenceReason', 'UNKNOWN'));
      expect(sent.single, containsPair('absenceReasonNote', 'à vérifier'));
    },
  );

  test(
    'un envoi refusé se lit refusé, et Réessayer le remet en file',
    () async {
      await repo.saveMarks(key, {'s1': late});
      await repo.validateDay(key, (await load()).lines);
      final id = AttendanceDayWriter.outboxEntryId(
        key.classroomId,
        key.day,
        key.academicYearId,
      );
      await OutboxDao(db).markSyncError(id, 'Mois clôturé');

      final refused = await load();
      expect(refused.sync, RecordSyncState.failed);
      expect(refused.refusal, 'Mois clôturé');

      await repo.retryDay(key);
      expect((await load()).sync, RecordSyncState.pending);
    },
  );

  test(
    'le mois : jours appelés et incidents des appels validés seulement',
    () async {
      await repo.saveMarks(key, {'s1': late, 's2': absent});
      await repo.validateDay(key, (await load()).lines);
      // Un brouillon d'un autre jour n'est pas un appel.
      const ClassDayKey other = (
        classroomId: 'c1',
        academicYearId: 'y1',
        day: '2026-09-30',
      );
      await repo.saveMarks(other, {'s1': absent});

      final month = (await repo.loadMonth((
        classroomId: key.classroomId,
        academicYearId: key.academicYearId,
        month: '2026-09',
      ))).getOrElse(() => throw StateError('mois'));

      expect(month.calledDays, {'2026-09-29'});
      expect(month.incidentOf('2026-09-29', 's1')?.mark.lateMinutes, 18);
      expect(
        month.incidentOf('2026-09-29', 's2')?.status,
        PresenceStatus.absent,
      );
      expect(month.incidentOf('2026-09-29', 's3'), isNull);
      expect(month.incidentOf('2026-09-30', 's1'), isNull);
      expect(month.sync, RecordSyncState.pending);
      expect(month.closed, isFalse);
    },
  );

  test(
    'rouvert : une correction reçue entre-temps n est pas écrasée',
    () async {
      await repo.saveMarks(key, {'s2': absent});
      await repo.validateDay(key, (await load()).lines);
      await repo.reopenDay(key);
      clock = 2000;

      // Une autre tablette passe Jean (s2) en retard ; le pull l'applique.
      await db.update('attendance_sessions', {'sync_status': 'SYNCED'});
      await db.update(
        'attendance_records',
        {
          'status': 'LATE',
          'present': 1,
          'arrival_time': '07:50',
          'late_minutes': 20,
          'updated_at': 1500,
          'sync_status': 'SYNCED',
        },
        where: 'student_id = ?',
        whereArgs: ['s2'],
      );

      // L'écran rouvert montre la correction ; on ne touche que Grâce (s1).
      final reopened = await load();
      expect(lineOf(reopened, 's2').status, PresenceStatus.late);
      await repo.saveMarks(key, {'s1': absent});
      await repo.validateDay(key, (await load()).lines);

      final jean = (await db.query(
        'attendance_records',
        where: 'student_id = ?',
        whereArgs: ['s2'],
      )).single;
      expect(jean['status'], 'LATE');
      expect(jean['updated_at'], 1500);
    },
  );

  test('rouvert : remettre « à pointer » masque la ligne en base', () async {
    await repo.saveMarks(key, {'s2': absent});
    await repo.validateDay(key, (await load()).lines);
    await repo.reopenDay(key);

    await repo.saveMarks(key, {'s2': const PresenceMark.none()});

    expect(lineOf(await load(), 's2').status, PresenceStatus.none);
  });
}
