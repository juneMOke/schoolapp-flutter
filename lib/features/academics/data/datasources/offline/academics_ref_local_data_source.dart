import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/grades_referential_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/grades_referential_rows.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_row.dart';

/// Accès sqflite à la table de **référence** `ref_cours` (read-only côté métier :
/// jamais écrite par une action utilisateur, uniquement peuplée par le pull,
/// scopé enseignant — DF-K). L'application d'un delta est un upsert par uuid
/// (`ConflictAlgorithm.replace`), sans garde `PENDING_SYNC`.
class AcademicsRefLocalDataSource {
  final Database _db;

  const AcademicsRefLocalDataSource(this._db);

  static const String coursTable = 'ref_cours';
  static const String brancheTable = 'ref_branche';
  static const String ligneBaremeTable = 'ref_ligne_bareme';
  static const String chapitreTable = 'ref_chapitre';
  static const String periodeTable = 'ref_periode';
  static const String sousPeriodeTable = 'ref_sous_periode';

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

  /// « Mes cours » (guide fonctionnel §4) : jointure `ref_cours` → `ref_ligne_
  /// bareme` → `ref_branche`, triée par classe puis par ordre du barème. Un
  /// cours dont la ligne de barème/branche n'est pas (encore) en cache est
  /// exclu par le `JOIN` (classe masquée). Aucun filtre d'identité : `ref_cours`
  /// n'accueille déjà que les cours de l'enseignant connecté (pull teacher-
  /// scopé, DF-K).
  Future<List<Map<String, Object?>>> getMyCoursesJoined() => _db.rawQuery('''
    SELECT co.classroom_id AS classroom_id,
           co.id AS cours_id,
           b.nom AS branche_nom
    FROM $coursTable co
    JOIN $ligneBaremeTable lb ON lb.id = co.ligne_bareme_id
    JOIN $brancheTable b ON b.id = lb.branche_id
    ORDER BY co.classroom_id, lb.ordre
  ''');

  // ── Bundle `grades-referential` (ETag, remplacement d'ensemble) ─────────────

  /// Remplace intégralement les 5 tables du bundle en 1 transaction (pas de
  /// delta : le contrat livre l'ensemble à chaque `200`). Un bundle vide (aucun
  /// cours pour ce prof) purge légitimement le cache local.
  Future<void> replaceGradesReferential(GradesReferentialBundleDto bundle) {
    return _db.transaction((txn) async {
      final batch = txn.batch();
      batch.delete(brancheTable);
      batch.delete(ligneBaremeTable);
      batch.delete(chapitreTable);
      batch.delete(periodeTable);
      batch.delete(sousPeriodeTable);
      for (final b in bundle.branches) {
        batch.insert(
          brancheTable,
          b.toLocalRow().toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final lb in bundle.ligneBaremes) {
        batch.insert(
          ligneBaremeTable,
          lb.toLocalRow().toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final c in bundle.chapitres) {
        batch.insert(
          chapitreTable,
          c.toLocalRow().toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final p in bundle.periodes) {
        batch.insert(
          periodeTable,
          p.toLocalRow().toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final sp in bundle.sousPeriodes) {
        batch.insert(
          sousPeriodeTable,
          sp.toLocalRow().toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  // ── Lecture du bundle (composition du détail cours, MAJ-4) ──────────────────

  /// Ligne de barème par id (`null` si le bundle n'a pas encore cette ligne).
  Future<RefLigneBaremeRow?> getLigneBareme(String id) async {
    final rows = await _db.query(
      ligneBaremeTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RefLigneBaremeRow.fromMap(rows.first);
  }

  /// Branche par id (`null` si le bundle n'a pas encore cette branche).
  Future<RefBrancheRow?> getBranche(String id) async {
    final rows = await _db.query(
      brancheTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RefBrancheRow.fromMap(rows.first);
  }

  /// Chapitres d'un cours, triés par `ordre`.
  Future<List<RefChapitreRow>> getChapitresForCours(String coursId) async {
    final rows = await _db.query(
      chapitreTable,
      where: 'cours_id = ?',
      whereArgs: [coursId],
      orderBy: 'ordre ASC',
    );
    return rows.map(RefChapitreRow.fromMap).toList(growable: false);
  }

  /// Périodes scolaires d'une portée année × groupe de niveau, triées par
  /// `ordre` — remplace le squelette `ref_cours_notation` comme source du
  /// statut de clôture.
  Future<List<RefPeriodeRow>> getPeriodesForGroup(
    String academicYearId,
    String schoolLevelGroupId,
  ) async {
    final rows = await _db.query(
      periodeTable,
      where: 'academic_year_id = ? AND school_level_group_id = ?',
      whereArgs: [academicYearId, schoolLevelGroupId],
      orderBy: 'ordre ASC',
    );
    return rows.map(RefPeriodeRow.fromMap).toList(growable: false);
  }

  /// Sous-périodes des périodes données, triées par `ordre` (regroupement par
  /// `periodeScolaireId` laissé à l'appelant).
  Future<List<RefSousPeriodeRow>> getSousPeriodesForPeriodes(
    List<String> periodeIds,
  ) async {
    if (periodeIds.isEmpty) return const [];
    final placeholders = List.filled(periodeIds.length, '?').join(',');
    final rows = await _db.query(
      sousPeriodeTable,
      where: 'periode_scolaire_id IN ($placeholders)',
      whereArgs: periodeIds,
      orderBy: 'ordre ASC',
    );
    return rows.map(RefSousPeriodeRow.fromMap).toList(growable: false);
  }

  // ── Réconciliation (DF-L) — cours perdu (réaffectation prof) ────────────────

  /// Évince un cours (référence). Le contenu d'écriture rattaché
  /// (`evaluation`/`note_evaluation`) est purgé séparément par
  /// `AcademicsLocalDataSource.evictCoursData` — les deux DAO possèdent chacune
  /// leurs propres tables.
  Future<void> evictCours(String coursId) async {
    await _db.delete(coursTable, where: 'id = ?', whereArgs: [coursId]);
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
