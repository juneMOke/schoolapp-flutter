import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_variables_dao.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_deduction_dto.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_write_requests.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_lww.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les saisies de rubriques (`payroll_deductions`), une par école, mois, agent
/// et rubrique, dernier écrit gagne.
///
/// Une saisie **refusée** reste ici le temps que l'économe la lise. Le calcul
/// compte alors ce que le serveur tient (`server_*`), pas le montant refusé.
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
        serverAmountInCents: row['server_amount_in_cents'] as int?,
        serverCurrency: row['server_currency'] as String?,
        syncState: PayrollStore.effectiveState(row),
        syncError: row['sync_error'] as String?,
        syncErrorCode: row['sync_error_code'] as String?,
      );
      final month = result[row['month']! as String] ??= {};
      (month[entry.staffMemberId] ??= []).add(entry);
    }
    return result;
  }

  /// La descente du mois. Ce que le serveur tient se range toujours ; une
  /// saisie en attente ou refusée garde sa ligne, et une saisie synchronisée
  /// prend la valeur servie ou disparaît avec elle. `null` : le champ n'est pas
  /// servi (un accusé de geste), rien ne bouge.
  ///
  /// Un accusé tout frais passe avant : cette page peut avoir été lue avant lui.
  static Future<void> applyServer(
    DatabaseExecutor txn,
    String month,
    List<PayrollDeductionDto>? items, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (items == null) return;
    final rows = await txn.query(
      table,
      columns: [
        'staff_member_id',
        'deduction_type_id',
        'sync_status',
        'acked_at',
      ],
      where: 'school_id = ? AND month = ?',
      whereArgs: [schoolId, month],
    );
    final local = {
      for (final row in rows)
        saisieKey(
          month,
          row['staff_member_id']! as String,
          row['deduction_type_id']! as String,
        ): row,
    };
    bool fresh(Map<String, Object?> row) {
      final acked = row['acked_at'] as int?;
      return acked != null && nowMs - acked < PayrollStore.freshAckWindowMs;
    }

    for (final item in items) {
      final saisie = saisieKey(month, item.staffMemberId, item.deductionTypeId);
      final key = _key(
        schoolId,
        month,
        item.staffMemberId,
        item.deductionTypeId,
      );
      final row = local.remove(saisie);
      final server = {
        'server_amount_in_cents': item.amountInCents,
        'server_currency': item.currency,
      };
      if (row != null && fresh(row)) continue;
      if (row != null && row['sync_status'] != RecordSyncState.synced.dbValue) {
        await txn.update(
          table,
          server,
          where: PayrollStore.where(key),
          whereArgs: PayrollStore.args(key),
        );
        continue;
      }
      await PayrollStore.upsert(txn, table, key, {
        ...server,
        'amount_in_cents': item.amountInCents,
        'currency': item.currency,
        'client_updated_at': item.clientUpdatedAt,
        'sync_status': RecordSyncState.synced.dbValue,
        'sync_error': null,
        'sync_error_code': null,
        'updated_at': nowMs,
      });
    }
    for (final row in local.values) {
      if (fresh(row)) continue;
      final key = _key(
        schoolId,
        month,
        row['staff_member_id']! as String,
        row['deduction_type_id']! as String,
      );
      if (row['sync_status'] == RecordSyncState.synced.dbValue) {
        await txn.delete(
          table,
          where: PayrollStore.where(key),
          whereArgs: PayrollStore.args(key),
        );
      } else {
        await txn.update(
          table,
          {'server_amount_in_cents': null, 'server_currency': null},
          where: PayrollStore.where(key),
          whereArgs: PayrollStore.args(key),
        );
      }
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

  /// La saisie envoyée est-elle encore celle de la ligne ? Sinon elle n'a plus
  /// rien à dire : sa remplaçante part avec sa propre entrée, et une ligne
  /// retirée ne se renvoie pas.
  Future<bool> isCurrent(
    PayrollDeductionRequestDto sent, {
    required String schoolId,
  }) async {
    final key = _key(
      schoolId,
      sent.month,
      sent.staffMemberId,
      sent.deductionTypeId,
    );
    final rows = await _store.db.query(
      table,
      columns: ['client_updated_at'],
      where: PayrollStore.where(key),
      whereArgs: PayrollStore.args(key),
    );
    return rows.isNotEmpty &&
        StaffLww.sameInstant(
          rows.single['client_updated_at'] as String?,
          sent.clientUpdatedAt,
        );
  }

  /// L'accusé : le serveur tient maintenant [sent], ou [retained] s'il a gardé
  /// une écriture plus récente — même si la ligne a été retouchée entre-temps.
  Future<void> acknowledge(
    PayrollDeductionRequestDto sent, {
    required String schoolId,
    required int nowMs,
    PayrollDeductionDto? retained,
  }) => _store.transaction((txn) async {
    final key = _key(
      schoolId,
      sent.month,
      sent.staffMemberId,
      sent.deductionTypeId,
    );
    final amount = retained?.amountInCents ?? sent.amountInCents;
    final currency = retained?.currency ?? sent.currency;
    await txn.update(
      table,
      {
        'server_amount_in_cents': amount,
        'server_currency': currency,
        'acked_at': nowMs,
      },
      where: PayrollStore.where(key),
      whereArgs: PayrollStore.args(key),
    );
    await PayrollStore(txn).settleLww(
      table,
      key,
      sentClientUpdatedAt: sent.clientUpdatedAt,
      failed: false,
      serverColumns: retained == null
          ? const {}
          : {
              'amount_in_cents': amount,
              'currency': currency,
              'client_updated_at': retained.clientUpdatedAt,
            },
    );
  });

  Future<bool> refuse(
    PayrollDeductionRequestDto sent, {
    required String schoolId,
    String? code,
    String? reason,
  }) => _store.settleLww(
    table,
    _key(schoolId, sent.month, sent.staffMemberId, sent.deductionTypeId),
    sentClientUpdatedAt: sent.clientUpdatedAt,
    failed: true,
    code: code,
    reason: reason,
  );

  /// Une saisie de [typeId] attend-elle encore de partir ?
  Future<bool> hasQueuedOn(String typeId) async {
    final rows = await _store.db.rawQuery(
      'SELECT 1 FROM ${OutboxDao.table} WHERE status = ? AND id LIKE ? LIMIT 1',
      [OutboxStatus.pending.dbValue, '${PayrollOutbox.deduction}:%:$typeId@%'],
    );
    return rows.isNotEmpty;
  }

  /// L'économe a lu le refus : la ligne revient à ce que le serveur tient, ou
  /// disparaît s'il ne tient rien, avec ce qui restait du refus dans la file.
  /// Une saisie qui attend encore son envoi n'est pas un refus.
  Future<void> dismiss(
    String month,
    PayrollDeductionEntry entry, {
    required String schoolId,
  }) => _store.transaction((txn) async {
    final key = _key(
      schoolId,
      month,
      entry.staffMemberId,
      entry.deductionTypeId,
    );
    final saisie = saisieKey(month, entry.staffMemberId, entry.deductionTypeId);
    if (await PayrollStore.isPending(
      txn,
      table,
      key,
      saisieType: PayrollOutbox.deduction,
      saisieKey: saisie,
    )) {
      return;
    }
    await txn.delete(
      OutboxDao.table,
      where: 'status != ? AND id LIKE ?',
      whereArgs: [
        OutboxStatus.acked.dbValue,
        '${PayrollOutbox.deduction}:$saisie@%',
      ],
    );
    final restored = entry.serverAmountInCents != null;
    if (!restored) {
      await txn.delete(
        table,
        where: '${PayrollStore.where(key)} AND sync_status != ?',
        whereArgs: [...PayrollStore.args(key), RecordSyncState.synced.dbValue],
      );
      return;
    }
    await txn.update(
      table,
      {
        'amount_in_cents': entry.serverAmountInCents,
        'currency': entry.serverCurrency,
        'sync_status': RecordSyncState.synced.dbValue,
        'sync_error': null,
        'sync_error_code': null,
      },
      where: PayrollStore.where(key),
      whereArgs: PayrollStore.args(key),
    );
  });
}
