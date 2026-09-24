import 'package:school_app_flutter/features/expense/data/local/expense_delta_columns.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_write_dao.dart';
import 'package:school_app_flutter/features/expense/data/sync/expense_sync_models.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce que le serveur dit d'une dépense, appliqué au registre local — par
/// l'accusé d'une remontée ou par le pull.
///
/// ## La règle qui protège la saisie
///
/// **Une écriture locale plus récente n'est jamais écrasée.** Deux cas :
///
/// - le **contenu** : une ligne en attente (ou refusée) garde le sien ; seuls
///   les champs que le serveur attribue (numéro, agent, version, curseur) sont
///   posés. Pour un accusé, « plus récente » se juge contre ce qui a été
///   ENVOYÉ, pas contre l'horloge renvoyée : le serveur borne une horloge en
///   avance, et comparer à sa valeur ferait croire à une saisie en attente qui
///   n'existe pas — la ligne resterait « en attente » pour toujours.
/// - le **retrait** : tant que `withdrawal_pending_at` est posé, ni le pull ni
///   l'accusé d'un contenu ne touchent `deleted_at`. Ce que le serveur en dit
///   est gardé à part (`server_deleted_at`) : c'est l'état auquel revient un
///   geste refusé.
///
/// Les deux familles de colonnes vivent dans [ExpenseDeltaColumns].
class ExpenseSyncDao {
  final Database _db;

  const ExpenseSyncDao(this._db);

  static const String table = 'expenses';

  static const _same = ExpenseDeltaColumns.sameInstant;

