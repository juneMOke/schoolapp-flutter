import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';

import '../../offline_full_db.dart';

/// Insère un élève directement en SQL : ces tests portent sur la LECTURE de la
/// garde, ils ne doivent pas dépendre du chemin d'écriture d'un dossier.
Future<void> _insertStudent(
  Database db, {
  required String id,
  required String syncStatus,
}) {
  return db.insert('students', <String, Object?>{
    'id': id,
    'first_name': 'Amina',
    'last_name': 'Mbala',
    'gender': 'FEMALE',
    'date_of_birth': '2014-03-02',
    'sync_status': syncStatus,
    'updated_at': 0,
  });
}

Future<void> _insertCohortStudent(Database db, {required String studentId}) {
  return db.insert('ref_previous_year_students', <String, Object?>{
    'student_id': studentId,
    'matriculation_number': 'MAT-0042',
    'first_name': 'Amina',
    'last_name': 'Mbala',
    'gender': 'FEMALE',
    'date_of_birth': '2014-03-02',
  });
}

void main() {
  late Database db;
  late EnrollmentReadDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = EnrollmentReadDao(db);
  });

  tearDown(() async => db.close());

  group('isStudentKnownToServer', () {
    test('vrai quand la ligne students est passée SYNCED', () async {
      await _insertStudent(db, id: 'stu-synced', syncStatus: 'SYNCED');

      expect(await dao.isStudentKnownToServer('stu-synced'), isTrue);
    });

    // Le cas qui motive toute la garde : un élève saisi hors ligne porte un uuid
    // client que le serveur n'a pas encore honoré. Émettre un relevé sur cet id
    // produit un 404.
    test('faux quand l élève est encore en attente de synchro', () async {
      await _insertStudent(db, id: 'stu-pending', syncStatus: 'PENDING_SYNC');

      expect(await dao.isStudentKnownToServer('stu-pending'), isFalse);
    });

    test('faux quand le push de l élève a été rejeté', () async {
      await _insertStudent(db, id: 'stu-error', syncStatus: 'SYNC_ERROR');

      expect(await dao.isStudentKnownToServer('stu-error'), isFalse);
    });

    test('faux quand l élève est un brouillon', () async {
      await _insertStudent(db, id: 'stu-draft', syncStatus: 'DRAFT');

      expect(await dao.isStudentKnownToServer('stu-draft'), isFalse);
    });

    // Sans ce second test, tout candidat de réinscription serait bloqué à tort :
    // son dossier N est encore PENDING, mais son student_id est l'id CANONIQUE
    // repris de la cohorte N-1 — le serveur le connaît déjà.
    test(
      'vrai pour un candidat de cohorte N-1 dont le dossier N est en attente',
      () async {
        await _insertStudent(db, id: 'stu-re', syncStatus: 'PENDING_SYNC');
        await _insertCohortStudent(db, studentId: 'stu-re');

        expect(await dao.isStudentKnownToServer('stu-re'), isTrue);
      },
    );

    test('vrai pour un élève de cohorte sans aucune ligne students', () async {
      await _insertCohortStudent(db, studentId: 'stu-cohort-only');

      expect(await dao.isStudentKnownToServer('stu-cohort-only'), isTrue);
    });

    // Fail-closed : un identifiant qu'on ne sait rattacher à rien vaut « non ».
    test('faux quand l élève est introuvable', () async {
      expect(await dao.isStudentKnownToServer('stu-inconnu'), isFalse);
    });
  });
}
