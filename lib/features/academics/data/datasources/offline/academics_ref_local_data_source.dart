import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/owner_scope.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/grades_referential_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/grades_referential_rows.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/ref_cours_row.dart';

/// Accès sqflite à la table de **référence** `ref_cours` (read-only côté métier :
/// jamais écrite par une action utilisateur, uniquement peuplée par le pull,
/// scopé enseignant — DF-K). L'application d'un delta est un upsert par uuid
/// (`ConflictAlgorithm.replace`), sans garde `PENDING_SYNC`.
///
/// **Partition par compte** : `ref_cours` et les 5 tables du bundle
/// `grades-referential` sont cadrées enseignant côté serveur mais partagées par
/// tous les comptes de la tablette — chaque écriture est estampillée
/// `owner_uid`, chaque lecture filtrée dessus (cf.
/// `core/offline/owner_scope.dart`). Un `ownerUid` absent retombe sur le
/// propriétaire non scopé : comportement mono-compte d'avant la partition.
class AcademicsRefLocalDataSource {
  final Database _db;

  const AcademicsRefLocalDataSource(this._db);

  static const String coursTable = 'ref_cours';
  static const String brancheTable = 'ref_branche';
  static const String ligneBaremeTable = 'ref_ligne_bareme';
  static const String chapitreTable = 'ref_chapitre';
  static const String periodeTable = 'ref_periode';
  static const String sousPeriodeTable = 'ref_sous_periode';

