import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_record_row.dart';

/// Accès sqflite à `attendance_records` (AF-1/AF-3). Écriture par exception +
/// arbitrage last-write-wins sur `updated_at`. La matérialisation de l'appel et
/// l'enfilage dans l'outbox se font dans **une seule transaction** (atomicité
/// « appel confirmé »).
class AttendanceLocalDataSource {
  final Database _db;

  const AttendanceLocalDataSource(this._db);

  static const String table = 'attendance_records';

  /// Lignes matérialisées d'un jour (absents + retards corrigés). Un élève
  /// **sans ligne** = présent (dérivation côté repository).
  Future<List<AttendanceRecordRow>> getDayRecords({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      table,
      where:
          'classroom_id = ? AND attendance_date = ? AND academic_year_id = ?',
      whereArgs: [classroomId, dateStr, academicYearId],
    );
    return rows.map(AttendanceRecordRow.fromMap).toList(growable: false);
  }

  Future<AttendanceRecordRow?> _existingByKey(
    DatabaseExecutor txn, {
    required String studentId,
    required String dateStr,
    required String academicYearId,
  }) async {
    final rows = await txn.query(
      table,
      where: 'student_id = ? AND attendance_date = ? AND academic_year_id = ?',
      whereArgs: [studentId, dateStr, academicYearId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AttendanceRecordRow.fromMap(rows.first);
  }

  /// Confirme un appel (full-write) : applique l'état complet du roster en
  /// stockage par exception + LWW, puis enfile l'entrée d'outbox — atomiquement.
  ///
  /// - absent (present=false) → upsert d'une ligne present=0 (LWW).
  /// - présent (present=true) → efface l'exception si elle existait (retard
  ///   corrigé, LWW) ; sinon aucune ligne (présent = absence de ligne).
  Future<void> confirmDailyAttendance({
    required List<AttendanceRecordRow> rows,
    required OutboxEntry outboxEntry,
  }) async {
    await _db.transaction((txn) async {
      for (final row in rows) {
        final existing = await _existingByKey(
          txn,
          studentId: row.studentId,
          dateStr: row.attendanceDate,
          academicYearId: row.academicYearId,
        );

        if (!row.present) {
          if (existing == null) {
            await txn.insert(table, row.toMap());
          } else if (row.updatedAt >= existing.updatedAt) {
            await txn.update(
              table,
              row.toMap()..['id'] = existing.id,
              where: 'id = ?',
              whereArgs: [existing.id],
            );
          }
          // sinon : ligne locale plus récente → LWW conserve l'existant.
        } else {
          // Présent : on ne matérialise que la correction d'une absence connue.
          if (existing != null && row.updatedAt >= existing.updatedAt) {
            await txn.update(
              table,
              {
                'present': 1,
                'absence_reason': null,
                'absence_reason_note': null,
                'updated_at': row.updatedAt,
                'sync_status': SyncState.pendingSync.dbValue,
                'synced_at': null,
              },
              where: 'id = ?',
              whereArgs: [existing.id],
            );
          }
        }
      }

      // Coalescing : l'id déterministe de l'entrée fait qu'un ré-appel du même
      // jour REMPLACE l'entrée en attente (ConflictAlgorithm.replace).
      await OutboxDao(txn).enqueue(outboxEntry);
    });
  }

  /// Marque les lignes d'un jour comme synchronisées (après ACK serveur).
  Future<void> markDaySynced({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
    required int syncedAt,
  }) async {
    await _db.update(
      table,
      {'sync_status': SyncState.synced.dbValue, 'synced_at': syncedAt},
      where:
          'classroom_id = ? AND attendance_date = ? AND academic_year_id = ?',
      whereArgs: [classroomId, dateStr, academicYearId],
    );
  }

  /// Nombre d'absences locales d'un jour (present=0) — numérateur du taux AF-3.
  Future<int> countAbsences({
    required String classroomId,
    required String dateStr,
    required String academicYearId,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $table WHERE classroom_id = ? '
      'AND attendance_date = ? AND academic_year_id = ? AND present = 0',
      [classroomId, dateStr, academicYearId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }
}
