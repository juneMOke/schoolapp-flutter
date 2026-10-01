import 'package:sqflite_common/sqlite_api.dart';

/// Les clôtures de mois de l'appel, par classe (`attendance_month_closures`).
class AttendanceClosureLocalDataSource {
  final Database _db;

  const AttendanceClosureLocalDataSource(this._db);

  static const String table = 'attendance_month_closures';

  /// Le mois `YYYY-MM` de la classe est-il clos — ou en passe de l'être sur
  /// cette tablette ? Une clôture saisie fige le mois dès la saisie ; une
  /// clôture refusée par le serveur ne fige rien.
  Future<bool> isClosed({
    required String classroomId,
    required String academicYearId,
    required String month,
  }) async {
    final rows = await _db.query(
      table,
      columns: ['1'],
      where:
          'classroom_id = ? AND academic_year_id = ? AND month = ? '
          "AND sync_status <> 'SYNC_ERROR'",
      whereArgs: [classroomId, academicYearId, month],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
