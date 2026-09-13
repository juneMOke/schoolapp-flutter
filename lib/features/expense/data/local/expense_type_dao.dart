import 'package:school_app_flutter/core/expense/local/expense_type_local_model.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les types de dépense en local : écrits par le pull du socle, lus par le
/// module. Aucune écriture ne part d'ici vers le serveur (pas de configuration
/// des types en V1).
class ExpenseTypeDao {
  final Database _db;

  const ExpenseTypeDao(this._db);

  static const String table = 'ref_expense_types';

  /// Remplace les types **de cette école** : purge scopée puis insertion, en
  /// une transaction.
  ///
  /// ⚠️ Scopé par école, jamais globalement : sur une tablette partagée, une
  /// purge globale renommerait les dépenses de l'autre école en « type
  /// inconnu ». [schoolId] vide = appelant sans école résolue : on ne touche à
  /// rien.
  ///
  /// L'appelant ne transmet jamais une liste vide (le socle la dit alors non
  /// communiquée) : une section illisible ne doit pas effacer ce qui nomme le
  /// registre.
  Future<void> replaceForSchool(
    List<ExpenseTypeLocalModel> types, {
    required String schoolId,
  }) async {
    if (schoolId.isEmpty) return;
    await _db.transaction((txn) async {
      await txn.delete(table, where: 'school_id = ?', whereArgs: [schoolId]);
      final batch = txn.batch();
      for (final type in types) {
        if (!type.isUsable) continue;
        batch.insert(
          table,
          type.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Les types de l'école, **masqués compris**, dans l'ordre de l'école.
  Future<List<ExpenseTypeLocalModel>> typesForSchool(String schoolId) async {
    if (schoolId.isEmpty) return const [];
    final rows = await _db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      orderBy: 'sort_order ASC, code ASC',
    );
    return rows.map(ExpenseTypeLocalModel.fromMap).toList(growable: false);
  }
}
