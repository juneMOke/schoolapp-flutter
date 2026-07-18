import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/entities/stats_period.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_pull_models.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/attendances/data/repository/offline/attendance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/datasources/offline/classroom_local_data_source.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

/// Statistiques d'assiduité par élève (AF-3, §5) : dénominateur = COUNT(sessions),
/// numérateur = absences ; gate bootstrapComplete (invariant #7) ; hebdo MON→SAT.
void main() {
  late Database db;
  late AttendanceLocalDataSource local;
  late SyncMetaDao syncMeta;
  late AttendanceOfflineRepositoryImpl repo;

  const classroomId = 'c1';
  const yearId = 'ay-1';

  setUp(() async {
    db = await openFullOfflineDb();
    local = AttendanceLocalDataSource(db);
    syncMeta = SyncMetaDao(db);
    repo = AttendanceOfflineRepositoryImpl(
      localDataSource: local,
      rosterDataSource: ClassroomLocalDataSource(db),
      syncMetaDao: syncMeta,
      idGenerator: const IdGenerator(Uuid()),
    );
  });

  tearDown(() async => db.close());

  /// Injecte une session (via le pull, marquée SYNCED) + ses absents.
  Future<void> seedSession(
    String date, {
    List<String> absents = const [],
    String classroom = classroomId,
  }) async {
    await local.applyPulledSessions([
      AttendanceSessionDeltaDto(
        id: 'srv-$classroom-$date',
        classroomId: classroom,
        attendanceDate: date,
        academicYearId: yearId,
        updatedAt: '${date}T08:00:00.000Z',
        absences: absents
            .map(
              (sid) => AbsenceDeltaDto(
                id: 'a-$classroom-$date-$sid',
                studentId: sid,
                updatedAt: '${date}T08:00:00.000Z',
              ),
            )
            .toList(),
      ).toPulled(1000),
    ], 1000);
  }

  /// Pose les deux drapeaux bootstrapComplete (appels + transferts) requis pour
  /// un chiffre fiable (F6).
  Future<void> markBootstrapComplete() async {
    await syncMeta.setCursor(
      AttendancePullRepositoryImpl.bootstrapResource,
      cursor: 'DONE',
      syncedAt: 5,
    );
    await syncMeta.setCursor(
      ClassroomTransferPullRepositoryImpl.bootstrapResource,
      cursor: 'DONE',
      syncedAt: 5,
    );
  }

  /// Insère un transfert SYNCED (borne d'intervalle d'appartenance).
  Future<void> seedTransfer({
    required String studentId,
    required String from,
    required String to,
    required DateTime at,
  }) async {
    await db.insert('classroom_transfers', {
      'id': 't-$studentId-${at.millisecondsSinceEpoch}',
      'student_id': studentId,
      'from_classroom_id': from,
      'to_classroom_id': to,
      'school_level_id': 'lvl',
      'academic_year_id': yearId,
      'transferred_at': at.millisecondsSinceEpoch,
      'sync_status': 'SYNCED',
    });
  }

  test(
    'mensuel : joursAppeles = COUNT(sessions), absences = COUNT(records)',
    () async {
      // Mai 2026 : 3 appels, l'élève s1 absent 1 fois.
      await seedSession('2026-05-04', absents: ['s1']);
      await seedSession('2026-05-05');
      await seedSession('2026-05-06', absents: ['s2']);
      // Un appel hors période (juin) ne doit pas compter.
      await seedSession('2026-06-01', absents: ['s1']);
      await markBootstrapComplete();

      final res = (await repo.getStudentAttendanceStats(
        studentId: 's1',
        classroomId: classroomId,
        academicYearId: yearId,
        period: StatsPeriod.month,
        reference: DateTime(2026, 5, 15),
      )).getOrElse(() => throw StateError('left'));

      expect(res.daysCalled, 3); // mai seulement
      expect(res.absences, 1); // s1 absent le 4 mai
      expect(res.present, 2);
      expect(res.rate, closeTo(2 / 3, 0.0001));
      expect(res.available, isTrue);
    },
  );

  test(
    'gate : pas de bootstrap ⇒ available=false (chiffre non fiable)',
    () async {
      await seedSession('2026-05-04', absents: ['s1']);
      // bootstrap NON posé.

      final res = (await repo.getStudentAttendanceStats(
        studentId: 's1',
        classroomId: classroomId,
        academicYearId: yearId,
        period: StatsPeriod.month,
        reference: DateTime(2026, 5, 15),
      )).getOrElse(() => throw StateError('left'));

      expect(res.available, isFalse);
      expect(res.bootstrapComplete, isFalse);
    },
  );

  test('hebdo lundi→samedi : le dimanche précédent est exclu', () async {
    // 2026-05-04 = lundi ; 2026-05-09 = samedi ; 2026-05-03 = dimanche (exclu).
    await seedSession('2026-05-03'); // dimanche précédent
    await seedSession('2026-05-04'); // lundi
    await seedSession('2026-05-09'); // samedi
    await seedSession('2026-05-10'); // dimanche suivant (exclu)

    final res = (await repo.getStudentAttendanceStats(
      studentId: 's1',
      classroomId: classroomId,
      academicYearId: yearId,
      period: StatsPeriod.week,
      reference: DateTime(2026, 5, 6), // un mercredi de la semaine
    )).getOrElse(() => throw StateError('left'));

    expect(res.daysCalled, 2); // lundi + samedi
  });

  test(
    'annuel : toutes les sessions de l\'année (pas de borne de date)',
    () async {
      await seedSession('2026-05-04');
      await seedSession('2026-11-20');
      await seedSession('2027-01-15');

      final res = (await repo.getStudentAttendanceStats(
        studentId: 's1',
        classroomId: classroomId,
        academicYearId: yearId,
        period: StatsPeriod.year,
        reference: DateTime(2026, 5, 15),
      )).getOrElse(() => throw StateError('left'));

      expect(res.daysCalled, 3);
      expect(res.from, isNull);
      expect(res.to, isNull);
    },
  );

  test(
    'élève transféré c1→c2 : dénominateur = sessions de c1 avant + c2 après',
    () async {
      // Avant le transfert (05-05), s1 est dans c1 ; après, dans c2.
      await seedSession('2026-05-02', classroom: 'c1'); // c1, compte
      await seedSession('2026-05-03', classroom: 'c1'); // c1, compte
      await seedSession('2026-05-08', classroom: 'c1'); // c1 APRÈS → exclu
      await seedSession('2026-05-01', classroom: 'c2'); // c2 AVANT → exclu
      await seedSession(
        '2026-05-06',
        classroom: 'c2',
        absents: ['s1'],
      ); // c2, compte
      await seedSession('2026-05-07', classroom: 'c2'); // c2, compte
      await seedTransfer(
        studentId: 's1',
        from: 'c1',
        to: 'c2',
        at: DateTime(2026, 5, 5),
      );
      await markBootstrapComplete();

      final res = (await repo.getStudentAttendanceStats(
        studentId: 's1',
        classroomId: 'c2', // classe courante
        academicYearId: yearId,
        period: StatsPeriod.month,
        reference: DateTime(2026, 5, 15),
      )).getOrElse(() => throw StateError('left'));

      // Sans intervalles, on aurait compté toutes les sessions de c2 (3) → faux.
      expect(res.daysCalled, 4); // c1: 05-02,05-03 + c2: 05-06,05-07
      expect(res.absences, 1); // s1 absent le 06 (dans c2)
      expect(res.available, isTrue);
    },
  );

  test(
    'transferts non bootstrappés ⇒ available=false même si appels OK',
    () async {
      await seedSession('2026-05-04', absents: ['s1']);
      // Seul le bootstrap des APPELS est posé, pas celui des transferts.
      await syncMeta.setCursor(
        AttendancePullRepositoryImpl.bootstrapResource,
        cursor: 'DONE',
        syncedAt: 5,
      );

      final res = (await repo.getStudentAttendanceStats(
        studentId: 's1',
        classroomId: classroomId,
        academicYearId: yearId,
        period: StatsPeriod.month,
        reference: DateTime(2026, 5, 15),
      )).getOrElse(() => throw StateError('left'));

      expect(res.bootstrapComplete, isFalse);
      expect(res.available, isFalse);
    },
  );
}
