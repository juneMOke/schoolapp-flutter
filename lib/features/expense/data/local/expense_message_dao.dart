import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_message_local_model.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le fil d'une demande : lecture chronologique, et un ajout **atomique**.
///
/// C'est le patron du fil de la Discipline, moins son défaut. Là-bas, ajouter
/// un commentaire repasse le cas en attente de synchro et bumpe son horloge,
/// parce que le commentaire voyage dans la poussée du parent. Ici le message
/// voyage **seul** (Q1) : toucher au contenu de la dépense le repousserait
/// pour rien, et surtout ferait perdre une décision à l'arbitrage — c'est
/// pourquoi seule `last_message_at` bouge.
class ExpenseMessageDao {
  final Database _db;

  const ExpenseMessageDao(this._db);

  static const String table = 'expense_messages';
  static const String expensesTable = 'expenses';

  /// Le fil, du plus ancien au plus récent.
  ///
  /// L'identifiant départage deux messages écrits sur la même horloge : sans
  /// lui, l'ordre d'affichage dépendrait du plan d'exécution de SQLite.
  ///
  /// Scopé par école comme toute lecture du module : la base héritée est
  /// partagée entre les écoles d'un même poste, et un fil n'a pas à traverser
  /// cette frontière — même si les identifiants sont des uuid.
  Future<List<ExpenseMessageLocalModel>> threadFor(
    String expenseId, {
    required String schoolId,
  }) async {
    final rows = await _db.query(
      table,
      where: 'expense_id = ? AND school_id = ?',
      whereArgs: [expenseId, schoolId],
      orderBy: 'created_at, id',
    );
    return rows.map(ExpenseMessageLocalModel.fromMap).toList(growable: false);
  }

  /// Ajoute un message et remonte la fraîcheur du fil, dans une seule
  /// transaction : un message sans fraîcheur laisserait la liste muette, une
  /// fraîcheur sans message annoncerait un fil vide.
  ///
  /// **Append-only, et idempotent par l'uuid** : réécrire le même message est
  /// inerte, ce qui est exactement ce qu'on veut d'un geste rejoué (Q3).
  ///
  /// La fraîcheur ne **recule jamais** : un message plus ancien appliqué après
  /// un plus récent — l'ordre que le pull ne promet pas — ne doit pas faire
  /// croire la demande plus calme qu'elle n'est. La comparaison est textuelle,
  /// ce que l'ISO-8601 UTC autorise, et c'est la raison pour laquelle la
  /// colonne n'accepte qu'une seule forme.
  Future<void> append(ExpenseMessageLocalModel message) async {
    await _db.transaction((txn) async {
      await txn.insert(
        table,
        message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        expensesTable,
        {'last_message_at': message.createdAt},
        where: 'id = ? AND (last_message_at IS NULL OR last_message_at < ?)',
        whereArgs: [message.expenseId, message.createdAt],
      );
    });
  }

