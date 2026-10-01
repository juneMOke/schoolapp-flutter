import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_draft_mark_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';

/// Le brouillon de l'appel : les marques posées avant la validation, ou
/// depuis la réouverture d'un appel validé. Rien n'y part au serveur — c'est la
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

  /// Les jours d'une classe qui portent un brouillon, entre deux jours
  /// inclus.
  Future<Set<String>> daysWithMarks({
    required String classroomId,
    required String academicYearId,
    required String from,
    required String to,
  }) async {
    final rows = await _db.query(
      table,
      distinct: true,
      columns: ['attendance_date'],
      where:
          'classroom_id = ? AND academic_year_id = ? '
          'AND attendance_date BETWEEN ? AND ?',
      whereArgs: [classroomId, academicYearId, from, to],
    );
    return {for (final row in rows) row['attendance_date']! as String};
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

  /// Rouvre un appel validé : la session est marquée rouverte et le
  /// brouillon du jour repart vide — les élèves non touchés se lisent dans
  /// l'appel en base. Rien ne part avant la revalidation.
  Future<void> reopen({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
    required int reopenedAt,
  }) => _db.transaction((txn) async {
    await txn.delete(
      table,
      where: _dayWhere,
      whereArgs: [classroomId, dateStr, academicYearId],
    );
    await txn.update(
      AttendanceLocalDataSource.sessionsTable,
      {'reopened_at': reopenedAt},
      where: _dayWhere,
      whereArgs: [classroomId, dateStr, academicYearId],
    );
  });
}
