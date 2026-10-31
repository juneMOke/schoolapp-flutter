import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/staff/local/payroll_settings_seed.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_deduction_dao.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_outbox.dart';
import 'package:school_app_flutter/features/payroll/data/local/payroll_store.dart';
import 'package:school_app_flutter/features/payroll/data/sync/payroll_deduction_dto.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_gate.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le catalogue des rubriques de l'école (`payroll_deduction_types`) : semé
/// par le socle, modifiable sur la tablette, dernier écrit gagne par rubrique.
///
/// `server_known` dit que le serveur l'a déjà eue : c'est lui qui distingue
/// une rubrique supprimée au serveur (à retirer) d'une création encore jamais
/// reçue (à garder).
class PayrollDeductionTypeDao {
  final PayrollStore _store;

  PayrollDeductionTypeDao(DatabaseExecutor db) : _store = PayrollStore(db);

  static const String table = 'payroll_deduction_types';

  static PayrollRowKey _key(String schoolId, String id) => {
    'school_id': schoolId,
    'id': id,
  };

  /// Tout le catalogue, archivées comprises, dans l'ordre du moteur.
  Future<List<PayrollDeductionType>> forSchool(String schoolId) async {
    final rows = await _store.db.rawQuery(
      'SELECT *, '
      '${PayrollStore.lwwEffectiveStatusColumn(PayrollOutbox.deductionType, 'id')} '
      'FROM $table WHERE school_id = ? ORDER BY sort_order, id',
      [schoolId],
    );
    return [
      for (final row in rows)
        PayrollDeductionType(
          id: row['id']! as String,
          label: row['label']! as String,
          sortOrder: row['sort_order']! as int,
          archived: row['archived'] == 1,
          serverKnown: row['server_known'] == 1,
          syncState: PayrollStore.effectiveState(row),
          syncError: row['sync_error'] as String?,
          syncErrorCode: row['sync_error_code'] as String?,
        ),
    ];
  }

