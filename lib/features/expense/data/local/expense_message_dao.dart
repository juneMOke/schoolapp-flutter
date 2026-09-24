import 'package:school_app_flutter/features/expense/data/local/expense_message_local_model.dart';
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
}