  Future<int> applyPulledCours(
    List<RefCoursRow> rows, {
    required String? ownerUid,
  }) async {
    final owner = ownerKey(ownerUid);
    var applied = 0;
    await applyInBatches<RefCoursRow>(
      _db,
      rows,
      apply: (txn, chunk) async {
        for (final row in chunk) {
          await txn.insert(coursTable, {
            ...row.toMap(),
            'owner_uid': owner,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          applied++;
        }
      },
    );
    return applied;
  }

  /// Un cours par son id (résolution cours → classe pour le roster de notation).
  ///
  /// Non filtré par propriétaire : l'id d'un cours n'appartient qu'à un
  /// enseignant, et l'appelant part toujours d'un cours déjà obtenu par une
  /// lecture scopée (liste « Mes cours », séance de l'emploi du temps).
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

  /// Cours de [ownerUid] (source d'itération du pull evaluations/notes NF-4).
  ///
  /// Le filtre est ici **structurant** : sans lui, le compte connecté itérerait
  /// les cours d'un autre enseignant présents sur la tablette et tirerait ses
  /// notes — au mieux des 403 en boucle, au pire le contenu d'autrui en base.
  Future<List<RefCoursRow>> getAllCours({required String? ownerUid}) async {
    final rows = await _db.query(
      coursTable,
      where: 'owner_uid = ?',
      whereArgs: [ownerKey(ownerUid)],
    );
    return rows.map(RefCoursRow.fromMap).toList(growable: false);
  }

  /// « Mes cours » (guide fonctionnel §4) : jointure `ref_cours` → `ref_ligne_
  /// bareme` → `ref_branche`, triée par classe puis par ordre du barème. Un
  /// cours dont la ligne de barème/branche n'est pas (encore) en cache est
  /// exclu par le `JOIN` (classe masquée).
  ///
  /// Les trois tables sont jointes **à propriétaire constant** : le bundle
  /// livrant des références d'école, la même ligne de barème existe pour chaque
  /// enseignant de l'établissement — sans le filtre sur `lb`/`b`, un cours se
  /// joindrait à la copie d'un collègue et la liste dépendrait de l'ordre des
  /// pulls.
  Future<List<Map<String, Object?>>> getMyCoursesJoined({
    required String? ownerUid,
  }) async {
    final owner = ownerKey(ownerUid);
    return _db.rawQuery(
      '''
    SELECT co.classroom_id AS classroom_id,
           co.id AS cours_id,
           b.nom AS branche_nom
    FROM $coursTable co
    JOIN $ligneBaremeTable lb
      ON lb.id = co.ligne_bareme_id AND lb.owner_uid = co.owner_uid
    JOIN $brancheTable b
      ON b.id = lb.branche_id AND b.owner_uid = lb.owner_uid
    WHERE co.owner_uid = ?
    ORDER BY co.classroom_id, lb.ordre
  ''',
      [owner],
    );
  }

  // ── Bundle `grades-referential` (ETag, remplacement d'ensemble) ─────────────

  /// Remplace intégralement les 5 tables du bundle **pour [ownerUid]** en 1
  /// transaction (pas de delta : le contrat livre l'ensemble à chaque `200`).
  /// Un bundle vide (aucun cours pour ce prof) purge légitimement son cache.
  ///
  /// Le remplacement est **borné au propriétaire** : un `DELETE` global
  /// effacerait le référentiel des autres comptes de la tablette, qui n'ont
  /// aucun moyen de le récupérer hors ligne — ils perdraient statuts de clôture
  /// et plafonds de saisie, et leur liste « Mes cours » se viderait (la
  /// jointure exclut un cours sans sa ligne de barème).
  Future<void> replaceGradesReferential(
    GradesReferentialBundleDto bundle, {
    required String? ownerUid,
  }) {
    final owner = ownerKey(ownerUid);
    return _db.transaction((txn) async {
      final batch = txn.batch();
      for (final table in const [
        brancheTable,
        ligneBaremeTable,
        chapitreTable,
        periodeTable,
        sousPeriodeTable,
      ]) {
        batch.delete(table, where: 'owner_uid = ?', whereArgs: [owner]);
      }
      void insertAll(String table, Iterable<Map<String, Object?>> maps) {
        for (final map in maps) {
          batch.insert(table, {
            ...map,
            'owner_uid': owner,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      insertAll(
        brancheTable,
        bundle.branches.map((b) => b.toLocalRow().toMap()),
      );
      insertAll(
        ligneBaremeTable,
        bundle.ligneBaremes.map((lb) => lb.toLocalRow().toMap()),
      );
      insertAll(
        chapitreTable,
        bundle.chapitres.map((c) => c.toLocalRow().toMap()),
      );
      insertAll(
        periodeTable,
        bundle.periodes.map((p) => p.toLocalRow().toMap()),
      );
      insertAll(
        sousPeriodeTable,
        bundle.sousPeriodes.map((sp) => sp.toLocalRow().toMap()),
      );
      await batch.commit(noResult: true);
    });
  }

  // ── Lecture du bundle (composition du détail cours, MAJ-4) ──────────────────

  /// Ligne de barème par id (`null` si le bundle n'a pas encore cette ligne).
  Future<RefLigneBaremeRow?> getLigneBareme(
    String id, {
    required String? ownerUid,
  }) async {
    final rows = await _db.query(
      ligneBaremeTable,
      where: 'id = ? AND owner_uid = ?',
      whereArgs: [id, ownerKey(ownerUid)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RefLigneBaremeRow.fromMap(rows.first);
  }

  /// Branche par id (`null` si le bundle n'a pas encore cette branche).
  Future<RefBrancheRow?> getBranche(
    String id, {
    required String? ownerUid,
  }) async {
    final rows = await _db.query(
      brancheTable,
      where: 'id = ? AND owner_uid = ?',
      whereArgs: [id, ownerKey(ownerUid)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RefBrancheRow.fromMap(rows.first);
  }

  /// Chapitres d'un cours, triés par `ordre`.
  Future<List<RefChapitreRow>> getChapitresForCours(
    String coursId, {
    required String? ownerUid,
  }) async {
    final rows = await _db.query(
      chapitreTable,
      where: 'cours_id = ? AND owner_uid = ?',
      whereArgs: [coursId, ownerKey(ownerUid)],
      orderBy: 'ordre ASC',
    );
    return rows.map(RefChapitreRow.fromMap).toList(growable: false);
  }

  /// Périodes scolaires d'une portée année × groupe de niveau, triées par
  /// `ordre` — remplace le squelette `ref_cours_notation` comme source du
  /// statut de clôture.
  Future<List<RefPeriodeRow>> getPeriodesForGroup(
    String academicYearId,
    String schoolLevelGroupId, {
    required String? ownerUid,
  }) async {
    final rows = await _db.query(
      periodeTable,
      where:
          'academic_year_id = ? AND school_level_group_id = ? '
          'AND owner_uid = ?',
      whereArgs: [academicYearId, schoolLevelGroupId, ownerKey(ownerUid)],
      orderBy: 'ordre ASC',
    );
    return rows.map(RefPeriodeRow.fromMap).toList(growable: false);
  }

  /// Sous-périodes des périodes données, triées par `ordre` (regroupement par
  /// `periodeScolaireId` laissé à l'appelant).
  Future<List<RefSousPeriodeRow>> getSousPeriodesForPeriodes(
    List<String> periodeIds, {
    required String? ownerUid,
  }) async {
    if (periodeIds.isEmpty) return const [];
    final placeholders = List.filled(periodeIds.length, '?').join(',');
    final rows = await _db.query(
      sousPeriodeTable,
      where: 'periode_scolaire_id IN ($placeholders) AND owner_uid = ?',
      whereArgs: [...periodeIds, ownerKey(ownerUid)],
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

  /// Évince les cours **de [ownerUid]** absents de [keepIds] — le pull `cours`
  /// (désormais scopé enseignant, DF-K) fait foi de « mes cours » sur un cycle
  /// bootstrap complet. Le delta additif ne signale jamais un retrait
  /// (réaffectation à un autre prof) : c'est cette diff explicite qui le fait.
  /// Renvoie les ids évincés (pour cascade côté [AcademicsLocalDataSource]).
  ///
  /// Le filtre propriétaire est **critique** : le snapshot ne décrit que le
  /// compte qui vient de bootstraper. Sans lui, sa première synchro évincerait
  /// tous les cours de ses collègues présents sur la tablette — et la cascade
  /// emporterait au passage LEURS évaluations et notes, y compris non
  /// synchronisées.
  Future<List<String>> evictCoursNotIn(
    Set<String> keepIds, {
    required String? ownerUid,
  }) async {
    final rows = await _db.query(
      coursTable,
      columns: ['id'],
      where: 'owner_uid = ?',
      whereArgs: [ownerKey(ownerUid)],
    );
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
