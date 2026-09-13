import 'dart:convert';

import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Écritures locales du registre — **toujours avec leur entrée d'outbox, dans
/// la même transaction** : une dépense sans entrée ne partirait jamais, une
/// entrée sans dépense pousserait un état introuvable.
///
/// ## Une entrée par dépense et par horloge
///
/// L'identifiant d'entrée est **déterministe** (`EXPENSE:<id>`,
/// `EXPENSE_WITHDRAWAL:<id>`) : chaque geste REMPLACE l'entrée encore en
/// attente par l'état complet le plus récent. La file garde donc au plus un
/// contenu et un retrait par dépense, et corriger une ligne refusée la remet
/// en file d'elle-même (le remplacement repasse l'entrée `PENDING`). La garde
/// anti-TOCTOU du moteur (`markAcked(expectedCreatedAt)`) protège un geste
/// fait pendant qu'une remontée est en vol.
class ExpenseWriteDao {
  final Database _db;

  const ExpenseWriteDao(this._db);

  static const String table = 'expenses';

  /// Contenu d'une dépense (création, modification, duplication, bascule).
  static const String aggregateType = 'EXPENSE';

  /// Retrait ou restauration — un geste à part, sur sa propre horloge.
  static const String withdrawalAggregateType = 'EXPENSE_WITHDRAWAL';

  static String contentEntryId(String expenseId) => '$aggregateType:$expenseId';

  static String withdrawalEntryId(String expenseId) =>
      '$withdrawalAggregateType:$expenseId';

  /// Enregistre l'état complet d'une dépense et le met en file.
  ///
  /// Sur une ligne existante, seuls le contenu et l'état de synchro sont
  /// réécrits ([ExpenseLocalModel.toLocalWriteMap]) : un accusé ou un pull
  /// appliqué entre la lecture de la ligne et cette écriture a pu poser un
  /// numéro, une version, ou lever un retrait en attente — les réécrire depuis
  /// la lecture d'avant les déferait.
  Future<void> saveExpense({
    required ExpenseLocalModel row,
    required ExpenseSyncRequestDto request,
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      final updated = await txn.update(
        table,
        row.toLocalWriteMap(),
        where: 'id = ?',
        whereArgs: [row.id],
      );
      if (updated == 0) await txn.insert(table, row.toMap());
      await OutboxDao(txn).enqueue(
        OutboxEntry(
          id: contentEntryId(row.id),
          aggregateType: aggregateType,
          aggregateId: row.id,
          operation: OutboxOperation.upsert,
          payload: jsonEncode(request.toJson()),
          // Sans école, l'entrée deviendrait inéligible au flush scopé.
          schoolId: row.schoolId,
          createdAt: nowMs,
        ),
      );
    });
  }

  /// Retire (`deleted`) ou restaure une dépense sur le poste, et met le geste
  /// en file. `withdrawal_pending_at` protège le retrait local du pull et des
  /// accusés de contenu tant que le serveur ne l'a pas accusé.
  Future<void> setWithdrawal({
    required ExpenseWithdrawalPayload payload,
    required String schoolId,
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      await txn.update(
        table,
        {
          'deleted_at': payload.deleted ? payload.changedAt : null,
          'withdrawal_pending_at': payload.changedAt,
          'updated_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [payload.expenseId],
      );
      await enqueueWithdrawal(txn, payload, schoolId: schoolId, nowMs: nowMs);
    });
  }

  /// Met un retrait (ou une restauration) en file, dans la transaction de
  /// l'appelant — qui a posé `withdrawal_pending_at` sur la ligne.
  static Future<void> enqueueWithdrawal(
    DatabaseExecutor txn,
    ExpenseWithdrawalPayload payload, {
    required String schoolId,
    required int nowMs,
  }) => OutboxDao(txn).enqueue(
    OutboxEntry(
      id: withdrawalEntryId(payload.expenseId),
      aggregateType: withdrawalAggregateType,
      aggregateId: payload.expenseId,
      operation: OutboxOperation.update,
      payload: jsonEncode(payload.toJson()),
      schoolId: schoolId,
      createdAt: nowMs,
    ),
  );

  /// Retrait ou restauration **purement local** d'une dépense que le serveur
  /// n'a jamais acceptée (pas de numéro, dernier envoi refusé).
  ///
  /// C'est l'abandon sûr que le socle laisse à chaque module (cf. `OutboxDao`,
  /// « pas de `discard` ») : dans la MÊME transaction, la dépense quitte le
  /// registre ET ses deux entrées sont neutralisées, quel que soit leur
  /// statut — le contenu refusé (remis en file depuis la feuille des erreurs,
  /// il ressusciterait chez le serveur une dépense retirée ici) et un retrait
  /// qui attendrait un numéro que le serveur ne donnera pas. Restaurer ne
  /// remet rien en file : la ligne revient « à corriger », et c'est sa
  /// correction qui repartira.
  ///
  /// Rend `false` — sans rien écrire — quand la ligne n'est plus dans cet
  /// état au moment d'écrire (accusée ou corrigée entre-temps), ou quand
  /// [expectedPendingAt] ne désigne plus le geste en attente : c'est alors à
  /// la file de décider.
  Future<bool> setLocalOnlyWithdrawal({
    required String expenseId,
    required String? deletedAt,
    required int nowMs,
    String? expectedPendingAt,
  }) => _db.transaction((txn) async {
    final updated = await txn.update(
      table,
      {
        'deleted_at': deletedAt,
        'withdrawal_pending_at': null,
        'updated_at': nowMs,
      },
      where:
          'id = ? AND expense_number IS NULL AND sync_status = ?'
          '${expectedPendingAt == null ? '' : ' AND withdrawal_pending_at = ?'}',
      whereArgs: [
        expenseId,
        ExpenseSyncState.rejected.dbValue,
        ?expectedPendingAt,
      ],
    );
    if (updated == 0) return false;
    await txn.update(
      OutboxDao.table,
      {'status': OutboxStatus.acked.dbValue},
      where: 'id IN (?, ?) AND status <> ?',
      whereArgs: [
        contentEntryId(expenseId),
        withdrawalEntryId(expenseId),
        OutboxStatus.acked.dbValue,
      ],
    );
    return true;
  });
}
