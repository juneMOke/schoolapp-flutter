import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_cancellation.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// L'annulation d'un fait de paie, partagée par les avances et les
/// versements : les mêmes colonnes `cancellation_*` sur les deux tables.
class PayrollCancellationStore {
  final PayrollStore _store;
  final String _table;

  /// L'agrégat d'outbox du fait (`SALARY_ADVANCE`, `PAYROLL_DISBURSEMENT`).
  final String _factType;

  const PayrollCancellationStore(this._store, this._table, this._factType);

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
        'cancellation_status': RecordSyncState.pending.dbValue,
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
          (failed ? RecordSyncState.failed : RecordSyncState.synced).dbValue,
      'cancellation_error': reason,
      if (!failed) 'cancelled_at': cancelledAt,
    },
    where: 'cancellation_id = ?',
    whereArgs: [cancellationId],
  );

  /// Le fait [factId] porte-t-il une annulation qui n'a pas été refusée ?
  /// Alors il ne doit plus partir : la tablette l'a annulé avant que le
  /// serveur ne le connaisse.
  Future<bool> isCancelled(String factId) async {
    final rows = await _store.db.query(
      _table,
      columns: ['cancellation_id', 'cancellation_status', 'cancelled_at'],
      where: 'id = ?',
      whereArgs: [factId],
    );
    if (rows.isEmpty) return false;
    final cancellation = fromRow(rows.single);
    return cancellation != null && !cancellation.isRefused;
  }

  /// Le fait lié à [cancellationId] : `(id, sync_status)`, ou `null`.
  Future<({String id, RecordSyncState state})?> targetOf(
    String cancellationId,
  ) async {
    final rows = await _store.db.rawQuery(
      'SELECT f.id, f.sync_status, '
      '${PayrollStore.effectiveStatusColumns('f', _factType)} '
      'FROM $_table f WHERE f.cancellation_id = ? LIMIT 1',
      [cancellationId],
    );
    if (rows.isEmpty) return null;
    return (
      id: rows.single['id']! as String,
      state: PayrollStore.effectiveState(rows.single),
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
          'cancellation_status': RecordSyncState.synced.dbValue,
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
          ? RecordSyncState.synced
          : RecordSyncState.fromDb(row['cancellation_status'] as String?),
      syncError: row['cancellation_error'] as String?,
    );
  }
}
