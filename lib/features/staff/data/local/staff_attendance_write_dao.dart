import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_attendance_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_attendance_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Écritures locales des pointages — **toujours avec leur entrée d'outbox,
/// dans la même transaction**.
///
/// L'identifiant d'entrée est **déterministe** (`STAFF_ATTENDANCE:<id>`) :
/// modifier un pointage encore en file remplace son entrée par l'état final.
/// La file garde au plus un envoi par agent et par jour.
class StaffAttendanceWriteDao {
  final Database _db;

  const StaffAttendanceWriteDao(this._db);

  static const String table = StaffAttendanceLocalModel.table;
  static const String aggregateType = 'STAFF_ATTENDANCE';

  static String entryId(String recordId) => '$aggregateType:$recordId';

  /// Enregistre les pointages et les met en file, tous ou aucun.
  Future<void> save(
    List<StaffAttendanceSyncRequestDto> requests, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final outbox = OutboxDao(txn);
    for (final request in requests) {
      final record = request.staffAttendance;
      final content = {
        ...StaffAttendanceLocalModel.contentColumns(record),
        'sync_status': RecordSyncState.pending.dbValue,
        'sync_error': null,
        'sync_error_code': null,
        'updated_at': nowMs,
      };
      final updated = await txn.update(
        table,
        content,
        where: 'id = ?',
        whereArgs: [record.id],
      );
      if (updated == 0) {
        await txn.insert(table, {
          'id': record.id,
          'school_id': schoolId,
          ...content,
        });
      }
      await outbox.enqueue(
        OutboxEntry(
          id: entryId(record.id),
          aggregateType: aggregateType,
          aggregateId: record.staffMemberId,
          operation: OutboxOperation.upsert,
          payload: jsonEncode(request.toJson()),
          schoolId: schoolId,
          createdAt: nowMs,
        ),
      );
    }
  });
}
