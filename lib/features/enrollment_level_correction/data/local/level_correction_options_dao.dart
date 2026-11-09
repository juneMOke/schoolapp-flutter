import 'package:school_app_flutter/core/database/projections/enrollment_suspension_sql.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_options.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les classes qu'une correction peut viser, lues sur la tablette.
class LevelCorrectionOptionsDao {
  final Database _db;

  const LevelCorrectionOptionsDao(this._db);

  /// Les classes de l'année et la classe actuelle de l'élève — l'appartenance
  /// courante, transferts compris, celle que lit aussi la désactivation.
  ///
  /// Mais seulement si l'élève y **est** : appartenance `ACTIVE`. Une ligne
  /// `INACTIVE` — classe quittée, ou élève désactivé — dit qu'il n'est pas en
  /// classe, et la classe cible ne lui est pas imposée (D3). Le back l'a
  /// tranché le 2026-11-08 : un élève désactivé ne compte pas comme en classe.
  Future<LevelCorrectionClassrooms> classrooms({
    required String studentId,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      'ref_classrooms',
      columns: ['id', 'name', 'school_level_id'],
      where: 'academic_year_id = ?',
      whereArgs: [academicYearId],
      orderBy: 'name COLLATE NOCASE, id',
    );
    final current = await _db.rawQuery(
      'SELECT cm.classroom_id AS classroom_id '
      'FROM ${EnrollmentSuspensionSql.membersTable} cm '
      'WHERE cm.id = '
      '${EnrollmentSuspensionSql.currentMemberId('?', '?')} '
      "AND cm.status = 'ACTIVE'",
      [studentId, academicYearId],
    );
    return LevelCorrectionClassrooms(
      classrooms: [
        for (final r in rows)
          ClassroomOption(
            id: r['id']! as String,
            name: r['name']! as String,
            schoolLevelId: r['school_level_id'] as String?,
          ),
      ],
      currentClassroomId: current.isEmpty
          ? null
          : current.first['classroom_id'] as String?,
    );
  }
}
