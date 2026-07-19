import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_notation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_row.dart';

/// Accès sqflite à la table de **référence** `ref_cours` (read-only côté métier :
/// jamais écrite par une action utilisateur, uniquement peuplée par le pull, par
/// classe). L'application d'un delta est un upsert par uuid
/// (`ConflictAlgorithm.replace`), sans garde `PENDING_SYNC`.
///
/// Lit aussi les ids de classes dans `ref_classrooms` (table du module Classe,
/// même base) : c'est la source d'itération du pull cours (option B — pull par
/// classe depuis les classes déjà rapatriées par le pull Classe).
class AcademicsRefLocalDataSource {
  final Database _db;

  const AcademicsRefLocalDataSource(this._db);

  static const String coursTable = 'ref_cours';
  static const String classroomsTable = 'ref_classrooms';
  static const String coursNotationTable = 'ref_cours_notation';

  /// Ids des classes d'une année (source d'itération du pull cours). Lit
  /// `ref_classrooms` peuplée par le module Classe ; liste vide si le pull
  /// Classe n'a pas encore eu lieu (le pull cours est alors un no-op propre).
  Future<List<String>> getClassroomIdsForYear(String academicYearId) async {
    final rows = await _db.query(
      classroomsTable,
      columns: ['id'],
      where: 'academic_year_id = ?',
      whereArgs: [academicYearId],
      orderBy: 'id ASC',
    );
    return rows.map((r) => r['id'] as String).toList(growable: false);
  }

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

  /// Cours d'une classe (résolution roster/barème).
  Future<List<RefCoursRow>> getCoursForClassroom(String classroomId) async {
    final rows = await _db.query(
      coursTable,
      where: 'classroom_id = ?',
      whereArgs: [classroomId],
    );
    return rows.map(RefCoursRow.fromMap).toList(growable: false);
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
}
