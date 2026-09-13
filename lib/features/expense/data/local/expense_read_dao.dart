import 'package:school_app_flutter/features/expense/data/local/expense_local_model.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Lectures du registre local. Aucune écriture ici.
class ExpenseReadDao {
  final DatabaseExecutor _db;

  const ExpenseReadDao(this._db);

  static const String table = 'expenses';

  /// Tout le registre de l'école, **retraits compris** : c'est le domaine qui
  /// les écarte de la vue, et un « Annuler » a besoin de la ligne retirée.
  ///
  /// Le registre tient en mémoire (la maquette génère ~370 dépenses par an ;
  /// même à 2 000, la liste reste petite) : aucune pagination SQL, tous les
  /// filtres et totaux se calculent en Dart sans aller-retour.
  Future<List<ExpenseLocalModel>> expensesForSchool(String schoolId) async {
    if (schoolId.isEmpty) return const [];
    final rows = await _db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      orderBy: 'expense_date DESC',
    );
    return rows.map(ExpenseLocalModel.fromMap).toList(growable: false);
  }

  Future<ExpenseLocalModel?> find(String id) async {
    final rows = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : ExpenseLocalModel.fromMap(rows.first);
  }
}
