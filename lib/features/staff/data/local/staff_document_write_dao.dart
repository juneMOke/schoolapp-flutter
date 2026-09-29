import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_push_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Écriture locale d'une pièce — **toujours avec son entrée d'outbox, dans la
/// même transaction**. Les octets, eux, sont déjà scellés dans le magasin : la
/// ligne ne naît que si la pièce existe.
///
/// Une pièce est un fait figé : « remplacer » en verse une nouvelle, son
/// entrée à elle (`STAFF_DOCUMENT:<pièce>`).
class StaffDocumentWriteDao {
  final Database _db;

  const StaffDocumentWriteDao(this._db);

  static const String table = StaffDocumentLocalModel.table;
  static const String aggregateType = 'STAFF_DOCUMENT';

  static String entryId(String documentId) => '$aggregateType:$documentId';

  Future<void> add({
    required StaffDocumentUploadDto request,
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await txn.insert(
      table,
      StaffDocumentLocalModel.pendingColumns(
        request,
        schoolId: schoolId,
        nowMs: nowMs,
      ),
    );
    await OutboxDao(txn).enqueue(
      OutboxEntry(
        id: entryId(request.id),
        aggregateType: aggregateType,
        aggregateId: request.staffMemberId,
        operation: OutboxOperation.create,
        payload: jsonEncode(request.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      ),
    );
  });
}
