import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les éléments variables (`payroll_variables`), dernier écrit gagne, une
/// ligne par école, mois et agent.
class PayrollVariablesDao {
  final PayrollStore _store;

  PayrollVariablesDao(DatabaseExecutor db) : _store = PayrollStore(db);

  static const String table = 'payroll_variables';

  static PayrollRowKey _key(String schoolId, String month, String memberId) => {
    'school_id': schoolId,
    'month': month,
    'staff_member_id': memberId,
  };

  /// Mois → agent → éléments.
  Future<Map<String, Map<String, PayrollVariables>>> forSchool(
    String schoolId,
  ) async {
    final rows = await _store.db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    final result = <String, Map<String, PayrollVariables>>{};
    for (final row in rows) {
      final variables = PayrollVariables(
        staffMemberId: row['staff_member_id']! as String,
        overtimeMinutes: row['overtime_minutes'] as int?,
        overtimeRateInCents: row['overtime_rate_in_cents'] as int?,
        dependentChildren: row['dependent_children'] as int?,
        syncState: StaffSyncState.fromDb(row['sync_status'] as String?),
        syncError: row['sync_error'] as String?,
      );
      (result[row['month']! as String] ??= {})[variables.staffMemberId] =
          variables;
    }
    return result;
  }

  /// Ceux que la paie [month] porte au serveur ; une saisie locale en attente
  /// n'est pas écrasée.
  static Future<void> applyServer(
    DatabaseExecutor txn,
    String month,
    List<PayrollVariablesDto> items, {
    required String schoolId,
    required int nowMs,
  }) async {
    for (final item in items) {
      final key = _key(schoolId, month, item.staffMemberId);
      if (await PayrollStore.isPending(txn, table, key)) continue;
      await PayrollStore.upsert(txn, table, key, {
        'overtime_minutes': item.overtimeMinutes,
        'overtime_rate_in_cents': item.overtimeRateInCents,
        'dependent_children': item.dependentChildren,
        'client_updated_at': item.clientUpdatedAt,
        'sync_status': StaffSyncState.synced.dbValue,
        'sync_error': null,
        'sync_error_code': null,
        'updated_at': nowMs,
      });
    }
  }

  Future<void> save(
    PayrollVariablesRequestDto request, {
    required String schoolId,
    required int nowMs,
  }) => _store.write(
    table,
    _key(schoolId, request.month, request.staffMemberId),
    {
      'overtime_minutes': request.overtimeMinutes,
      'overtime_rate_in_cents': request.overtimeRateInCents,
      'dependent_children': request.dependentChildren,
      'client_updated_at': request.clientUpdatedAt,
      'updated_at': nowMs,
    },
    PayrollQueued(
      entryId: PayrollOutbox.saisieId(
        PayrollOutbox.variables,
        '${request.month}:${request.staffMemberId}',
        request.clientUpdatedAt,
      ),
      aggregateType: PayrollOutbox.variables,
      aggregateId: PayrollOutbox.monthKey(request.month),
      payload: request.toJson(),
    ),
    schoolId: schoolId,
    nowMs: nowMs,
  );

  Future<bool> settle(
    PayrollVariablesRequestDto sent, {
    required String schoolId,
    required bool failed,
    String? code,
    String? reason,
  }) => _store.settleLww(
    table,
    _key(schoolId, sent.month, sent.staffMemberId),
    sentClientUpdatedAt: sent.clientUpdatedAt,
    failed: failed,
    code: code,
    reason: reason,
  );
}
