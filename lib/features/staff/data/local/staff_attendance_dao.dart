import 'package:school_app_flutter/features/staff/data/local/staff_attendance_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Lecture de `staff_attendance_records`, et application du flux descendu.
class StaffAttendanceDao {
  final Database _db;

  const StaffAttendanceDao(this._db);

  static const String table = StaffAttendanceLocalModel.table;

  /// Les pointages de l'école du jour [from] au jour [to] inclus.
  Future<List<StaffAttendanceLocalModel>> forRange(
    String schoolId, {
    required String from,
    required String to,
  }) async {
    if (schoolId.isEmpty) return const [];
    final rows = await _db.query(
      table,
      where: 'school_id = ? AND work_date >= ? AND work_date <= ?',
      whereArgs: [schoolId, from, to],
    );
    return rows.map(StaffAttendanceLocalModel.new).toList(growable: false);
  }

  Future<StaffAttendanceLocalModel?> find(String id) async {
    final rows = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : StaffAttendanceLocalModel(rows.single);
  }

  /// Les pointages de l'école encore **en attente d'envoi** sur les jours
  /// [from] → [to] : c'est ce qu'une validation ou une clôture doit laisser
  /// partir avant elle.
  Future<List<StaffAttendanceLocalModel>> pendingIn(
    String schoolId, {
    required String from,
    required String to,
  }) async {
    final rows = await _db.query(
      table,
      where:
          'school_id = ? AND work_date >= ? AND work_date <= ? '
          'AND sync_status = ?',
      whereArgs: [schoolId, from, to, StaffSyncState.pending.dbValue],
    );
    return rows.map(StaffAttendanceLocalModel.new).toList(growable: false);
  }

  /// Applique une page descendue. Rend le nombre de lignes écrites.
  ///
  /// Un pointage portant une saisie locale **pas encore remontée** ne prend
  /// que la version du serveur : son contenu attend l'accusé de sa propre
  /// remontée, qui tranchera au dernier écrit.
  Future<int> applyPulled(
    List<StaffAttendanceDto> deltas, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (deltas.isEmpty || schoolId.isEmpty) return 0;
    await _db.transaction((txn) async {
      for (final delta in deltas) {
        final existing = await txn.query(
          table,
          columns: ['sync_status'],
          where: 'id = ?',
          whereArgs: [delta.id],
        );
        if (existing.isEmpty) {
          await txn.insert(table, {
            'id': delta.id,
            'school_id': schoolId,
            ...StaffAttendanceLocalModel.contentColumns(delta),
            ...StaffAttendanceLocalModel.serverColumns(delta),
            'sync_status': StaffSyncState.synced.dbValue,
            'updated_at': nowMs,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          continue;
        }
        final synced =
            existing.single['sync_status'] == StaffSyncState.synced.dbValue;
        await txn.update(
          table,
          {
            ...StaffAttendanceLocalModel.serverColumns(delta),
            if (synced) ...StaffAttendanceLocalModel.contentColumns(delta),
            'updated_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [delta.id],
        );
      }
    });
    return deltas.length;
  }
}
