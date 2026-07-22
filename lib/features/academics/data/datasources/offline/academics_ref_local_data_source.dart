import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_notation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_row.dart';

/// Accès sqflite à la table de **référence** `ref_cours` (read-only côté métier :
/// jamais écrite par une action utilisateur, uniquement peuplée par le pull,
/// scopé enseignant — DF-K). L'application d'un delta est un upsert par uuid
/// (`ConflictAlgorithm.replace`), sans garde `PENDING_SYNC`.
class AcademicsRefLocalDataSource {
  final Database _db;

  const AcademicsRefLocalDataSource(this._db);

  static const String coursTable = 'ref_cours';
  static const String coursNotationTable = 'ref_cours_notation';

  Future<int> applyPulledCours(List<RefCoursRow> rows) async {
    var applied = 0;
    await applyInBatches<RefCoursRow>(
      _db,
      rows,
      apply: (txn, chunk) async {
        for (final row in chunk) {
          await txn.insert(
            coursTable,
            row.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          applied++;
        }
      },
    );
    return applied;
  }

  /// Un cours par son id (résolution cours → classe pour le roster de notation).
  Future<RefCoursRow?> getCours(String coursId) async {
    final rows = await _db.query(
      coursTable,
      where: 'id = ?',
      whereArgs: [coursId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RefCoursRow.fromMap(rows.first);
  }

  /// Tous les cours en base (source d'itération du pull evaluations/notes NF-4).
  Future<List<RefCoursRow>> getAllCours() async {
    final rows = await _db.query(coursTable);
    return rows.map(RefCoursRow.fromMap).toList(growable: false);
  }

  // ── Squelette de notation (cache réf du détail cours) ───────────────────────

  /// Met en cache (upsert par `cours_id`) le squelette de notation d'un cours.
  Future<void> upsertCoursNotation(RefCoursNotationRow row) async {
    await _db.insert(
      coursNotationTable,
      row.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Squelette de notation caché d'un cours (null si jamais pullé).
  Future<RefCoursNotationRow?> getCoursNotation(String coursId) async {
    final rows = await _db.query(
      coursNotationTable,
      where: 'cours_id = ?',
      whereArgs: [coursId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RefCoursNotationRow.fromMap(rows.first);
  }

  // ── Réconciliation (DF-L) — cours perdu (réaffectation prof) ────────────────

  /// Évince un cours (référence + squelette de notation en cache). Le contenu
  /// d'écriture rattaché (`evaluation`/`note_evaluation`) est purgé séparément
  /// par `AcademicsLocalDataSource.evictCoursData` — les deux DAO possèdent
  /// chacune leurs propres tables.
  Future<void> evictCours(String coursId) async {
    await _db.transaction((txn) async {
      await txn.delete(
        coursNotationTable,
        where: 'cours_id = ?',
        whereArgs: [coursId],
      );
      await txn.delete(coursTable, where: 'id = ?', whereArgs: [coursId]);
    });
  }

  /// Évince les cours locaux **absents** de [keepIds] — le pull `cours`
  /// (désormais scopé enseignant, DF-K) fait foi de « mes cours » sur un cycle
  /// bootstrap complet. Le delta additif ne signale jamais un retrait
  /// (réaffectation à un autre prof) : c'est cette diff explicite qui le fait.
  /// Renvoie les ids évincés (pour cascade côté [AcademicsLocalDataSource]).
  Future<List<String>> evictCoursNotIn(Set<String> keepIds) async {
    final rows = await _db.query(coursTable, columns: ['id']);
    final staleIds = rows
        .map((r) => r['id'] as String)
        .where((id) => !keepIds.contains(id))
        .toList(growable: false);
    for (final id in staleIds) {
      await evictCours(id);
    }
    return staleIds;
  }
}
