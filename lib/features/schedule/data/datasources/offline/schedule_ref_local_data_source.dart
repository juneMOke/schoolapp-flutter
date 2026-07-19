import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_recurring_session_row.dart';
import 'package:school_app_flutter/features/schedule/data/models/offline/ref_time_slot_row.dart';

/// Accès sqflite aux tables de **référence** de l'emploi du temps
/// (`ref_time_slots`, `ref_recurring_sessions`). Read-only côté métier : ces
/// tables ne sont jamais écrites par une action utilisateur, uniquement peuplées
/// par le pull → l'application d'un delta est un simple upsert par uuid
/// (`ConflictAlgorithm.replace`), sans garde `PENDING_SYNC` (aucune écriture
/// locale à protéger).
class ScheduleRefLocalDataSource {
  final Database _db;

  const ScheduleRefLocalDataSource(this._db);

  static const String timeSlotsTable = 'ref_time_slots';
  static const String sessionsTable = 'ref_recurring_sessions';

  // ── Application du pull ─────────────────────────────────────────────────────

  Future<int> applyPulledTimeSlots(List<RefTimeSlotRow> rows) async {
    var applied = 0;
    await applyInBatches<RefTimeSlotRow>(
      _db,
      rows,
      apply: (txn, chunk) async {
        for (final row in chunk) {
          await txn.insert(
            timeSlotsTable,
            row.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          applied++;
        }
      },
    );
    return applied;
  }

  Future<int> applyPulledSessions(List<RefRecurringSessionRow> rows) async {
    var applied = 0;
    await applyInBatches<RefRecurringSessionRow>(
      _db,
      rows,
      apply: (txn, chunk) async {
        for (final row in chunk) {
          await txn.insert(
            sessionsTable,
            row.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          applied++;
        }
      },
    );
    return applied;
  }

  // ── Lectures (emploi du temps local) ────────────────────────────────────────

  /// Trame horaire de l'école, dans l'ordre métier d'affichage.
  Future<List<RefTimeSlotRow>> getTimeSlots() async {
    final rows = await _db.query(timeSlotsTable, orderBy: 'slot_order ASC');
    return rows.map(RefTimeSlotRow.fromMap).toList(growable: false);
  }

  /// Séances récurrentes d'une année (emploi du temps type).
  Future<List<RefRecurringSessionRow>> getSessionsForYear(
    String academicYearId,
  ) async {
    final rows = await _db.query(
      sessionsTable,
      where: 'academic_year_id = ?',
      whereArgs: [academicYearId],
    );
    return rows.map(RefRecurringSessionRow.fromMap).toList(growable: false);
  }
}
