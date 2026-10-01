import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_local_model.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

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

  /// Les pointages de l'école encore **en file** sur les jours [from] →
  /// [to], mis en file au plus tard à [queuedBefore] : c'est ce qu'une
  /// validation ou une clôture doit laisser partir avant elle.
  ///
  /// ⚠️ Jamais ceux mis en file **après** le geste : « valider, rouvrir,
  /// corriger » ferait sinon attendre la validation derrière la correction,
  /// la correction derrière la réouverture, et la réouverture derrière la
  /// validation — un interblocage. L'heure de mise en file est celle de
  /// l'entrée d'outbox, que chaque retouche rajeunit.
  Future<List<StaffAttendanceLocalModel>> pendingIn(
    String schoolId, {
    required String from,
    required String to,
    required int queuedBefore,
  }) async {
    final rows = await _db.rawQuery(
      'SELECT r.* FROM $table r '
      'JOIN ${OutboxDao.table} o '
      "ON o.id = '${StaffAttendanceWriteDao.aggregateType}:' || r.id "
      'WHERE r.school_id = ? AND r.work_date >= ? AND r.work_date <= ? '
      'AND r.sync_status = ? AND o.status = ? AND o.created_at <= ?',
      [
        schoolId,
        from,
        to,
        RecordSyncState.pending.dbValue,
        OutboxStatus.pending.dbValue,
        queuedBefore,
      ],
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
            'sync_status': RecordSyncState.synced.dbValue,
            'updated_at': nowMs,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          continue;
        }
        final synced =
            existing.single['sync_status'] == RecordSyncState.synced.dbValue;
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
