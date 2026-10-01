import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_local_model.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_lww.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_dto.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_attendance_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Ce que l'accusé d'un pointage fait à la ligne locale.
///
/// Toutes les décisions se prennent sur **l'horloge envoyée** : un pointage
/// retouché sur la tablette pendant le vol porte une autre horloge, et
/// l'accusé ne doit ni écraser cette saisie ni la geler en erreur — elle
/// partira à son tour.
class StaffAttendanceSyncDao {
  final Database _db;

  const StaffAttendanceSyncDao(this._db);

  static const String table = StaffAttendanceLocalModel.table;

  /// Applique la ligne retenue par le serveur (`APPLIED` ou `SUPERSEDED`).
  Future<void> applyAck(
    StaffAttendanceDto canonical, {
    required String sentClientUpdatedAt,
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final rows = await txn.query(
      table,
      columns: ['client_updated_at'],
      where: 'id = ?',
      whereArgs: [canonical.id],
    );
    if (rows.isEmpty) {
      await txn.insert(table, {
        'id': canonical.id,
        'school_id': schoolId,
        ...StaffAttendanceLocalModel.contentColumns(canonical),
        ...StaffAttendanceLocalModel.serverColumns(canonical),
        'sync_status': RecordSyncState.synced.dbValue,
        'updated_at': nowMs,
      });
      return;
    }
    final latest = StaffLww.sameInstant(
      rows.single['client_updated_at'] as String?,
      sentClientUpdatedAt,
    );
    await txn.update(
      table,
      {
        ...StaffAttendanceLocalModel.serverColumns(canonical),
        if (latest) ...StaffAttendanceLocalModel.contentColumns(canonical),
        if (latest) 'sync_status': RecordSyncState.synced.dbValue,
        if (latest) 'sync_error': null,
        if (latest) 'sync_error_code': null,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [canonical.id],
    );
  });

  /// Marque le pointage « refusé » — sauf si une saisie plus récente l'a
  /// remplacé pendant le vol (rend alors `false` : l'entrée repart avec elle).
  Future<bool> markRejected(
    String id, {
    required String sentClientUpdatedAt,
    required String? code,
    required String reason,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final rows = await txn.query(
      table,
      columns: ['client_updated_at'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return true;
    if (!StaffLww.sameInstant(
      rows.single['client_updated_at'] as String?,
      sentClientUpdatedAt,
    )) {
      return false;
    }
    await txn.update(
      table,
      {
        'sync_status': RecordSyncState.failed.dbValue,
        'sync_error': reason,
        'sync_error_code': code,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return true;
  });

  /// Après la réouverture d'un jour, ses pointages refusés parce que le jour
  /// était validé repartent d'eux-mêmes. Rend combien.
  static Future<int> requeueDayLockedIn(
    DatabaseExecutor txn,
    String schoolId,
    String day, {
    required int nowMs,
  }) async {
    final rows = await txn.query(
      table,
      columns: ['id'],
      where:
          'school_id = ? AND work_date = ? AND sync_status = ? '
          'AND sync_error_code = ?',
      whereArgs: [
        schoolId,
        day,
        RecordSyncState.failed.dbValue,
        kStaffDayLockedCode,
      ],
    );
    final outbox = OutboxDao(txn);
    for (final row in rows) {
      final id = row['id']! as String;
      await txn.update(
        table,
        {
          'sync_status': RecordSyncState.pending.dbValue,
          'sync_error': null,
          'sync_error_code': null,
          'updated_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await outbox.requeue(StaffAttendanceWriteDao.entryId(id));
    }
    return rows.length;
  }
}
