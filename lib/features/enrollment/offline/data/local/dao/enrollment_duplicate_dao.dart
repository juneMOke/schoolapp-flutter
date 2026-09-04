import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/known_student_identity.dart';

/// Corpus local de la **sonde de doublon d'inscription** : les identités que la
/// tablette connaît déjà, en deux sources.
///
/// DAO dédié plutôt qu'une méthode de plus sur `EnrollmentReadDao` : la sonde a
/// sa propre discipline de lecture — projection **au strict nécessaire** (trois
/// noms, une date, deux ids), aucune jointure de confort, aucun libellé de
/// niveau. Elle balaie tout le corpus une fois, là où les listes en paginent une
/// tranche enrichie.
///
/// **Aucun filtre de nom en SQL.** `LOWER()` SQLite ne plie pas les accents :
/// « Mukéndi » manquerait « Mukendi », et ici un faux négatif n'est pas une
/// gêne — c'est le doublon manqué. Le rapprochement se fait donc en Dart, sur
/// la projection entière (cf. `EnrollmentDuplicateMatcher`).
class EnrollmentDuplicateDao {
  final Database _db;

  const EnrollmentDuplicateDao(this._db);

  /// Identités portées par un dossier de l'année [academicYearId].
  ///
  /// **Aucun filtre `sync_status`** : un brouillon `DRAFT` saisi ce matin sur
  /// la même tablette est exactement le doublon qu'on cherche.
  ///
  /// **Aucun filtre `status` non plus** — un dossier `CANCELLED` reste un fait :
  /// l'enfant est dans la base. Le taire donnerait un silence que la donnée ne
  /// porte pas.
  ///
  /// `academic_year_id` porte **aussi le scope école** : une année appartient à
  /// une école (`ref_academic_years.school_id`). C'est la seule prise
  /// disponible — ni `students` ni `enrollments` n'ont de `school_id`.
  ///
  /// [excludedStudentId] et [excludedEnrollmentId] sont les ids du brouillon en
  /// cours : dès l'enregistrement de l'étape Identité, il porte sa propre ligne
  /// dans les deux tables. **Sans ces deux exclusions, la sonde se trouve
  /// elle-même**, à tous les coups. Ils sont requis et non nuls — un `null` en
  /// `whereArgs` lèverait chez sqflite, et une chaîne vide n'exclut simplement
  /// personne.
  Future<List<KnownStudentIdentity>> currentYearIdentities({
    required String academicYearId,
    required String excludedStudentId,
    required String excludedEnrollmentId,
  }) async {
    final rows = await _db.rawQuery(
      '''
      SELECT e.id AS enrollment_id, s.id AS student_id,
             s.first_name AS first_name, s.last_name AS last_name,
             s.surname AS surname, s.date_of_birth AS date_of_birth
      FROM enrollments e
      JOIN students s ON s.id = e.student_id
      WHERE e.academic_year_id = ?
        AND s.id <> ?
        AND e.id <> ?
      ORDER BY s.last_name, s.first_name
      ''',
      [academicYearId, excludedStudentId, excludedEnrollmentId],
    );

    return [
      for (final r in rows)
        KnownStudentIdentity(
          studentId: r['student_id'] as String,
          enrollmentId: r['enrollment_id'] as String,
          identity: _identity(r),
          source: EnrollmentDuplicateSource.currentYearDossier,
        ),
    ];
  }

  /// Identités de la **cohorte N-1** (`ref_previous_year_students`).
  ///
  /// Pas d'`enrollmentId` : le dossier de l'an dernier n'est pas dans
  /// `enrollments`, seule l'identité de l'élève est descendue.
  ///
  /// ⚠️ Cette table n'a **aucun axe école**. Sur une tablette partagée entre
  /// deux écoles, un candidat de l'autre école remonterait. C'est la dette déjà
  /// ouverte des curseurs non scopés, pas une régression de cette lecture — qui
  /// n'écrit rien.
  Future<List<KnownStudentIdentity>> previousYearCohortIdentities({
    required String excludedStudentId,
  }) async {
    final rows = await _db.rawQuery(
      '''
      SELECT student_id, first_name, last_name, surname, date_of_birth
      FROM ref_previous_year_students
      WHERE student_id <> ?
      ORDER BY last_name, first_name
      ''',
      [excludedStudentId],
    );

    return [
      for (final r in rows)
        KnownStudentIdentity(
          studentId: r['student_id'] as String,
          identity: _identity(r),
          source: EnrollmentDuplicateSource.previousYearCohort,
        ),
    ];
  }

  /// Les deux sources projettent les mêmes colonnes, sous les mêmes noms.
  /// `surname` est nullable des deux côtés — un dossier ancien peut ne pas
  /// porter de post-nom, là où l'étape Identité l'exige aujourd'hui.
  EnrollmentIdentity _identity(Map<String, Object?> r) => EnrollmentIdentity(
    lastName: r['last_name'] as String,
    firstName: r['first_name'] as String,
    surname: (r['surname'] as String?) ?? '',
    dateOfBirth: r['date_of_birth'] as String,
  );
}
