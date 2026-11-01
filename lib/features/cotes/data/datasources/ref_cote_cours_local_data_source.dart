import 'package:school_app_flutter/features/cotes/data/models/cote_delta_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les cotes des cours d'un enseignant, en lecture seule : la tablette ne les
/// écrit jamais, elle les remplace à chaque page du flux.
class RefCoteCoursLocalDataSource {
  final Database _db;

  const RefCoteCoursLocalDataSource(this._db);

  static const String table = 'ref_cote_cours';

  Future<int> applyPulled(List<CoteDeltaDto> items) async {
    if (items.isEmpty) return 0;
    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in items) {
        batch.insert(table, {
          'id': item.id,
          'student_id': item.studentId,
          'cours_id': item.coursId,
          'colonne_id': item.colonneId,
          'examen': item.examen ? 1 : 0,
          'valeur': item.valeur,
          'updated_at': item.updatedAtMs,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
    return items.length;
  }

  /// Colonne → élève → cote. Une cote vidée n'y figure pas : la colonne de cet
  /// élève revient à sa moyenne.
  Future<Map<String, Map<String, double>>> readForCours(String coursId) async {
    final rows = await _db.query(
      table,
      where: 'cours_id = ? AND valeur IS NOT NULL',
      whereArgs: [coursId],
    );
    final byColumn = <String, Map<String, double>>{};
    for (final row in rows) {
      (byColumn[row['colonne_id'] as String] ??= {})[row['student_id']
          as String] = (row['valeur'] as num)
          .toDouble();
    }
    return byColumn;
  }

  Future<void> evictCours(String coursId) =>
      _db.delete(table, where: 'cours_id = ?', whereArgs: [coursId]);
}
