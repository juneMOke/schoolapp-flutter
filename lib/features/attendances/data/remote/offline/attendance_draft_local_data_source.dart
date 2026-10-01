import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_draft_mark_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';

/// Le brouillon de l'appel : les marques posées avant la validation, et la
/// réouverture d'un appel validé. Rien n'y part au serveur — c'est la
/// validation qui transforme le brouillon en appel
/// (`AttendanceLocalDataSource.confirmDailyAttendance` le vide).
class AttendanceDraftLocalDataSource {
  final Database _db;

  const AttendanceDraftLocalDataSource(this._db);

  static const String table = AttendanceLocalDataSource.draftMarksTable;
  static const String _dayWhere =
      'classroom_id = ? AND attendance_date = ? AND academic_year_id = ?';

  Future<List<AttendanceDraftMarkRow>> marksOf({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      table,
      where: _dayWhere,
      whereArgs: [classroomId, dateStr, academicYearId],
    );
    return rows.map(AttendanceDraftMarkRow.fromMap).toList(growable: false);
  }

  /// Pose ou remplace des marques ; [removed] repasse des élèves « à
  /// pointer ». En une transaction : « restants présents » écrit la classe
  /// d'un bloc ou rien.
  Future<void> putMarks({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
    List<AttendanceDraftMarkRow> marks = const [],
    List<String> removed = const [],
  }) => _db.transaction((txn) async {
    for (final mark in marks) {
      await txn.insert(
        table,
        mark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (final studentId in removed) {
      await txn.delete(
        table,
        where: '$_dayWhere AND student_id = ?',
        whereArgs: [classroomId, dateStr, academicYearId, studentId],
      );
    }
  });

  /// Rouvre un appel validé : [marks] (la classe entière telle que validée)
  /// devient le brouillon, et la session est marquée rouverte. Rien ne part :
  /// c'est la revalidation qui renverra l'appel.
  Future<void> reopen({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
    required List<AttendanceDraftMarkRow> marks,
    required int reopenedAt,
  }) => _db.transaction((txn) async {
    await txn.delete(
      table,
      where: _dayWhere,
      whereArgs: [classroomId, dateStr, academicYearId],
    );
    for (final mark in marks) {
      await txn.insert(table, mark.toMap());
    }
    await txn.update(
      AttendanceLocalDataSource.sessionsTable,
      {'reopened_at': reopenedAt},
      where: _dayWhere,
      whereArgs: [classroomId, dateStr, academicYearId],
    );
  });
}
