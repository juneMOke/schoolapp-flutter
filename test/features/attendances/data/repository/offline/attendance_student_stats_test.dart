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
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_member_pull_repository_impl.dart';
import 'package:school_app_flutter/features/classes/data/repositories/offline/classroom_transfer_pull_repository_impl.dart';

import '../../../../../core/offline/offline_full_test_db.dart';

/// Statistiques d'assiduité par élève (AF-3, §5) : dénominateur = COUNT(sessions),
/// numérateur = absences ; gate bootstrapComplete (invariant #7) ; hebdo MON→SAT.
void main() {
  late Database db;
  late AttendanceLocalDataSource local;
  late ClassroomLocalDataSource roster;
  late SyncMetaDao syncMeta;
  late AttendanceOfflineRepositoryImpl repo;

  const classroomId = 'c1';
  const yearId = 'ay-1';

  setUp(() async {
    db = await openFullOfflineDb();
    local = AttendanceLocalDataSource(db);
    roster = ClassroomLocalDataSource(db);
    syncMeta = SyncMetaDao(db);
    repo = AttendanceOfflineRepositoryImpl(
      localDataSource: local,
      rosterDataSource: roster,
      syncMetaDao: syncMeta,
      idGenerator: const IdGenerator(Uuid()),
    );
  });

  tearDown(() async => db.close());

  /// Ligne `ref_classroom_members` : la classe courante de [studentId] est
  /// résolue par composition (CF3/CF4) depuis ce miroir. Marque aussi la
  /// ressource `classroom_members` synchronisée dans `sync_meta` (requis par
  /// le gate `bootstrapComplete` du chemin rapide, cf. repo impl).
  Future<void> seedMembership({
    required String studentId,
    String classroom = classroomId,
  }) async {
    await roster.upsertMembers(
      members: [
        ClassroomMemberDto(
          id: 'm-$studentId',
          studentId: studentId,
          classroomId: classroom,
          academicYearId: yearId,
          studentFirstName: 'F$studentId',
          studentLastName: 'L$studentId',
          studentGender: 'MALE',
          status: 'ACTIVE',
        ),
      ],
      syncedAt: 1,
    );
    await syncMeta.setCursor(
      kClassroomMembersResource,
      cursor: 'DONE',
      syncedAt: 1,
    );
  }

  /// Injecte une session (via le pull, marquée SYNCED) + ses absents.
  /// [reasons] permet de fixer un motif par élève absent (défaut : aucun).
  Future<void> seedSession(
    String date, {
    List<String> absents = const [],
    String classroom = classroomId,
    Map<String, String?> reasons = const {},
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
                absenceReason: reasons[sid],
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
      await seedMembership(studentId: 's1');
      await markBootstrapComplete();

      final res = (await repo.getStudentAttendanceStats(
        studentId: 's1',
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
    'détail des absences : motif + split justifiée/injustifiée/sans motif',
    () async {
      await seedSession(
        '2026-05-04',
        absents: ['s1'],
        reasons: {'s1': 'SICKNESS'},
      ); // justifiée
      await seedSession(
        '2026-05-05',
        absents: ['s1'],
        reasons: {'s1': 'UNJUSTIFIED'},
      ); // injustifiée
      await seedSession('2026-05-06', absents: ['s1']); // sans motif
      await seedMembership(studentId: 's1');
      await markBootstrapComplete();

      final res = (await repo.getStudentAttendanceStats(
        studentId: 's1',
        academicYearId: yearId,
        period: StatsPeriod.month,
        reference: DateTime(2026, 5, 15),
      )).getOrElse(() => throw StateError('left'));

      expect(res.absences, 3);
      // Sans motif = justifiée par défaut (même règle que forAbsenceReason,
      // cohérence avec le détail par ligne de PresenceAbsenceList).
      expect(res.unjustifiedAbsences, 1);
      expect(res.justifiedAbsences, 2);
      expect(res.entries, hasLength(3));
      // Trié par la couche appelante (le DAO renvoie déjà DESC) : le plus
      // récent (06) en tête.
      expect(res.entries.first.date, DateTime(2026, 5, 6));
    },
  );

  test(
    'gate : pas de bootstrap ⇒ available=false (chiffre non fiable)',
    () async {
      await seedSession('2026-05-04', absents: ['s1']);
      // bootstrap NON posé.

      final res = (await repo.getStudentAttendanceStats(
        studentId: 's1',
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
    await seedMembership(studentId: 's1');

    final res = (await repo.getStudentAttendanceStats(
      studentId: 's1',
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
      await seedMembership(studentId: 's1');

      final res = (await repo.getStudentAttendanceStats(
        studentId: 's1',
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
        academicYearId: yearId,
        period: StatsPeriod.month,
        reference: DateTime(2026, 5, 15),
      )).getOrElse(() => throw StateError('left'));

      // Sans intervalles, on aurait compté toutes les sessions de c2 (3) → faux
      // — et comme aucune ligne ref_classroom_members n'est seedée dans ce
      // test, le chemin rapide (getCurrentClassroomId) donnerait daysCalled=0
      // s'il était pris par erreur : cette assertion prouve donc aussi que le
      // bypass par intervalles a bien eu lieu, pas seulement par construction.
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
        academicYearId: yearId,
        period: StatsPeriod.month,
        reference: DateTime(2026, 5, 15),
      )).getOrElse(() => throw StateError('left'));

      expect(res.bootstrapComplete, isFalse);
      expect(res.available, isFalse);
    },
  );

  test('roster (ref_classroom_members) jamais synchronisé ⇒ available=false '
      'et daysCalled=0 (chemin rapide, classe courante inconnue)', () async {
    // Aucun seedMembership : le chemin rapide (pas de transfert) ne peut
    // pas résoudre de classe courante pour l'élève.
    await seedSession('2026-05-04', absents: ['s1']);
    await markBootstrapComplete(); // appels + transferts seulement.

    final res = (await repo.getStudentAttendanceStats(
      studentId: 's1',
      academicYearId: yearId,
      period: StatsPeriod.month,
      reference: DateTime(2026, 5, 15),
    )).getOrElse(() => throw StateError('left'));

    expect(res.daysCalled, 0);
    // Des absences peuvent déjà exister localement (pas scopées classe) —
    // elles ne doivent PAS se traduire par un faux « aucun jour scolaire » :
    // le gate bootstrapComplete doit rester fermé tant que le roster n'a
    // jamais synchronisé, précisément pour distinguer ce cas d'un élève
    // réellement jamais appelé.
    expect(res.bootstrapComplete, isFalse);
    expect(res.available, isFalse);
  });
}
