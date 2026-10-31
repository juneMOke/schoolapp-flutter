import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_deduction_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les saisies de rubriques (`payroll_deductions`), une par école, mois, agent
/// et rubrique, dernier écrit gagne.
///
/// Une saisie **refusée** n'est plus au serveur : elle reste ici, hors calcul,
/// le temps que l'économe la lise. La descente la remplace dès que le serveur
/// sert une valeur pour la même clé.
class PayrollDeductionDao {
  final PayrollStore _store;

  PayrollDeductionDao(DatabaseExecutor db) : _store = PayrollStore(db);

  static const String table = 'payroll_deductions';

  static const String _keyExpression =
      "month || ':' || staff_member_id || ':' || deduction_type_id";

  static String saisieKey(String month, String member, String type) =>
      '$month:$member:$type';

  static PayrollRowKey _key(
    String schoolId,
    String month,
    String member,
    String type,
  ) => {
    'school_id': schoolId,
    'month': month,
    'staff_member_id': member,
    'deduction_type_id': type,
  };

  /// Mois → agent → saisies.
  Future<Map<String, Map<String, List<PayrollDeductionEntry>>>> forSchool(
    String schoolId,
  ) async {
    final rows = await _store.db.rawQuery(
      'SELECT *, '
      '${PayrollStore.lwwEffectiveStatusColumn(PayrollOutbox.deduction, _keyExpression)} '
      'FROM $table WHERE school_id = ?',
      [schoolId],
    );
    final result = <String, Map<String, List<PayrollDeductionEntry>>>{};
    for (final row in rows) {
      final entry = PayrollDeductionEntry(
        staffMemberId: row['staff_member_id']! as String,
        deductionTypeId: row['deduction_type_id']! as String,
        amountInCents: row['amount_in_cents']! as int,
        currency: row['currency']! as String,
        syncState: PayrollStore.effectiveState(row),
        syncError: row['sync_error'] as String?,
        syncErrorCode: row['sync_error_code'] as String?,
      );
      final month = result[row['month']! as String] ??= {};
      (month[entry.staffMemberId] ??= []).add(entry);
    }
    return result;
  }

  /// Remplace les saisies de [month] par [items]. Reste ce qui attend encore
  /// son envoi, et ce qui a été refusé sans valeur au serveur. `null` : le
  /// champ n'est pas servi (un accusé de geste), rien ne bouge.
  static Future<void> applyServer(
    DatabaseExecutor txn,
    String month,
    List<PayrollDeductionDto>? items, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (items == null) return;
    final served = <String>{};
    for (final item in items) {
      final key = _key(
        schoolId,
        month,
        item.staffMemberId,
        item.deductionTypeId,
      );
      final saisie = saisieKey(month, item.staffMemberId, item.deductionTypeId);
      served.add(saisie);
      if (await PayrollStore.isPending(
        txn,
        table,
        key,
        saisieType: PayrollOutbox.deduction,
        saisieKey: saisie,
      )) {
        continue;
      }
      await PayrollStore.upsert(txn, table, key, {
        'amount_in_cents': item.amountInCents,
        'currency': item.currency,
        'client_updated_at': item.clientUpdatedAt,
        'sync_status': RecordSyncState.synced.dbValue,
        'sync_error': null,
        'sync_error_code': null,
        'updated_at': nowMs,
      });
    }
    final rows = await txn.query(
      table,
      columns: ['staff_member_id', 'deduction_type_id'],
      where: 'school_id = ? AND month = ? AND sync_status = ?',
      whereArgs: [schoolId, month, RecordSyncState.synced.dbValue],
    );
    for (final row in rows) {
      final member = row['staff_member_id']! as String;
      final type = row['deduction_type_id']! as String;
      if (served.contains(saisieKey(month, member, type))) continue;
      final key = _key(schoolId, month, member, type);
      await txn.delete(
        table,
        where: PayrollStore.where(key),
        whereArgs: PayrollStore.args(key),
      );
    }
  }

  /// Enregistre, dans une même transaction, les éléments variables de l'agent
  /// et ses saisies modifiées — une entrée d'outbox par montant changé.
  Future<void> saveWithVariables(
    PayrollVariablesRequestDto? variables,
    List<PayrollDeductionRequestDto> requests, {
    required String schoolId,
    required int nowMs,
  }) => _store.transaction((txn) async {
    if (variables != null) {
      await PayrollVariablesDao(
        txn,
      ).save(variables, schoolId: schoolId, nowMs: nowMs);
    }
    final store = PayrollStore(txn);
    for (final request in requests) {
      final saisie = saisieKey(
        request.month,
        request.staffMemberId,
        request.deductionTypeId,
      );
      await store.write(
        table,
        _key(
          schoolId,
          request.month,
          request.staffMemberId,
          request.deductionTypeId,
        ),
        {
          'amount_in_cents': request.amountInCents,
          'currency': request.currency,
          'client_updated_at': request.clientUpdatedAt,
          'updated_at': nowMs,
        },
        PayrollQueued(
          entryId: PayrollOutbox.saisieId(
            PayrollOutbox.deduction,
            saisie,
            request.clientUpdatedAt,
          ),
          aggregateType: PayrollOutbox.deduction,
          aggregateId: PayrollOutbox.monthKey(request.month),
          payload: request.toJson(),
        ),
        schoolId: schoolId,
        nowMs: nowMs,
      );
    }
  });

  Future<bool> settle(
    PayrollDeductionRequestDto sent, {
    required String schoolId,
    required bool failed,
    String? code,
    String? reason,
  }) => _store.settleLww(
    table,
    _key(schoolId, sent.month, sent.staffMemberId, sent.deductionTypeId),
    sentClientUpdatedAt: sent.clientUpdatedAt,
    failed: failed,
    code: code,
    reason: reason,
  );

  /// L'économe a lu le refus : la saisie disparaît. Seule une ligne refusée
  /// s'efface ainsi.
  Future<void> dismiss(
    String month,
    PayrollDeductionEntry entry, {
    required String schoolId,
  }) => _store.db.delete(
    table,
    where:
        '${PayrollStore.where(_key(schoolId, month, entry.staffMemberId, entry.deductionTypeId))} '
        'AND sync_status != ?',
    whereArgs: [
      ...PayrollStore.args(
        _key(schoolId, month, entry.staffMemberId, entry.deductionTypeId),
      ),
      RecordSyncState.synced.dbValue,
    ],
  );
}
