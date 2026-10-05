import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_local_model.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_push_request.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Écriture d'un geste sur la photo d'un élève — **toujours avec son entrée
/// d'outbox, dans la même transaction**.
///
/// Une seule entrée par élève (`STUDENT_PHOTO:<élève>`) : un nouveau geste
/// remplace le précédent encore en file, puisque seule la dernière photo
/// compte. La garde `created_at` du moteur empêche l'accusé d'un envoi en vol
/// d'acquitter le geste qui l'a remplacé.
class StudentPhotoWriteDao {
  final Database _db;

  const StudentPhotoWriteDao(this._db);

  static const String table = StudentPhotoLocalModel.table;
  static const String aggregateType = 'STUDENT_PHOTO';

  static String entryId(String studentId) => '$aggregateType:$studentId';

  /// Pose [request] et rend la ligne d'avant, pour que l'appelant libère les
  /// octets du geste remplacé.
  Future<StudentPhotoLocalModel?> record(
    StudentPhotoPushRequest request, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final before = await txn.query(
      table,
      where: 'student_id = ?',
      whereArgs: [request.studentId],
      limit: 1,
    );
    await txn.insert(table, {
      'student_id': request.studentId,
      'school_id': schoolId,
      'updated_at': nowMs,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await txn.update(
      table,
      {
        'pending_op': request.op.wire,
        'pending_sha256': request.sha256,
        'pending_at': request.at,
        'sync_status': RecordSyncState.pending.dbValue,
        'sync_error': null,
        'sync_error_code': null,
        'updated_at': nowMs,
      },
      where: 'student_id = ?',
      whereArgs: [request.studentId],
    );
    await OutboxDao(txn).enqueue(
      OutboxEntry(
        id: entryId(request.studentId),
        aggregateType: aggregateType,
        aggregateId: request.studentId,
        operation: OutboxOperation.upsert,
        payload: jsonEncode(request.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      ),
    );
    return before.isEmpty ? null : StudentPhotoLocalModel(before.single);
  });
}
