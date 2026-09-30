import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_cancellation.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// L'annulation d'un fait de paie, partagée par les avances et les
/// versements : les mêmes colonnes `cancellation_*` sur les deux tables.
class PayrollCancellationStore {
  final PayrollStore _store;
  final String _table;

  const PayrollCancellationStore(this._store, this._table);

  /// Pose l'annulation de [id] et la met en file, dans une transaction.
  Future<void> request(
    String id, {
    required String cancellationId,
    required String reason,
    required PayrollQueued queued,
    required String schoolId,
    required int nowMs,
  }) => _store.transaction((txn) async {
    await txn.update(
      _table,
      {
        'cancellation_id': cancellationId,
        'cancellation_reason': reason,
        'cancellation_status': StaffSyncState.pending.dbValue,
        'cancellation_error': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    await PayrollStore.enqueue(txn, queued, schoolId: schoolId, nowMs: nowMs);
  });

  /// L'issue de l'annulation [cancellationId] ; [cancelledAt] = l'instant que
  /// le serveur a retenu, ou celui du poste quand le fait n'était jamais parti.
  Future<void> settle(
    String cancellationId, {
    required bool failed,
    String? reason,
    String? cancelledAt,
  }) => _store.db.update(
    _table,
    {
      'cancellation_status':
          (failed ? StaffSyncState.failed : StaffSyncState.synced).dbValue,
      'cancellation_error': reason,
      if (!failed) 'cancelled_at': cancelledAt,
    },
    where: 'cancellation_id = ?',
    whereArgs: [cancellationId],
  );

  /// Le fait lié à [cancellationId] : `(id, sync_status)`, ou `null`.
  Future<({String id, StaffSyncState state})?> targetOf(
    String cancellationId,
  ) async {
    final rows = await _store.db.query(
      _table,
      columns: ['id', 'sync_status'],
      where: 'cancellation_id = ?',
      whereArgs: [cancellationId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (
      id: rows.single['id']! as String,
      state: StaffSyncState.fromDb(rows.single['sync_status'] as String?),
    );
  }

  /// Colonnes serveur d'une annulation descendue : elle l'emporte sur ce que
  /// la tablette croyait.
  static Map<String, Object?> serverColumns({
    required String? cancelledAt,
    required String? reason,
  }) => cancelledAt == null
      ? const {}
      : {
          'cancelled_at': cancelledAt,
          'cancellation_reason': reason,
          'cancellation_status': StaffSyncState.synced.dbValue,
          'cancellation_error': null,
        };

  static PayrollCancellation? fromRow(Map<String, Object?> row) {
    final id = row['cancellation_id'] as String?;
    final cancelledAt = row['cancelled_at'] as String?;
    if (id == null && cancelledAt == null) return null;
    return PayrollCancellation(
      id: id ?? '',
      reason: row['cancellation_reason'] as String? ?? '',
      cancelledAt: cancelledAt,
      syncState: cancelledAt != null
          ? StaffSyncState.synced
          : StaffSyncState.fromDb(row['cancellation_status'] as String?),
      syncError: row['cancellation_error'] as String?,
    );
  }
}