  /// Applique un **geste du circuit** : la demande bouge et son fil s'allonge,
  /// dans la même transaction. L'un sans l'autre serait un mensonge — une
  /// décision sans trace, ou une trace sans décision.
  ///
  /// **Inerte au rejeu, par l'uuid du message** — la même clé d'idempotence
  /// que le serveur (Q3). Rend `false` sans rien écrire quand le message
  /// existe déjà : c'est ce qui garantit qu'une relance rejouée ne compte
  /// jamais double, là où [append] écrase délibérément (il sert le pull, dont
  /// le rôle est justement de réaligner).
  ///
  /// [columns] ne porte que ce que le geste réécrit
  /// (`ExpenseGestureColumns`) ; il est vide pour un commentaire ou une
  /// relance, qui ne déplacent pas la demande.
  Future<bool> appendGesture(
    ExpenseMessageLocalModel message, {
    Map<String, Object?> columns = const {},
    bool bumpsReminder = false,
    OutboxEntry? entry,
  }) => _db.transaction((txn) async {
    final existing = await txn.query(
      table,
      columns: const ['id'],
      where: 'id = ?',
      whereArgs: [message.id],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;
    await txn.insert(table, message.toMap());
    // L'entrée de file entre ICI, dans la même transaction : un geste sans
    // entrée ne partirait jamais, une entrée sans geste pousserait un fait
    // que la base ne porte pas.
    if (entry != null) await OutboxDao(txn).enqueue(entry);
    if (columns.isNotEmpty) {
      await txn.update(
        expensesTable,
        columns,
        where: 'id = ?',
        whereArgs: [message.expenseId],
      );
    }
    // Lu et réécrit dans la transaction : deux relances simultanées comptent
    // deux, jamais une. Une carte de colonnes ne sait pas dire « + 1 ».
    if (bumpsReminder) {
      await txn.rawUpdate(
        'UPDATE $expensesTable SET reminder_count = reminder_count + 1 '
        'WHERE id = ?',
        [message.expenseId],
      );
    }
    await txn.update(
      expensesTable,
      {'last_message_at': message.createdAt},
      where: 'id = ? AND (last_message_at IS NULL OR last_message_at < ?)',
      whereArgs: [message.expenseId, message.createdAt],
    );
    return true;
  });

  /// Applique le fil descendu par le pull.
  ///
  /// **Un message encore `PENDING_SYNC` est SAUTÉ.** Le poste l'a écrit, la
  /// file ne l'a pas encore poussé : le réécrire depuis une page serveur qui
  /// l'ignore l'effacerait, et le marquer accusé mentirait. C'est l'accusé du
  /// geste qui le réglera.
  ///
  /// Rend le nombre de messages réellement écrits.
  Future<int> applyPulled(
    List<ExpenseMessageLocalModel> messages, {
    required String expenseId,
  }) => _db.transaction(
    (txn) => applyPulledIn(txn, messages, expenseId: expenseId),
  );

  /// Le même geste, **dans la transaction de l'appelant** — c'est ainsi que
  /// le pull écrit une demande et son fil sans jamais laisser l'une sans
  /// l'autre.
  static Future<int> applyPulledIn(
    DatabaseExecutor txn,
    List<ExpenseMessageLocalModel> messages, {
    required String expenseId,
  }) async {
    if (messages.isEmpty) return 0;
    final pending = <String>{
      for (final row in await txn.query(
        table,
        columns: const ['id'],
        where: 'expense_id = ? AND sync_status = ?',
        whereArgs: [expenseId, ExpenseSyncState.pending.dbValue],
      ))
        row['id'] as String,
    };
    var written = 0;
    for (final message in messages) {
      if (pending.contains(message.id)) continue;
      await txn.insert(
        table,
        message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      written++;
    }
    return written;
  }

  /// Remonte la fraîcheur du fil — **jamais en arrière**.
  ///
  /// Comparaison textuelle d'ISO-8601 UTC, ce que la forme unique imposée par
  /// [ExpenseMessageLocalModel.at] autorise.
  static Future<void> bumpLastMessageAtIn(
    DatabaseExecutor txn,
    String expenseId,
    String? at,
  ) async {
    if (at == null) return;
    await txn.update(
      expensesTable,
      {'last_message_at': at},
      where: 'id = ? AND (last_message_at IS NULL OR last_message_at < ?)',
      whereArgs: [expenseId, at],
    );
  }

  /// Le **plus ancien message encore en attente** d'une demande — le
  /// registre d'ordre de F31.
  ///
  /// C'est le fil qui ordonne les gestes, et rien d'autre : le moteur
  /// d'outbox ne lit jamais `aggregate_id`, poursuit après un `retry`, et son
  /// backoff retire une entrée de la course pendant 1 à 256 s. Tout ordre est
  /// à la charge du handler.
  ///
  /// ⚠️ **En attente seulement, jamais « non accusé ».** Un message mort
  /// (`SYNC_ERROR`) reste dans le fil — il est append-only — mais il ne barre
  /// plus la route : sinon le premier geste refusé condamnerait la demande
  /// pour toujours, y compris le geste neuf par lequel l'agent vient réparer.
  ///
  /// L'index `(expense_id, created_at)` sert cette lecture autant que
  /// l'affichage du fil.
  Future<String?> oldestPendingId(String expenseId) async {
    final rows = await _db.query(
      table,
      columns: const ['id'],
      where: 'expense_id = ? AND sync_status = ?',
      whereArgs: [expenseId, ExpenseSyncState.pending.dbValue],
      orderBy: 'created_at, id',
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['id'] as String;
  }

  /// L'état de remontée d'un message, ou `null` s'il n'existe plus.
  Future<ExpenseSyncState?> stateOf(String messageId) async {
    final rows = await _db.query(
      table,
      columns: const ['sync_status'],
      where: 'id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ExpenseSyncState.fromDb(rows.single['sync_status'] as String?);
  }

  /// **L'échappatoire de la garde d'ordre** : un geste meurt, et toute la
  /// suite qu'il portait meurt avec lui.
  ///
  /// Marque en erreur le message d'horloge [fromCreatedAt] **et tous les
  /// suivants encore en attente** sur la même demande. Une séquence dont la
  /// première marche a cédé est incohérente — payer une demande dont
  /// l'approbation a été refusée n'a aucun sens —, et sans cela `blocked`,
  /// qui ne consomme aucune tentative et ne s'empoisonne jamais, les gèlerait
  /// pour toujours.
  ///
  /// Rend le nombre de messages condamnés.
  Future<int> rejectFrom(String expenseId, {required String fromCreatedAt}) =>
      _db.update(
        table,
        {'sync_status': ExpenseSyncState.rejected.dbValue},
        where: 'expense_id = ? AND created_at >= ? AND sync_status = ?',
        whereArgs: [expenseId, fromCreatedAt, ExpenseSyncState.pending.dbValue],
      );

  /// Marque l'issue d'un message poussé.
  Future<void> markMessage(String messageId, ExpenseSyncState state) =>
      _db.update(
        table,
        {'sync_status': state.dbValue},
        where: 'id = ?',
        whereArgs: [messageId],
      );
}
