import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_payout_policy.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Le taux de versement de chaque mois (`payroll_payout_policies`), dernier
/// écrit gagne, une ligne par école et par mois.
class PayrollPayoutPolicyDao {
  final PayrollStore _store;

  PayrollPayoutPolicyDao(DatabaseExecutor db) : _store = PayrollStore(db);

  static const String table = 'payroll_payout_policies';

  static PayrollRowKey _key(String schoolId, String month) => {
    'school_id': schoolId,
    'month': month,
  };

  /// Mois → taux.
  Future<Map<String, PayrollPayoutPolicy>> forSchool(String schoolId) async {
    final rows = await _store.db.rawQuery(
      'SELECT *, '
      '${PayrollStore.lwwEffectiveStatusColumn(PayrollOutbox.payoutPolicy, 'month')} '
      'FROM $table WHERE school_id = ?',
      [schoolId],
    );
    return {
      for (final row in rows)
        row['month']! as String: PayrollPayoutPolicy(
          month: row['month']! as String,
          ratePercent: row['rate_percent']! as int,
          reason: row['reason'] as String?,
          syncState: PayrollStore.effectiveState(row),
          syncError: row['sync_error'] as String?,
        ),
    };
  }

  /// Celui que la paie [month] porte au serveur ; une saisie locale en
  /// attente n'est pas écrasée. Sans taux au serveur, rien n'est effacé : un
  /// serveur v1 n'en porte jamais.
  static Future<void> applyServer(
    DatabaseExecutor txn,
    String month,
    PayrollPayoutPolicyDto? policy, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (policy == null) return;
    final key = _key(schoolId, month);
    if (await PayrollStore.isPending(
      txn,
      table,
      key,
      saisieType: PayrollOutbox.payoutPolicy,
      saisieKey: month,
    )) {
      return;
    }
    await PayrollStore.upsert(txn, table, key, {
      'rate_percent': policy.ratePercent,
      'reason': policy.reason,
      'client_updated_at': policy.clientUpdatedAt,
      'sync_status': RecordSyncState.synced.dbValue,
      'sync_error': null,
      'sync_error_code': null,
      'updated_at': nowMs,
    });
  }

  Future<void> save(
    PayrollPayoutPolicyRequestDto request, {
    required String schoolId,
    required int nowMs,
  }) => _store.write(
    table,
    _key(schoolId, request.month),
    {
      'rate_percent': request.ratePercent,
      'reason': request.reason,
      'client_updated_at': request.clientUpdatedAt,
      'updated_at': nowMs,
    },
    PayrollQueued(
      entryId: PayrollOutbox.saisieId(
        PayrollOutbox.payoutPolicy,
        request.month,
        request.clientUpdatedAt,
      ),
      aggregateType: PayrollOutbox.payoutPolicy,
      aggregateId: PayrollOutbox.monthKey(request.month),
      payload: request.toJson(),
    ),
    schoolId: schoolId,
    nowMs: nowMs,
  );

  Future<bool> settle(
    PayrollPayoutPolicyRequestDto sent, {
    required String schoolId,
    required bool failed,
    String? code,
    String? reason,
  }) => _store.settleLww(
    table,
    _key(schoolId, sent.month),
    sentClientUpdatedAt: sent.clientUpdatedAt,
    failed: failed,
    code: code,
    reason: reason,
  );
}
