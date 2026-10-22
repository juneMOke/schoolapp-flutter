import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/depot/depot_copie_row.dart';
import 'package:school_app_flutter/features/academics/domain/entities/depot/depot_copie.dart';

/// Les copies déposées par les parents (`evaluation_depot`), miroir pur du
/// champ `depots` des évaluations.
class EvaluationDepotLocalDataSource {
  final Database _db;

  const EvaluationDepotLocalDataSource(this._db);

  static const String table = 'evaluation_depot';

  Future<List<DepotCopie>> depotsOf(String evaluationId) async {
    final rows = await _db.query(
      table,
      where: 'evaluation_id = ?',
      whereArgs: [evaluationId],
    );
    return rows.map(DepotCopieRow.fromMap).toList();
  }

  /// Remplace les copies de l'évaluation par [depots], la liste du serveur —
  /// une copie remplacée par le parent, ou retirée, disparaît ici aussi.
  Future<void> replaceForEvaluation(
    DatabaseExecutor txn, {
    required String evaluationId,
    required List<DepotCopie> depots,
  }) async {
    await txn.delete(
      table,
      where: 'evaluation_id = ?',
      whereArgs: [evaluationId],
    );
    for (final depot in depots) {
      await txn.insert(
        table,
        DepotCopieRow.toMap(evaluationId, depot),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
