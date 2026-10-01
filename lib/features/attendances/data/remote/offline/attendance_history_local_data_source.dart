import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_session_row.dart';
import 'package:school_app_flutter/features/attendances/data/remote/offline/attendance_local_data_source.dart';

/// Lecture de l'historique de l'appel : jours appelés, absences d'un élève,
/// mois d'une classe. Rien n'y écrit — l'écriture d'un appel est l'affaire de
/// [AttendanceLocalDataSource].
///
/// ⚠️ Depuis la v2, une ligne d'appel est une absence **ou un retard** : toute
/// requête qui compte des absences filtre `present = 0`.
class AttendanceHistoryLocalDataSource {
  final Database _db;

  const AttendanceHistoryLocalDataSource(this._db);

  static const String sessionsTable = AttendanceLocalDataSource.sessionsTable;
  static const String recordsTable = AttendanceLocalDataSource.recordsTable;

  /// Nombre d'absences locales d'un jour (present=0) — numérateur du taux AF-3.
  Future<int> countAbsences({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $recordsTable WHERE classroom_id = ? '
      'AND attendance_date = ? AND academic_year_id = ? AND present = 0',
      [classroomId, dateStr, academicYearId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// **Jours appelés** d'une classe sur une période (dénominateur des stats
  /// AF-3, §5) : nombre de sessions. [fromStr]/[toStr] nuls = année entière
  /// (les sessions sont déjà cadrées par `academic_year_id`).
  Future<int> countSessions({
    required String classroomId,
    required String academicYearId,
    String? fromStr,
    String? toStr,
  }) async {
    final where = StringBuffer('classroom_id = ? AND academic_year_id = ?');
    final args = <Object?>[classroomId, academicYearId];
    if (fromStr != null && toStr != null) {
      where.write(' AND attendance_date BETWEEN ? AND ?');
      args
        ..add(fromStr)
        ..add(toStr);
    }
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $sessionsTable WHERE $where',
      args,
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// **Jours appelés** d'une classe sur un intervalle à bornes **indépendantes**
  /// (F6, intervalles d'appartenance) : chaque borne inclusive s'applique seule
  /// (≠ [countSessions] qui exige les deux). `null` = borne ouverte de ce côté.
  Future<int> countSessionsBetween({
    required String classroomId,
    required String academicYearId,
    String? fromInclusive,
    String? toInclusive,
  }) async {
    final where = StringBuffer('classroom_id = ? AND academic_year_id = ?');
    final args = <Object?>[classroomId, academicYearId];
    if (fromInclusive != null) {
      where.write(' AND attendance_date >= ?');
      args.add(fromInclusive);
    }
    if (toInclusive != null) {
      where.write(' AND attendance_date <= ?');
      args.add(toInclusive);
    }
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $sessionsTable WHERE $where',
      args,
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  /// **Absences d'un élève** sur une période, détail complet (numérateur +
  /// motif/note des stats AF-3 §5), triées du plus récent au plus ancien.
  /// [fromStr]/[toStr] nuls = année entière.
  Future<List<AttendanceRecordRow>> getStudentAbsenceRecords({
    required String studentId,
    required String academicYearId,
    String? fromStr,
    String? toStr,
  }) async {
    final where = StringBuffer(
      'student_id = ? AND academic_year_id = ? AND present = 0',
    );
    final args = <Object?>[studentId, academicYearId];
    if (fromStr != null && toStr != null) {
      where.write(' AND attendance_date BETWEEN ? AND ?');
      args
        ..add(fromStr)
        ..add(toStr);
    }
    final rows = await _db.query(
      recordsTable,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'attendance_date DESC',
    );
    return rows.map(AttendanceRecordRow.fromMap).toList(growable: false);
  }

  /// Les sessions d'une classe entre deux jours inclus (`YYYY-MM-DD`).
  Future<List<AttendanceSessionRow>> sessionsBetween({
    required String classroomId,
    required String academicYearId,
    required String from,
    required String to,
  }) async {
    final rows = await _db.query(
      sessionsTable,
      where:
          'classroom_id = ? AND academic_year_id = ? '
          'AND attendance_date BETWEEN ? AND ?',
      whereArgs: [classroomId, academicYearId, from, to],
    );
    return rows.map(AttendanceSessionRow.fromMap).toList(growable: false);
  }

  /// Les exceptions (retards et absences) d'une classe entre deux jours
  /// inclus.
  Future<List<AttendanceRecordRow>> recordsBetween({
    required String classroomId,
    required String academicYearId,
    required String from,
    required String to,
  }) async {
    final rows = await _db.query(
      recordsTable,
      where:
          'classroom_id = ? AND academic_year_id = ? '
          'AND attendance_date BETWEEN ? AND ?',
      whereArgs: [classroomId, academicYearId, from, to],
    );
    return rows.map(AttendanceRecordRow.fromMap).toList(growable: false);
  }

  /// Les retards d'un élève sur une période (`null` = année entière), du plus
  /// récent au plus ancien.
  Future<List<AttendanceRecordRow>> getStudentLateRecords({
    required String studentId,
    required String academicYearId,
    String? fromStr,
    String? toStr,
  }) async {
    final where = StringBuffer(
      "student_id = ? AND academic_year_id = ? AND status = 'LATE'",
    );
    final args = <Object?>[studentId, academicYearId];
    if (fromStr != null && toStr != null) {
      where.write(' AND attendance_date BETWEEN ? AND ?');
      args
        ..add(fromStr)
        ..add(toStr);
    }
    final rows = await _db.query(
      recordsTable,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'attendance_date DESC',
    );
    return rows.map(AttendanceRecordRow.fromMap).toList(growable: false);
  }
}
