import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/staff_pay_profile_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/staff_pay_profile.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les profils de paie (`staff_pay_profiles`), dernier écrit gagne.
class StaffPayProfileDao {
  final PayrollStore _store;

  StaffPayProfileDao(DatabaseExecutor db) : _store = PayrollStore(db);

  static const String table = 'staff_pay_profiles';

  static PayrollRowKey _key(String staffMemberId) => {
    'staff_member_id': staffMemberId,
  };

  Future<Map<String, StaffPayProfile>> forSchool(String schoolId) async {
    final rows = await _store.db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    return {
      for (final row in rows) row['staff_member_id']! as String: _toEntity(row),
    };
  }

  /// Une page descendue. Un profil retouché sur la tablette et pas encore
  /// accusé attend son propre accusé, qui tranchera au dernier écrit.
  Future<int> applyPulled(
    List<StaffPayProfileDto> items, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (items.isEmpty || schoolId.isEmpty) return 0;
    await _store.transaction((txn) async {
      for (final item in items) {
        final key = _key(item.staffMemberId);
        if (await PayrollStore.isPending(txn, table, key)) continue;
        await PayrollStore.upsert(txn, table, key, {
          'school_id': schoolId,
          ..._columns(item),
          'server_updated_at': item.serverUpdatedAt,
          'sync_status': StaffSyncState.synced.dbValue,
          'sync_error': null,
          'sync_error_code': null,
          'updated_at': nowMs,
        });
      }
    });
    return items.length;
  }

  Future<void> save(
    StaffPayProfileRequestDto request, {
    required String schoolId,
    required int nowMs,
  }) => _store.write(
    table,
    _key(request.profile.staffMemberId),
    {'school_id': schoolId, ..._columns(request.profile), 'updated_at': nowMs},
    PayrollQueued(
      entryId: PayrollOutbox.entryId(
        PayrollOutbox.profile,
        request.profile.staffMemberId,
      ),
      aggregateType: PayrollOutbox.profile,
      aggregateId: request.profile.staffMemberId,
      payload: request.toJson(),
    ),
    schoolId: schoolId,
    nowMs: nowMs,
  );

  /// L'accusé : la ligne retenue par le serveur (appliquée ou gagnante) la
  /// remplace, si la tablette n'a rien retouché pendant le vol.
  Future<bool> settle(
    String staffMemberId, {
    required String sentClientUpdatedAt,
    required bool failed,
    StaffPayProfileDto? retained,
    String? code,
    String? reason,
  }) => _store.settleLww(
    table,
    _key(staffMemberId),
    sentClientUpdatedAt: sentClientUpdatedAt,
    failed: failed,
    code: code,
    reason: reason,
    serverColumns: retained == null
        ? const {}
        : {
            ..._columns(retained),
            'server_updated_at': retained.serverUpdatedAt,
          },
  );

  static Map<String, Object?> _columns(StaffPayProfileDto dto) => {
    'dependent_children': dto.dependentChildren,
    'preferred_mode': dto.preferredMode,
    'operator': dto.operator,
    'payout_phone': dto.payoutPhone,
    'bank_name': dto.bankName,
    'bank_account': dto.bankAccount,
    'client_updated_at': dto.clientUpdatedAt,
  };

  static StaffPayProfile _toEntity(Map<String, Object?> row) => StaffPayProfile(
    staffMemberId: row['staff_member_id']! as String,
    dependentChildren: row['dependent_children'] as int? ?? 0,
    preferredMode: PayoutMode.fromWire(row['preferred_mode'] as String?),
    operator: MobileMoneyOperator.fromWire(row['operator'] as String?),
    payoutPhone: row['payout_phone'] as String?,
    bankName: row['bank_name'] as String?,
    bankAccount: row['bank_account'] as String?,
    syncState: StaffSyncState.fromDb(row['sync_status'] as String?),
    syncError: row['sync_error'] as String?,
  );
}
