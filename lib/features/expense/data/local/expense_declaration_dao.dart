import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_delta_columns.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_delta_dto.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// L'écriture d'une **déclaration** (v3) et le règlement de son envoi.
///
/// À part de `ExpenseWriteDao` et `ExpenseSyncDao` : une déclaration n'est
/// ni un contenu qu'on réécrit (elle naît payée, donc verrouillée) ni un
/// geste sur une demande existante. Elle a sa propre entrée d'outbox, et
/// elle seule (F37).
class ExpenseDeclarationDao {
  final Database _db;

  const ExpenseDeclarationDao(this._db);

  static const String table = 'expenses';

  static const String aggregateType = 'EXPENSE_DECLARATION';

  static String entryId(String expenseId) => '$aggregateType:$expenseId';

  /// Écrit la ligne, ses messages et son entrée d'outbox **dans une seule
  /// transaction** (F38) : une déclaration sans entrée ne partirait jamais,
  /// une entrée sans ligne pousserait un argent que la base ne montre pas.
  ///
  /// [replacing] : la déclaration refusée que celle-ci régularise (F45). Elle
  /// quitte le registre dans la même transaction — jamais les deux à la fois
  /// dans les totaux. Rien ne remonte pour elle : le serveur ne l'a jamais
  /// connue.
  Future<void> insert({
    required ExpenseLocalModel row,
    required List<ExpenseMessageLocalModel> messages,
    required OutboxEntry entry,
    String? replacing,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await txn.insert(table, row.toMap());
    for (final message in messages) {
      await txn.insert(ExpenseMessageDao.table, message.toMap());
    }
    await ExpenseMessageDao.bumpLastMessageAtIn(
      txn,
      row.id,
      messages.isEmpty ? null : messages.last.createdAt,
    );
    await OutboxDao(txn).enqueue(entry);
    if (replacing != null) await _abandon(txn, replacing, nowMs: nowMs);
  });

  /// L'accusé d'une déclaration — `APPLIED` comme `SUPERSEDED` (Q2).
  ///
  /// Les messages que le poste avait écrits d'avance (`DECLARATION`, et le
  /// `VISA` d'office) sont réglés **avant** que le fil serveur ne descende :
  /// présents dans l'accusé, ils sont accusés ; absents, c'est qu'un premier
  /// envoi en portait d'autres, et ce sont ceux du serveur qui font foi.
  Future<void> applyAck(
    ExpenseDeltaDto canonical, {
    required Set<String> localMessageIds,
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final served = {for (final message in canonical.messages) message.id};
    for (final id in localMessageIds) {
      if (served.contains(id)) {
        await txn.update(
          ExpenseMessageDao.table,
          {'sync_status': ExpenseSyncState.synced.dbValue},
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await txn.delete(
          ExpenseMessageDao.table,
          where: 'id = ? AND sync_status = ?',
          whereArgs: [id, ExpenseSyncState.pending.dbValue],
        );
      }
    }
    final row = await ExpenseReadDao(txn).find(canonical.id);
    if (row == null) {
      await txn.insert(
        table,
        ExpenseDeltaColumns.newRow(canonical, schoolId: schoolId, nowMs: nowMs),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // Le contenu d'une déclaration est verrouillé dès sa naissance : celui
      // que le serveur a retenu est le seul, et il remplace le nôtre.
      await txn.update(
        table,
        {
          ...ExpenseDeltaColumns.server(canonical),
          ...ExpenseDeltaColumns.content(canonical),
          ...ExpenseDeltaColumns.synced,
          if (row.withdrawalPendingAt == null)
            'deleted_at': canonical.deletedAt,
          'updated_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [canonical.id],
      );
    }
    await ExpenseMessageDao.applyPulledIn(txn, [
      for (final message in canonical.messages)
        ExpenseMessageLocalModel.fromDelta(
          message,
          schoolId: schoolId,
          expenseId: canonical.id,
        ),
    ], expenseId: canonical.id);
    await ExpenseMessageDao.bumpLastMessageAtIn(
      txn,
      canonical.id,
      canonical.lastMessageAt,
    );
  });

  /// Un refus **terminal** : l'argent est sorti, le serveur n'en sait rien.
  /// La ligne n'est jamais effacée (F45) ; elle passe « à régulariser » avec
  /// son motif, et toute la suite de son fil meurt avec elle.
  Future<void> markRefused(
    String expenseId, {
    required String? code,
    required String reason,
    required int nowMs,
  }) => _db.transaction((txn) async {
    await txn.update(
      table,
      {
        'sync_status': ExpenseSyncState.rejected.dbValue,
        'sync_error': reason,
        'sync_error_code': code,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [expenseId],
    );
    await txn.update(
      ExpenseMessageDao.table,
      {'sync_status': ExpenseSyncState.rejected.dbValue},
      // Tout le fil en attente : la déclaration en est la première marche.
      where: 'expense_id = ? AND sync_status = ?',
      whereArgs: [expenseId, ExpenseSyncState.pending.dbValue],
    );
  });

  /// Retire du registre, sur le poste seul, une déclaration refusée que l'on
  /// régularise, et neutralise ce qui pourrait encore partir pour elle.
  static Future<void> _abandon(
    DatabaseExecutor txn,
    String expenseId, {
    required int nowMs,
  }) async {
    final updated = await txn.update(
      table,
      {
        'deleted_at': DateTime.fromMillisecondsSinceEpoch(
          nowMs,
          isUtc: true,
        ).toIso8601String(),
        'updated_at': nowMs,
      },
      where:
          'id = ? AND expense_number IS NULL AND sync_status = ? '
          'AND deleted_at IS NULL',
      whereArgs: [expenseId, ExpenseSyncState.rejected.dbValue],
    );
    // La refusée n'est plus à régulariser — accusée entre-temps (relancée
    // depuis la feuille des erreurs), ou déjà remplacée par un premier envoi
    // du même formulaire. Écrire la nouvelle compterait deux fois le même
    // argent : la transaction entière est défaite.
    if (updated == 0) throw const ExpenseRedeclarationStale();
    await txn.update(
      OutboxDao.table,
      {'status': OutboxStatus.acked.dbValue},
      where:
          '(id = ? OR (aggregate_type = ? AND aggregate_id = ?)) '
          'AND status <> ?',
      whereArgs: [
        entryId(expenseId),
        ExpenseWriteDao.gestureAggregateType,
        expenseId,
        OutboxStatus.acked.dbValue,
      ],
    );
  }
}

/// La déclaration à remplacer n'est plus à régulariser : rien n'est écrit.
class ExpenseRedeclarationStale implements Exception {
  const ExpenseRedeclarationStale();
}
