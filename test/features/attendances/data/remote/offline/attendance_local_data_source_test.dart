import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_pull_models.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

/// Verrouille la sémantique SESSION du DAO d'appel (contrat 1.2.0) : les 3 états,
/// la réconciliation par différence, le bump d'`updated_at` de la session et le LWW.
void main() {
  late Database db;
  late AttendanceLocalDataSource dao;

  const classroomId = 'c1';
  const yearId = 'y1';
  const dateStr = '2026-06-15';

  setUp(() async {
    db = await openFullOfflineDb();
    dao = AttendanceLocalDataSource(db);
  });

  tearDown(() async => db.close());

  AttendanceSessionRow session({required int updatedAt, int? takenAt}) =>
      AttendanceSessionRow(
        id: 'sess-$updatedAt',
        classroomId: classroomId,
        attendanceDate: dateStr,
        academicYearId: yearId,
        takenAt: takenAt ?? updatedAt,
        updatedAt: updatedAt,
      );

  AttendanceRecordRow absent(String sid, {required int updatedAt}) =>
      AttendanceRecordRow(
        id: 'rec-$sid-$updatedAt',
        studentId: sid,
        studentFirstName: 'F$sid',
        studentLastName: 'L$sid',
        studentGender: 'MALE',
        classroomId: classroomId,
        attendanceDate: dateStr,
        academicYearId: yearId,
        present: false,
        absenceReason: 'SICKNESS',
        updatedAt: updatedAt,
      );

  OutboxEntry outbox() => const OutboxEntry(
    id: 'ATTENDANCE:c1|2026-06-15|y1',
    aggregateType: 'ATTENDANCE',
    aggregateId: 'c1|2026-06-15|y1',
    operation: OutboxOperation.upsert,
    payload: '{}',
    createdAt: 1,
  );

  Future<List<AttendanceRecordRow>> dayRecords() => dao.getDayRecords(
    classroomId: classroomId,
    dateStr: dateStr,
    academicYearId: yearId,
  );

  test('getSession : null tant qu\'aucun appel (appel non fait)', () async {
    final s = await dao.getSession(
      classroomId: classroomId,
      dateStr: dateStr,
      academicYearId: yearId,
    );
    expect(s, isNull);
  });

  test('confirm : crée la session + matérialise les seules absences', () async {
    await dao.confirmDailyAttendance(
      session: session(updatedAt: 100),
      absentRows: [absent('s1', updatedAt: 100)],
      outboxEntry: outbox(),
    );

    final s = await dao.getSession(
      classroomId: classroomId,
      dateStr: dateStr,
      academicYearId: yearId,
    );
    expect(s, isNotNull);
    expect(s!.updatedAt, 100);

    final rows = await dayRecords();
    expect(rows, hasLength(1));
    expect(rows.single.studentId, 's1');
    // Exception rattachée à la session (lien logique).
    expect(rows.single.sessionId, s.id);
  });

  test(
    'réconciliation par différence : l\'absent redevenu présent est supprimé',
    () async {
      await dao.confirmDailyAttendance(
        session: session(updatedAt: 100),
        absentRows: [
          absent('s1', updatedAt: 100),
          absent('s2', updatedAt: 100),
        ],
        outboxEntry: outbox(),
      );
      // 2e appel : s1 n'est plus absent → il sort des exceptions (DELETE).
      await dao.confirmDailyAttendance(
        session: session(updatedAt: 200),
        absentRows: [absent('s2', updatedAt: 200)],
        outboxEntry: outbox(),
      );

      final rows = await dayRecords();
      expect(rows.map((r) => r.studentId), ['s2']);
    },
  );

  test(
    'personne d\'absent : toutes les exceptions de la session sont purgées',
    () async {
      await dao.confirmDailyAttendance(
        session: session(updatedAt: 100),
        absentRows: [absent('s1', updatedAt: 100)],
        outboxEntry: outbox(),
      );
      await dao.confirmDailyAttendance(
        session: session(updatedAt: 200),
        absentRows: const [],
        outboxEntry: outbox(),
      );
      expect(await dayRecords(), isEmpty);
      // La session subsiste (appel fait, tous présents).
      expect(
        await dao.getSession(
          classroomId: classroomId,
          dateStr: dateStr,
          academicYearId: yearId,
        ),
        isNotNull,
      );
    },
  );

  test(
    'invariant #4 : re-confirmer bump session.updated_at (id local conservé)',
    () async {
      await dao.confirmDailyAttendance(
        session: session(updatedAt: 100),
        absentRows: [absent('s1', updatedAt: 100)],
        outboxEntry: outbox(),
      );
      final firstId = (await dao.getSession(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: yearId,
      ))!.id;

      await dao.confirmDailyAttendance(
        session: session(updatedAt: 300),
        absentRows: [absent('s1', updatedAt: 300)],
        outboxEntry: outbox(),
      );
      final s = await dao.getSession(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: yearId,
      );
      expect(s!.updatedAt, 300);
      // id = transport : l'id local est conservé malgré un nouvel id entrant.
      expect(s.id, firstId);
    },
  );

  test('LWW : une session locale plus récente conserve la main', () async {
    await dao.confirmDailyAttendance(
      session: session(updatedAt: 300),
      absentRows: [absent('s1', updatedAt: 300)],
      outboxEntry: outbox(),
    );
    // Écriture plus ANCIENNE : ne doit pas écraser.
    await dao.confirmDailyAttendance(
      session: session(updatedAt: 100),
      absentRows: const [],
      outboxEntry: outbox(),
    );
    final s = await dao.getSession(
      classroomId: classroomId,
      dateStr: dateStr,
      academicYearId: yearId,
    );
    expect(s!.updatedAt, 300);
    // Les exceptions ne sont pas réconciliées par une écriture périmée.
    expect(await dayRecords(), hasLength(1));
  });

  PulledAttendanceSession pulled({
    required String sessionId,
    required List<String> absentIds,
    int updatedAt = 500,
  }) => PulledAttendanceSession(
    session: AttendanceSessionRow(
      id: sessionId,
      classroomId: classroomId,
      attendanceDate: dateStr,
      academicYearId: yearId,
      expectedCount: 40,
      updatedAt: updatedAt,
      serverUpdatedAt: '2026-06-15T09:00:00.000Z',
      syncStatus: 'SYNCED',
      syncedAt: 9999,
    ),
    absences: absentIds
        .map(
          (sid) => AttendanceRecordRow(
            id: 'srv-$sid',
            studentId: sid,
            studentFirstName: 'F$sid',
            studentLastName: 'L$sid',
            studentGender: 'MALE',
            classroomId: classroomId,
            attendanceDate: dateStr,
            academicYearId: yearId,
            present: false,
            absenceReason: 'SICKNESS',
            updatedAt: updatedAt,
            syncStatus: 'SYNCED',
            syncedAt: 9999,
          ),
        )
        .toList(),
  );

  test(
    'applyPulledSessions : insère session serveur + expected_count',
    () async {
      final applied = await dao.applyPulledSessions([
        pulled(sessionId: 'srv-sess', absentIds: ['s1']),
      ], 9999);
      expect(applied, 1);
      final s = await dao.getSession(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: yearId,
      );
      expect(s!.expectedCount, 40);
      expect(s.syncStatus, 'SYNCED');
      expect((await dayRecords()).single.studentId, 's1');
    },
  );

  test(
    'applyPulledSessions : NE clobbère PAS une session locale PENDING',
    () async {
      // Appel local non synchronisé (PENDING).
      await dao.confirmDailyAttendance(
        session: session(updatedAt: 100),
        absentRows: [absent('s1', updatedAt: 100)],
        outboxEntry: outbox(),
      );
      // Le pull porte un état serveur pour la même clé naturelle.
      final applied = await dao.applyPulledSessions([
        pulled(sessionId: 'srv-sess', absentIds: ['s2']),
      ], 9999);
      expect(applied, 0); // sauté : l'écriture locale non synchronisée gagne
      final rows = await dayRecords();
      expect(rows.map((r) => r.studentId), ['s1']); // état local conservé
    },
  );

  test(
    'applyPulledSessions : session SYNCED préexistante → id local conservé',
    () async {
      await dao.confirmDailyAttendance(
        session: session(updatedAt: 100),
        absentRows: [absent('s1', updatedAt: 100)],
        outboxEntry: outbox(),
      );
      await dao.markDaySynced(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: yearId,
        syncedAt: 500,
      );
      final localId = (await dao.getSession(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: yearId,
      ))!.id;

      await dao.applyPulledSessions([
        pulled(sessionId: 'srv-different-id', absentIds: ['s2']),
      ], 9999);
      final s = await dao.getSession(
        classroomId: classroomId,
        dateStr: dateStr,
        academicYearId: yearId,
      );
      // id = transport : on garde l'id local, on adopte l'état serveur.
      expect(s!.id, localId);
      expect((await dayRecords()).map((r) => r.studentId), ['s2']);
    },
  );

  test('markDaySynced : session ET exceptions passent SYNCED', () async {
    await dao.confirmDailyAttendance(
      session: session(updatedAt: 100),
      absentRows: [absent('s1', updatedAt: 100)],
      outboxEntry: outbox(),
    );
    await dao.markDaySynced(
      classroomId: classroomId,
      dateStr: dateStr,
      academicYearId: yearId,
      syncedAt: 9999,
    );

    final s = await dao.getSession(
      classroomId: classroomId,
      dateStr: dateStr,
      academicYearId: yearId,
    );
    expect(s!.syncStatus, SyncState.synced.dbValue);
    expect(s.syncedAt, 9999);
    final rows = await dayRecords();
    expect(rows.single.syncStatus, SyncState.synced.dbValue);
  });
}
