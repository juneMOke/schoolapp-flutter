import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart';

import '../../offline_full_db.dart';

/// Ré-ouverture d'un dossier **déjà finalisé** pour correction.
///
/// Les UPDATE d'étape sont gardés sur `sync_status = DRAFT` : sans cette
/// bascule, corriger un dossier complété écrirait zéro ligne, en silence. Elle
/// protège aussi la correction en cours — le pull saute toute ligne qui n'est
/// pas `SYNCED`, donc laisser le dossier `SYNCED` pendant l'édition exposerait
/// chaque champ corrigé à l'écrasement par la version serveur.
void main() {
  late Database db;
  late EnrollmentDraftDao draftDao;

  setUp(() async {
    db = await openFullOfflineDb();
    draftDao = EnrollmentDraftDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  StudentLocalModel student({String id = 's1'}) => StudentLocalModel(
    id: id,
    firstName: 'Amina',
    lastName: 'Moke',
    surname: 'Junior',
    gender: 'FEMALE',
    dateOfBirth: '2015-04-02',
    birthPlace: 'Kinshasa',
    nationality: 'CD',
    updatedAt: 100,
  );

  EnrollmentLocalModel enrollment({
    String id = 'e1',
    String studentId = 's1',
  }) => EnrollmentLocalModel(
    id: id,
    studentId: studentId,
    enrollmentType: 'NEW_ENROLLMENT',
    status: 'IN_PROGRESS',
    academicYearId: 'ay-2026',
    schoolLevelId: 'lvl-1',
    enrollmentDate: '2026-07-06',
    updatedAt: 100,
  );

  /// Pose un dossier dans l'état de synchro voulu, sans passer par le
  /// finalize (qui n'atteint que PENDING_SYNC) : c'est SYNCED, l'état d'un
  /// dossier revenu du serveur, qui nous intéresse.
  Future<void> seedFinalized(String syncStatus) async {
    await draftDao.insertDraftStudent(student());
    await draftDao.insertDraftEnrollment(enrollment());
    await db.update('students', {'sync_status': syncStatus});
    await db.update('enrollments', {'sync_status': syncStatus});
  }

  Future<String?> syncStatusOf(String table, String id) async {
    final rows = await db.query(
      table,
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.single['sync_status'] as String?;
  }

  Future<String?> cityOf(String id) async {
    final rows = await db.query(
      'students',
      columns: ['city'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.single['city'] as String?;
  }

  group('sans ré-ouverture', () {
    test(
      'corriger un dossier finalisé n\'écrit RIEN — le silence d\'avant',
      () async {
        await seedFinalized(SyncState.synced.dbValue);

        await draftDao.updateDraftStudentColumns('s1', {
          'city': 'Kinshasa',
        }, nowMs: 200);

        expect(await cityOf('s1'), isNull);
        expect(await syncStatusOf('students', 's1'), SyncState.synced.dbValue);
      },
    );
  });

  group('avec ré-ouverture', () {
    test('la correction passe, et le dossier bascule en brouillon', () async {
      await seedFinalized(SyncState.synced.dbValue);

      await draftDao.updateDraftStudentColumns(
        's1',
        {'city': 'Kinshasa'},
        nowMs: 200,
        reopenEnrollmentId: 'e1',
      );

      expect(await cityOf('s1'), 'Kinshasa');
      expect(await syncStatusOf('students', 's1'), SyncState.draft.dbValue);
      expect(await syncStatusOf('enrollments', 'e1'), SyncState.draft.dbValue);
    });

    test('un dossier en ERREUR de synchro est ré-ouvrable : il est finalisé, '
        'seul son envoi a échoué', () async {
      await seedFinalized(SyncState.syncError.dbValue);

      await draftDao.updateDraftEnrollmentColumns(
        'e1',
        {'previous_school_name': 'Saint-Joseph'},
        nowMs: 200,
        reopenEnrollmentId: 'e1',
      );

      expect(await syncStatusOf('enrollments', 'e1'), SyncState.draft.dbValue);
    });

    test('un dossier DÉJÀ dans la file d\'envoi n\'est pas ré-ouvert : sa '
        'commande est constituée', () async {
      await seedFinalized(SyncState.pendingSync.dbValue);

      await draftDao.updateDraftStudentColumns(
        's1',
        {'city': 'Kinshasa'},
        nowMs: 200,
        reopenEnrollmentId: 'e1',
      );

      expect(
        await syncStatusOf('enrollments', 'e1'),
        SyncState.pendingSync.dbValue,
      );
      expect(await cityOf('s1'), isNull, reason: 'rien n\'est écrit non plus');
    });

    test('idempotente : sur un brouillon, rien ne bouge', () async {
      await draftDao.insertDraftStudent(student());
      await draftDao.insertDraftEnrollment(enrollment());

      await draftDao.updateDraftStudentColumns(
        's1',
        {'city': 'Kinshasa'},
        nowMs: 200,
        reopenEnrollmentId: 'e1',
      );

      expect(await cityOf('s1'), 'Kinshasa');
      expect(await syncStatusOf('enrollments', 'e1'), SyncState.draft.dbValue);
    });

    test('l\'élève d\'un AUTRE dossier en cours de saisie n\'est pas '
        'ré-écrit', () async {
      await seedFinalized(SyncState.synced.dbValue);
      // Deuxième dossier du même élève, lui en cours de saisie.
      await draftDao.insertDraftEnrollment(
        enrollment(id: 'e2', studentId: 's1'),
      );
      await db.update('students', {'sync_status': SyncState.draft.dbValue});

      await draftDao.updateDraftStudentColumns(
        's1',
        {'city': 'Kinshasa'},
        nowMs: 200,
        reopenEnrollmentId: 'e1',
      );

      expect(await syncStatusOf('students', 's1'), SyncState.draft.dbValue);
      expect(await syncStatusOf('enrollments', 'e1'), SyncState.draft.dbValue);
      expect(await syncStatusOf('enrollments', 'e2'), SyncState.draft.dbValue);
    });
  });
}
