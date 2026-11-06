import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Lecture des corrections de niveau posées sur ce poste.
class LevelCorrectionReadDao {
  final Database _db;

  const LevelCorrectionReadDao(this._db);

  static const String table = LevelCorrectionWriteDao.table;

  /// La dernière correction posée sur l'inscription, `null` s'il n'y en a pas.
  Future<LevelCorrection?> latestFor(String enrollmentId) async {
    final rows = await _db.query(
      table,
      where: 'enrollment_id = ?',
      whereArgs: [enrollmentId],
      orderBy: 'updated_at DESC, corrected_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : fromRow(rows.single);
  }

  static LevelCorrection fromRow(Map<String, Object?> row) => LevelCorrection(
    id: row['id']! as String,
    enrollmentId: row['enrollment_id']! as String,
    studentId: row['student_id']! as String,
    academicYearId: row['academic_year_id']! as String,
    fromSchoolLevelId: row['from_school_level_id']! as String,
    toSchoolLevelId: row['to_school_level_id']! as String,
    toSchoolLevelGroupId: row['to_school_level_group_id']! as String,
    toClassroomId: row['to_classroom_id'] as String?,
    reason: row['reason']! as String,
    correctedAt: row['corrected_at']! as String,
    status: _status(row['sync_status'] as String?),
    refusalCode: row['sync_error_code'] as String?,
  );

  static LevelCorrectionStatus _status(String? value) =>
      switch (RecordSyncState.fromDb(value)) {
        RecordSyncState.synced => LevelCorrectionStatus.applied,
        RecordSyncState.failed => LevelCorrectionStatus.refused,
        RecordSyncState.pending => LevelCorrectionStatus.pending,
      };
}
