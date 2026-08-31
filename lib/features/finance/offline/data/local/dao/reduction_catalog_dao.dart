import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/models/reduction_catalog_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/grantable_reduction.dart';

/// Barème de réductions (ADR-021 V1) : écriture par le pull, lecture par le
/// guichet. **Aucune écriture ne vient d'ici** — le barème se paramètre côté
/// serveur, ce DAO ne fait que recevoir et servir.
class ReductionCatalogDao {
  final Database _db;

  const ReductionCatalogDao(this._db);

  /// Remplace le barème **de cette école** par celui du bundle : purge scopée
  /// puis insertion, en une transaction.
  ///
  /// ⚠️ **Scopé par école, pas par année, et ce n'est pas un détail.** Les deux
  /// tables n'ont pas d'`academic_year_id` — le barème descend à la racine du
  /// bundle. Une purge globale effacerait donc le barème de l'autre école sur
  /// une tablette partagée, et contrairement au reste du référentiel **aucun
  /// filtre d'année ne viendrait masquer la perte** en « cette école n'a pas de
  /// barème » : le poste d'à côté verrait sa liste se vider sans rien qui
  /// l'explique.
  ///
  /// Pas de diff ni de purge par lots, contrairement à
  /// `replaceTariffsForYears` : le scope tient dans **un seul** paramètre lié
  /// (`school_id = ?`), donc rien ne peut approcher `SQLITE_MAX_VARIABLE_NUMBER`.
  ///
  /// [schoolId] vide = appelant sans école résolue : on **ne touche à rien**.
  /// Purger sous la clé `''` effacerait le barème d'une base héritée, et
  /// l'insérer sous cette clé le rendrait invisible à toute lecture scopée.
  Future<void> replaceForSchool(
    List<ReductionTypeLocalModel> types,
    List<ReductionLineLocalModel> lines, {
    required String schoolId,
  }) async {
    if (schoolId.isEmpty) return;
    await _db.transaction((txn) async {
      await txn.delete(
        'ref_reduction_types',
        where: 'school_id = ?',
        whereArgs: [schoolId],
      );
      await txn.delete(
        'ref_reduction_lines',
        where: 'school_id = ?',
        whereArgs: [schoolId],
      );
      final batch = txn.batch();
      for (final type in types) {
        batch.insert('ref_reduction_types', type.toMap());
      }
      for (final line in lines) {
        batch.insert('ref_reduction_lines', line.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  /// Les réductions proposables au guichet, triées par libellé.
  ///
  /// Le `EXISTS` est le filtre qui compte : un type actif **sans aucune ligne
  /// de barème** ne réduira jamais rien. Le taux étant masqué à l'écran, il
  /// serait indiscernable d'un type qui réduit — on le cocherait de bonne foi,
  /// et la V2 hériterait d'un octroi vide.
  Future<List<GrantableReduction>> grantableForSchool(String schoolId) async {
    if (schoolId.isEmpty) return const [];
    final rows = await _db.rawQuery(
      'SELECT t.code AS code, t.label AS label '
      'FROM ref_reduction_types t '
      'WHERE t.school_id = ? AND t.active = 1 '
      'AND EXISTS (SELECT 1 FROM ref_reduction_lines l '
      'WHERE l.school_id = t.school_id AND l.reduction_code = t.code) '
      'ORDER BY t.label',
      [schoolId],
    );
    return [
      for (final row in rows)
        GrantableReduction(
          code: row['code'] as String,
          label: row['label'] as String,
        ),
    ];
  }
}
