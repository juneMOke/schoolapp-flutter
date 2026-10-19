import 'package:school_app_flutter/features/student/data/models/student_identity_row.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// L'élève et sa classe de l'année, lus en une requête.
class StudentIdentityDao {
  final Database _db;

  const StudentIdentityDao(this._db);

  /// `null` quand l'élève n'est pas en base.
  ///
  /// L'inscription est jointe par `LEFT JOIN` : un élève sans inscription
  /// cette année garde son nom, sans classe. Plusieurs inscriptions (une
  /// annulée, celle qui vit) : la vivante d'abord, puis la plus récente, et
  /// `e.id` rend le tri strict — deux lectures donnent la même classe.
  Future<StudentIdentityRow?> find({
    required String studentId,
    required String academicYearId,
  }) async {
    final rows = await _db.rawQuery(
      '''
      SELECT s.id, s.first_name, s.last_name, s.surname, s.gender,
             sl.name AS level_name, slg.name AS level_group_name
      FROM students s
      LEFT JOIN enrollments e
        ON e.student_id = s.id AND e.academic_year_id = ?
      LEFT JOIN ref_school_levels sl ON sl.id = e.school_level_id
      LEFT JOIN ref_school_level_groups slg
        ON slg.id = COALESCE(e.school_level_group_id, sl.level_group_id)
      WHERE s.id = ?
      ORDER BY (e.status = 'CANCELLED') ASC, e.updated_at DESC, e.id ASC
      LIMIT 1
      ''',
      [academicYearId, studentId],
    );
    if (rows.isEmpty) return null;
    return StudentIdentityRow.fromMap(rows.first);
  }
}
