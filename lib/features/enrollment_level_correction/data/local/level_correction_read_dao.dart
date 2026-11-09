import 'package:school_app_flutter/core/database/projections/enrollment_level_correction_sql.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Lecture des corrections de niveau posées sur ce poste.
class LevelCorrectionReadDao {
  final Database _db;

  const LevelCorrectionReadDao(this._db);

  static const String table = LevelCorrectionWriteDao.table;

  /// La dernière correction posée sur l'inscription (par instant du geste),
  /// `null` s'il n'y en a pas — la même que lit la garde du guichet.
  Future<LevelCorrection?> latestFor(String enrollmentId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT c.*, ${EnrollmentLevelCorrectionSql.queued('c')} AS queued
      FROM $table c
      WHERE c.enrollment_id = ?
      ORDER BY c.corrected_at DESC, c.rowid DESC
      LIMIT 1
      ''',
      [enrollmentId],
    );
    return rows.isEmpty ? null : fromRow(rows.single);
  }

  /// Une correction de niveau retient-elle l'encaissement de l'élève (D7) ?
  /// Cf. [EnrollmentLevelCorrectionSql.holdsCollection].
  Future<bool> holdsCollection({
    required String studentId,
    required String academicYearId,
  }) => EnrollmentLevelCorrectionSql.holdsCollection(
    _db,
    studentId: studentId,
    academicYearId: academicYearId,
  );

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
    status: _status(row),
    refusalCode: row['sync_error_code'] as String?,
  );

  /// `queued` absent (ligne lue sans la jointure) : la ligne en attente est
  /// tenue pour en file.
  static LevelCorrectionStatus _status(Map<String, Object?> row) =>
      switch (RecordSyncState.fromDb(row['sync_status'] as String?)) {
        RecordSyncState.synced =>
          row['settled_at'] == null
              ? LevelCorrectionStatus.applied
              : LevelCorrectionStatus.settled,
        RecordSyncState.failed => LevelCorrectionStatus.refused,
        RecordSyncState.pending =>
          row['queued'] == 0
              ? LevelCorrectionStatus.stalled
              : LevelCorrectionStatus.pending,
      };
}
