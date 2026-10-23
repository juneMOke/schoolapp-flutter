import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sale_row.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Qui sont les élèves servis par une vente, et dans quelle classe de l'année.
///
/// Le delta des ventes ne porte que l'**identifiant** du bénéficiaire : une
/// vente faite à l'autre guichet descend sans nom. Le poste le retrouve dans ce
/// qu'il sait déjà — la fiche de l'élève, à défaut sa place dans une classe.
///
/// **Lecture seule, et jamais recopiée sur la vente** : le nom figé au guichet
/// reste prioritaire, et c'est l'appelant qui en décide.
class BoutiqueSaleBeneficiaryDao {
  final Database _db;

  const BoutiqueSaleBeneficiaryDao(this._db);

  /// Un [SaleBeneficiary] par élève connu du poste ; les inconnus sont absents
  /// de la table rendue, jamais présents avec un nom vide.
  Future<Map<String, SaleBeneficiary>> lookup({
    required String academicYearId,
    required List<String> studentIds,
  }) async {
    if (studentIds.isEmpty) return const {};
    final marks = List.filled(studentIds.length, '?').join(', ');

    final students = await _db.rawQuery(
      'SELECT id, last_name, surname, first_name FROM students '
      'WHERE id IN ($marks)',
      studentIds,
    );
    // La classe de l'ANNÉE de la vente. Une appartenance ACTIVE d'abord :
    // INACTIVE dit aussi « a quitté cette classe », et l'élève passé d'une
    // classe à l'autre en a deux.
    final members = await _db.rawQuery(
      'SELECT m.student_id, m.student_last_name, m.student_middle_name, '
      '       m.student_first_name, m.classroom_id, c.name AS classroom_name '
      'FROM ref_classroom_members m '
      'LEFT JOIN ref_classrooms c ON c.id = m.classroom_id '
      'WHERE m.academic_year_id = ? AND m.student_id IN ($marks) '
      "ORDER BY CASE m.status WHEN 'ACTIVE' THEN 0 ELSE 1 END",
      [academicYearId, ...studentIds],
    );

    final names = <String, String>{
      for (final row in students)
        row['id'] as String: _fullName(
          row['last_name'] as String?,
          row['surname'] as String?,
          row['first_name'] as String?,
        ),
    };
    final placements = <String, Map<String, Object?>>{};
    for (final row in members) {
      placements.putIfAbsent(row['student_id'] as String, () => row);
    }

    final found = <String, SaleBeneficiary>{};
    for (final id in studentIds) {
      final placement = placements[id];
      final name =
          _orNull(names[id]) ??
          (placement == null
              ? null
              : _orNull(
                  _fullName(
                    placement['student_last_name'] as String?,
                    placement['student_middle_name'] as String?,
                    placement['student_first_name'] as String?,
                  ),
                ));
      if (name == null && placement == null) continue;
      found[id] = SaleBeneficiary(
        studentId: id,
        fullName: name,
        classId: placement?['classroom_id'] as String?,
        classLabel: _orNull(placement?['classroom_name'] as String?),
      );
    }
    return found;
  }

  /// Nom, post-nom, prénom — l'ordre du sélecteur de bénéficiaire au guichet,
  /// pour que le nom résolu ne diffère pas de celui qu'on y aurait figé.
  static String _fullName(String? last, String? middle, String? first) => [
    last,
    middle,
    first,
  ].map((part) => part?.trim() ?? '').where((p) => p.isNotEmpty).join(' ');

  static String? _orNull(String? value) =>
      (value == null || value.trim().isEmpty) ? null : value.trim();
}
