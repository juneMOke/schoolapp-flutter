import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce que les accusés des gestes de contrat font aux périodes locales.
class StaffContractSyncDao {
  final Database _db;

  const StaffContractSyncDao(this._db);

  static const String table = StaffContractLocalModel.table;

  /// La période est-elle connue du serveur ? Une correction ne part qu'après.
  Future<bool> isSynced(String contractId) async {
    final rows = await _db.query(
      table,
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [contractId],
    );
    return rows.isNotEmpty &&
        rows.single['sync_status'] == StaffSyncState.synced.dbValue;
  }

  /// Accusé d'une pose : la période devient celle du serveur.
  Future<void> applyAck(
    StaffContractDeltaDto canonical, {
    required String schoolId,
    required int nowMs,
  }) =>
      StaffContractDao.upsert(_db, canonical, schoolId: schoolId, nowMs: nowMs);

  /// Accusé d'une correction : la période corrigée et son remplaçant, dans une
  /// transaction ; le marqueur local tombe.
  Future<void> applyCorrectionAck({
    required StaffContractDeltaDto corrected,
    required StaffContractDeltaDto? replacement,
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await StaffContractDao.upsert(
      txn,
      corrected,
      schoolId: schoolId,
      nowMs: nowMs,
    );
    if (replacement != null) {
      await StaffContractDao.upsert(
        txn,
        replacement,
        schoolId: schoolId,
        nowMs: nowMs,
      );
    }
    await txn.update(
      table,
      {'correction_pending_id': null},
      where: 'id = ?',
      whereArgs: [corrected.id],
    );
  });

  /// Refus déterministe d'une pose : la période reste, marquée refusée.
  Future<void> markRejected(
    String contractId, {
    required String? code,
    required String reason,
    required int nowMs,
  }) => _db.update(
    table,
    {
      'sync_status': StaffSyncState.failed.dbValue,
      'sync_error': reason,
      'sync_error_code': code,
      'updated_at': nowMs,
    },
    where: 'id = ?',
    whereArgs: [contractId],
  );

  /// Refus d'une correction : la période d'origine revient dans la frise
  /// (marqueur retiré) et porte le refus ; le remplaçant, jamais accepté,
  /// s'efface.
  Future<void> rejectCorrection({
    required String contractId,
    required String? replacementId,
    required String? code,
    required String reason,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await txn.update(
      table,
      {
        'correction_pending_id': null,
        'sync_error': reason,
        'sync_error_code': code,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [contractId],
    );
    if (replacementId != null) {
      await txn.delete(table, where: 'id = ?', whereArgs: [replacementId]);
    }
  });

  /// La période a été purgée côté serveur (410).
  Future<void> delete(String contractId) =>
      _db.delete(table, where: 'id = ?', whereArgs: [contractId]);
}
