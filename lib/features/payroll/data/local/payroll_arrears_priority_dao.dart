import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_arrears_priority_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les drapeaux « priorité » des arriérés (`payroll_arrears_priorities`),
/// dernier écrit gagne, une ligne par agent et mois d'origine.
class PayrollArrearsPriorityDao {
  final PayrollStore _store;

  PayrollArrearsPriorityDao(DatabaseExecutor db) : _store = PayrollStore(db);

  static const String table = 'payroll_arrears_priorities';

  static PayrollRowKey _key(String schoolId, String month, String memberId) => {
    'school_id': schoolId,
    'month': month,
    'staff_member_id': memberId,
  };

  static String saisieKey(String month, String memberId) => '$month:$memberId';

  /// `mois|agent` des arriérés en priorité.
  Future<Set<String>> prioritized(String schoolId) async {
    final rows = await _store.db.query(
      table,
      columns: ['month', 'staff_member_id'],
      where: 'school_id = ? AND prioritized = 1',
      whereArgs: [schoolId],
    );
    return {
      for (final row in rows) '${row['month']}|${row['staff_member_id']}',
    };
  }

  Future<int> applyPulled(
    List<PayrollArrearsPriorityDto> items, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (items.isEmpty || schoolId.isEmpty) return 0;
    await _store.transaction((txn) async {
      for (final item in items) {
        final key = _key(schoolId, item.month, item.staffMemberId);
        if (await PayrollStore.isPending(
          txn,
          table,
          key,
          saisieType: PayrollOutbox.arrearsPriority,
          saisieKey: saisieKey(item.month, item.staffMemberId),
        )) {
          continue;
        }
        await PayrollStore.upsert(txn, table, key, {
          'id': item.id,
          'prioritized': item.prioritized ? 1 : 0,
          'client_updated_at': item.clientUpdatedAt,
          'sync_status': RecordSyncState.synced.dbValue,
          'sync_error': null,
          'sync_error_code': null,
          'updated_at': nowMs,
        });
      }
    });
    return items.length;
  }

  Future<void> save(
    PayrollArrearsPriorityRequestDto request, {
    required String schoolId,
    required int nowMs,
  }) {
    final priority = request.priority;
    return _store.write(
      table,
      _key(schoolId, priority.month, priority.staffMemberId),
      {
        'id': priority.id,
        'prioritized': priority.prioritized ? 1 : 0,
        'client_updated_at': priority.clientUpdatedAt,
        'updated_at': nowMs,
      },
      PayrollQueued(
        entryId: PayrollOutbox.saisieId(
          PayrollOutbox.arrearsPriority,
          saisieKey(priority.month, priority.staffMemberId),
          priority.clientUpdatedAt,
        ),
        aggregateType: PayrollOutbox.arrearsPriority,
        aggregateId: PayrollOutbox.lineKey(
          priority.month,
          priority.staffMemberId,
        ),
        payload: request.toJson(),
      ),
      schoolId: schoolId,
      nowMs: nowMs,
    );
  }

  Future<bool> settle(
    PayrollArrearsPriorityRequestDto sent, {
    required String schoolId,
    required bool failed,
    String? code,
    String? reason,
  }) => _store.settleLww(
    table,
    _key(schoolId, sent.priority.month, sent.priority.staffMemberId),
    sentClientUpdatedAt: sent.priority.clientUpdatedAt,
    failed: failed,
    code: code,
    reason: reason,
  );
}
