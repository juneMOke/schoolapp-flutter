import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';

/// L'horaire de l'école (début des cours, tolérance), lu dans
/// `ref_staff_attendance_settings` : une seule source pour le Pointage du
/// personnel et l'appel des élèves. Le socle le descend à tout compte ; seul
/// le droit de le **modifier** relève des RH.
class PresenceScheduleReader {
  final DatabaseExecutor _db;

  const PresenceScheduleReader(this._db);

  static const String table = 'ref_staff_attendance_settings';

  /// L'horaire de [schoolId] ; [PresenceSchedule.defaults] tant que rien
  /// n'est descendu.
  Future<PresenceSchedule> read(String? schoolId) async {
    if (schoolId == null) return PresenceSchedule.defaults;
    final rows = await _db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      limit: 1,
    );
    return rows.isEmpty
        ? PresenceSchedule.defaults
        : fromRow(rows.single) ?? PresenceSchedule.defaults;
  }

  /// L'horaire d'une ligne, ou `null` si elle est illisible.
  static PresenceSchedule? fromRow(Map<String, Object?> row) {
    final start = ClockTime.tryParse(row['start_time'] as String?);
    final tolerance = (row['tolerance_minutes'] as num?)?.toInt();
    if (start == null || tolerance == null) return null;
    return PresenceSchedule(start: start, toleranceMinutes: tolerance);
  }
}