  /// La liste du socle fait foi. Une écriture encore en file n'est pas
  /// écrasée ; une rubrique que le serveur a connue et ne sert plus est
  /// retirée ; une création qu'il n'a jamais reçue reste.
  Future<void> applySeed(
    List<PayrollDeductionTypeSeed> seeds, {
    required String schoolId,
    required int nowMs,
  }) => _store.transaction((txn) async {
    final served = {for (final seed in seeds) seed.id};
    final rows = await txn.query(
      table,
      columns: ['id', 'server_known'],
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    for (final row in rows) {
      final id = row['id']! as String;
      if (served.contains(id) || row['server_known'] != 1) continue;
      if (await _isQueued(txn, schoolId, id)) continue;
      await txn.delete(
        table,
        where: PayrollStore.where(_key(schoolId, id)),
        whereArgs: PayrollStore.args(_key(schoolId, id)),
      );
    }
    for (final seed in seeds) {
      if (await _isQueued(txn, schoolId, seed.id)) continue;
      await PayrollStore.upsert(txn, table, _key(schoolId, seed.id), {
        'label': seed.label,
        'sort_order': seed.sortOrder,
        'archived': seed.archived ? 1 : 0,
        'client_updated_at': seed.clientUpdatedAt,
        'server_known': 1,
        'sync_status': RecordSyncState.synced.dbValue,
        'sync_error': null,
        'sync_error_code': null,
        'updated_at': nowMs,
      });
    }
  });

  static Future<bool> _isQueued(
    DatabaseExecutor txn,
    String schoolId,
    String id,
  ) => PayrollStore.isPending(
    txn,
    table,
    _key(schoolId, id),
    saisieType: PayrollOutbox.deductionType,
    saisieKey: id,
  );

  /// Enregistre [requests] dans une même transaction, une entrée par rubrique.
  Future<void> saveAll(
    List<PayrollDeductionTypeRequestDto> requests, {
    required String schoolId,
    required int nowMs,
  }) => _store.transaction((txn) async {
    final store = PayrollStore(txn);
    for (final request in requests) {
      await store.write(
        table,
        _key(schoolId, request.id),
        {
          'label': request.label,
          'sort_order': request.sortOrder,
          'archived': request.archived ? 1 : 0,
          'client_updated_at': request.clientUpdatedAt,
          'updated_at': nowMs,
        },
        PayrollQueued(
          entryId: PayrollOutbox.saisieId(
            PayrollOutbox.deductionType,
            request.id,
            request.clientUpdatedAt,
          ),
          aggregateType: PayrollOutbox.deductionType,
          aggregateId: PayrollOutbox.deductionTypeKey(request.id),
          payload: request.toJson(),
        ),
        schoolId: schoolId,
        nowMs: nowMs,
      );
    }
  });

  /// L'accusé : le serveur connaît la rubrique, même si elle a été retouchée
  /// pendant le vol.
  Future<void> acknowledge(
    PayrollDeductionTypeRequestDto sent, {
    required String schoolId,
  }) async {
    await _store.db.update(
      table,
      {'server_known': 1},
      where: PayrollStore.where(_key(schoolId, sent.id)),
      whereArgs: PayrollStore.args(_key(schoolId, sent.id)),
    );
    await _store.settleLww(
      table,
      _key(schoolId, sent.id),
      sentClientUpdatedAt: sent.clientUpdatedAt,
      failed: false,
    );
  }

  Future<bool> refuse(
    PayrollDeductionTypeRequestDto sent, {
    required String schoolId,
    String? code,
    String? reason,
  }) => _store.settleLww(
    table,
    _key(schoolId, sent.id),
    sentClientUpdatedAt: sent.clientUpdatedAt,
    failed: true,
    code: code,
    reason: reason,
  );

  /// Le serveur l'a-t-il déjà eue ?
  Future<bool> isServerKnown(String schoolId, String id) async {
    final rows = await _store.db.query(
      table,
      columns: ['server_known'],
      where: PayrollStore.where(_key(schoolId, id)),
      whereArgs: PayrollStore.args(_key(schoolId, id)),
    );
    return rows.isNotEmpty && rows.single['server_known'] == 1;
  }

  /// Où en est, sur la tablette, la rubrique visée par une saisie. Refusée
  /// sans que le serveur l'ait jamais eue, elle n'arrivera jamais : la saisie
  /// doit échouer à son tour au lieu d'attendre sans fin.
  Future<({StaffParentState state, String? label})> of(
    String schoolId,
    String id,
  ) async {
    final rows = await _store.db.query(
      table,
      columns: ['label', 'server_known'],
      where: PayrollStore.where(_key(schoolId, id)),
      whereArgs: PayrollStore.args(_key(schoolId, id)),
    );
    if (rows.isEmpty) return (state: StaffParentState.missing, label: null);
    final row = rows.single;
    final label = row['label'] as String?;
    if (row['server_known'] == 1) {
      return (state: StaffParentState.acknowledged, label: label);
    }
    final queued = await _store.db.rawQuery(
      'SELECT 1 FROM ${OutboxDao.table} WHERE status = ? AND id LIKE ? LIMIT 1',
      [OutboxStatus.pending.dbValue, '${PayrollOutbox.deductionType}:$id@%'],
    );
    return (
      state: queued.isEmpty
          ? StaffParentState.refused
          : StaffParentState.unsent,
      label: label,
    );
  }

  /// Retire la rubrique après une suppression (ou une pierre tombale), avec
  /// ses saisies à 0 : le serveur les a retirées aussi. Une saisie encore en
  /// file ou refusée reste, et sera jugée à son envoi.
  Future<void> remove(String schoolId, String id) =>
      _store.transaction((txn) async {
        await txn.delete(
          table,
          where: PayrollStore.where(_key(schoolId, id)),
          whereArgs: PayrollStore.args(_key(schoolId, id)),
        );
        await txn.delete(
          PayrollDeductionDao.table,
          where:
              'school_id = ? AND deduction_type_id = ? AND sync_status = ? '
              'AND amount_in_cents = 0',
          whereArgs: [schoolId, id, RecordSyncState.synced.dbValue],
        );
      });

  /// Annule une rubrique que le serveur n'a jamais eue : la ligne, ses
  /// saisies et tout ce qui attendait de partir.
  Future<void> cancelUnsent(String schoolId, String id) =>
      _store.transaction((txn) async {
        await txn.delete(
          table,
          where: PayrollStore.where(_key(schoolId, id)),
          whereArgs: PayrollStore.args(_key(schoolId, id)),
        );
        await txn.delete(
          PayrollDeductionDao.table,
          where: 'school_id = ? AND deduction_type_id = ?',
          whereArgs: [schoolId, id],
        );
        await txn.delete(
          OutboxDao.table,
          where: 'status = ? AND (id LIKE ? OR id LIKE ?)',
          whereArgs: [
            OutboxStatus.pending.dbValue,
            '${PayrollOutbox.deductionType}:$id@%',
            '${PayrollOutbox.deduction}:%:$id@%',
          ],
        );
      });
}
