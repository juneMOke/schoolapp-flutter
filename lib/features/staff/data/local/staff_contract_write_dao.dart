import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_push_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Écritures locales des contrats — **toujours avec leur entrée d'outbox, dans
/// la même transaction**.
///
/// À l'inverse de la fiche, rien ne se remplace : une pose et une correction
/// sont des gestes, chacun son entrée (`STAFF_CONTRACT:<contrat>`,
/// `STAFF_CONTRACT_CORRECTION:<geste>`). Une période enregistrée ne se réécrit
/// pas.
class StaffContractWriteDao {
  final Database _db;

  const StaffContractWriteDao(this._db);

  static const String table = StaffContractLocalModel.table;
  static const String contractAggregateType = 'STAFF_CONTRACT';
  static const String correctionAggregateType = 'STAFF_CONTRACT_CORRECTION';

  static String contractEntryId(String contractId) =>
      '$contractAggregateType:$contractId';

  static String correctionEntryId(String correctionId) =>
      '$correctionAggregateType:$correctionId';

  /// Pose une période sur le poste et la met en file.
  Future<void> addContract({
    required StaffContractSyncRequestDto request,
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await txn.insert(
      table,
      StaffContractLocalModel.pendingColumns(
        request.contract,
        staffMemberId: request.staffMemberId,
        schoolId: schoolId,
        nowMs: nowMs,
      ),
    );
    await OutboxDao(txn).enqueue(
      OutboxEntry(
        id: contractEntryId(request.contract.id),
        aggregateType: contractAggregateType,
        aggregateId: request.staffMemberId,
        operation: OutboxOperation.create,
        payload: jsonEncode(request.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      ),
    );
  });

  /// Corrige une période sur le poste : elle sort de la frise affichée (le
  /// marqueur local), son remplaçant y entre, et le geste part en file.
  ///
  /// La période corrigée n'est **pas** réécrite : `corrected_at` appartient au
  /// serveur, qui le posera à l'accusé.
  Future<void> correct({
    required StaffContractCorrectionRequestDto request,
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await txn.update(
      table,
      {'correction_pending_id': request.correctionId, 'updated_at': nowMs},
      where: 'id = ?',
      whereArgs: [request.contractId],
    );
    final replacement = request.replacement;
    if (replacement != null) {
      await txn.insert(
        table,
        StaffContractLocalModel.pendingColumns(
          replacement,
          staffMemberId: request.staffMemberId,
          schoolId: schoolId,
          nowMs: nowMs,
        ),
      );
    }
    await OutboxDao(txn).enqueue(
      OutboxEntry(
        id: correctionEntryId(request.correctionId),
        aggregateType: correctionAggregateType,
        aggregateId: request.staffMemberId,
        operation: OutboxOperation.create,
        payload: jsonEncode(request.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      ),
    );
  });
}