  /// Accusé d'une remontée de contenu ([sentClientUpdatedAt] = l'horloge de
  /// l'état envoyé, [authorId] = son auteur).
  ///
  /// Cas limite : une dépense jamais acceptée, retirée **sur le poste seul**
  /// pendant que ce contenu était en vol
  /// ([ExpenseWriteDao.setLocalOnlyWithdrawal]). Le serveur vient de la
  /// créer sans rien savoir du retrait : le retrait garde la main et part à
  /// son tour — l'accusé ne ressuscite pas la ligne.
  Future<void> applyContentAck(
    ExpenseDeltaDto canonical, {
    required String sentClientUpdatedAt,
    required String schoolId,
    required int nowMs,
    String? authorId,
  }) => _db.transaction((txn) async {
    final row = await ExpenseReadDao(txn).find(canonical.id);
    if (row == null) {
      await _insert(txn, canonical, schoolId: schoolId, nowMs: nowMs);
      return;
    }
    final latest = _same(row.clientUpdatedAt, sentClientUpdatedAt);
    final orphanWithdrawal =
        row.expenseNumber == null &&
        row.deletedAt != null &&
        row.withdrawalPendingAt == null &&
        canonical.deletedAt == null;
    await txn.update(
      table,
      {
        ...ExpenseDeltaColumns.server(canonical),
        if (latest) ...ExpenseDeltaColumns.content(canonical),
        if (latest) ...ExpenseDeltaColumns.synced,
        if (row.withdrawalPendingAt == null && !orphanWithdrawal)
          'deleted_at': canonical.deletedAt,
        if (orphanWithdrawal) 'withdrawal_pending_at': row.deletedAt,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [canonical.id],
    );
    if (orphanWithdrawal) {
      await ExpenseWriteDao.enqueueWithdrawal(
        txn,
        ExpenseWithdrawalPayload(
          expenseId: canonical.id,
          deleted: true,
          changedAt: row.deletedAt!,
          authorId: authorId,
        ),
        schoolId: row.schoolId.isEmpty ? schoolId : row.schoolId,
        nowMs: nowMs,
      );
    }
  });

  /// Accusé d'un retrait ou d'une restauration.
  Future<void> applyWithdrawalAck(
    ExpenseDeltaDto canonical, {
    required String sentChangedAt,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final row = await ExpenseReadDao(txn).find(canonical.id);
    if (row == null) return;
    // Un geste plus récent attend encore : il décidera du retrait.
    final latest = _same(row.withdrawalPendingAt, sentChangedAt);
    await txn.update(
      table,
      {
        ...ExpenseDeltaColumns.server(canonical),
        if (latest) 'deleted_at': canonical.deletedAt,
        if (latest) 'withdrawal_pending_at': null,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [canonical.id],
    );
  });

  /// Accusé d'un **geste du circuit** : la ligne se range sur l'état
  /// canonique, fil compris.
  ///
  /// Seule la famille **serveur** est posée — jamais le contenu : un geste ne
  /// dit rien de l'intitulé ni du montant, et les réécrire depuis son accusé
  /// effacerait une correction saisie entre-temps. L'état de synchro du
  /// CONTENU n'est pas touché non plus : le geste voyage seul.
  Future<void> applyGestureAck(
    ExpenseDeltaDto canonical, {
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final updated = await txn.update(
      table,
      {...ExpenseDeltaColumns.server(canonical), 'updated_at': nowMs},
      where: 'id = ?',
      whereArgs: [canonical.id],
    );
    // Le serveur connaît une demande que ce poste ignore : c'est au pull de
    // la poser, pas à l'accusé d'un geste d'en inventer la moitié.
    if (updated == 0) return;
    await _applyThread(txn, canonical, schoolId: schoolId);
  });

  /// Refus terminal d'un geste : la ligne porte son motif (A4).
  ///
  /// À la différence du contenu, **aucune horloge à comparer** : un geste ne
  /// s'écrase pas, il s'ajoute — et celui qu'on vient de refuser est bien
  /// celui qui vient d'être tenté.
  Future<void> markGestureRejected(
    String expenseId, {
    required String? code,
    required String reason,
    required int nowMs,
  }) => _db.update(
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

  /// Refus terminal d'un contenu : la ligne porte son motif (A4).
  ///
  /// Rend `false` — et ne touche à rien — quand une saisie plus récente a
  /// remplacé celle qui a été refusée : c'est elle qu'il faut juger.
  Future<bool> markRejected(
    String expenseId, {
    required String sentClientUpdatedAt,
    required String? code,
    required String reason,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final row = await ExpenseReadDao(txn).find(expenseId);
    if (row == null) return true;
    if (!_same(row.clientUpdatedAt, sentClientUpdatedAt)) return false;
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
    return true;
  });

  /// Refus terminal d'un retrait (droit retiré entre-temps…) : le registre
  /// revient à ce que le **serveur** sait (`server_deleted_at`), pour dire
  /// vrai — pas à un état deviné depuis le geste refusé.
  ///
  /// Rend `false` — et ne touche à rien — quand le geste envoyé n'est plus
  /// celui qui attend : un geste plus récent décidera.
  Future<bool> revertWithdrawal(
    String expenseId, {
    required String sentChangedAt,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final row = await ExpenseReadDao(txn).find(expenseId);
    if (row == null) return true;
    if (!_same(row.withdrawalPendingAt, sentChangedAt)) return false;
    await txn.update(
      table,
      {
        'deleted_at': row.serverDeletedAt,
        'withdrawal_pending_at': null,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [expenseId],
    );
    return true;
  });

  /// Le serveur ne connaît pas la dépense (404) : le geste n'a plus d'objet.
  /// L'attente se lève pour rendre la main au pull et au registre des
  /// disparitions ; le retrait local, lui, reste tel que l'agent l'a voulu.
  Future<void> releaseWithdrawal(
    String expenseId, {
    required String sentChangedAt,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final row = await ExpenseReadDao(txn).find(expenseId);
    if (row == null) return;
    if (!_same(row.withdrawalPendingAt, sentChangedAt)) return;
    await txn.update(
      table,
      {'withdrawal_pending_at': null, 'updated_at': nowMs},
      where: 'id = ?',
      whereArgs: [expenseId],
    );
  });

  /// La dépense n'existe plus côté serveur (410) : la ligne s'efface.
  Future<void> deleteExpense(String expenseId) =>
      _db.delete(table, where: 'id = ?', whereArgs: [expenseId]);

  /// Le pull : insère l'inconnu, remplace le synchronisé, ne pose que les
  /// champs serveur sur une ligne en attente ou refusée. Rend le nombre de
  /// lignes écrites.
  Future<int> applyPulled(
    List<ExpenseDeltaDto> deltas, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (deltas.isEmpty) return 0;
    return _db.transaction((txn) async {
      final reader = ExpenseReadDao(txn);
      for (final delta in deltas) {
        final row = await reader.find(delta.id);
        if (row == null) {
          await _insert(txn, delta, schoolId: schoolId, nowMs: nowMs);
          await _applyThread(txn, delta, schoolId: schoolId);
          continue;
        }
        final synced = row.syncStatus == ExpenseSyncState.synced.dbValue;
        await txn.update(
          table,
          {
            ...ExpenseDeltaColumns.server(delta),
            if (synced) ...ExpenseDeltaColumns.content(delta),
            if (row.withdrawalPendingAt == null) 'deleted_at': delta.deletedAt,
            'updated_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [delta.id],
        );
        await _applyThread(txn, delta, schoolId: schoolId);
      }
      return deltas.length;
    });
  }

  /// Le fil descend **entier** avec sa demande, dans la même transaction :
  /// une demande sans son fil laisserait l'écran annoncer des messages qu'il
  /// ne sait pas montrer.
  ///
  /// La fraîcheur, elle, ne se pose que si elle avance — un geste écrit ici
  /// et pas encore poussé est plus récent que ce que le serveur connaît.
  static Future<void> _applyThread(
    DatabaseExecutor txn,
    ExpenseDeltaDto delta, {
    required String schoolId,
  }) async {
    await ExpenseMessageDao.applyPulledIn(txn, [
      for (final message in delta.messages)
        ExpenseMessageLocalModel.fromDelta(
          message,
          schoolId: schoolId,
          expenseId: delta.id,
        ),
    ], expenseId: delta.id);
    await ExpenseMessageDao.bumpLastMessageAtIn(
      txn,
      delta.id,
      delta.lastMessageAt,
    );
  }

  static Future<void> _insert(
    DatabaseExecutor txn,
    ExpenseDeltaDto delta, {
    required String schoolId,
    required int nowMs,
  }) => txn.insert(
    table,
    ExpenseDeltaColumns.newRow(delta, schoolId: schoolId, nowMs: nowMs),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
