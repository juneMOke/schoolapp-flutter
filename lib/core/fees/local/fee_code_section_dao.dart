import 'package:school_app_flutter/core/fees/local/fee_code_section_local_model.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les titres de sections de frais en local : écriture par le pull, lecture par
/// les écrans qui nomment un frais.
///
/// **Aucune écriture ne part d'ici vers le serveur** — une section se nomme dans
/// Configuration, ce DAO ne fait que recevoir et servir. Même régime que
/// `ExchangeRateDao` et `ReductionCatalogDao`, et pour la même raison : ces
/// tables descendent à la **racine** du référentiel, hors slot d'année.
class FeeCodeSectionDao {
  final Database _db;

  const FeeCodeSectionDao(this._db);

  /// Remplace le catalogue **de cette école** : purge scopée puis insertion, en
  /// une transaction.
  ///
  /// ⚠️ **Scopé par école, jamais globalement.** La table n'a pas
  /// d'`academic_year_id` — une purge globale effacerait les titres de l'autre
  /// école sur une tablette partagée, et **aucun filtre d'année ne viendrait
  /// masquer la perte** : le poste d'à côté verrait ses frais se renommer tout
  /// seuls en « Minerval » sans que rien ne l'explique.
  ///
  /// [schoolId] vide = appelant sans école résolue : on **ne touche à rien**.
  /// Purger sous la clé `''` effacerait le catalogue d'une base héritée ;
  /// l'insérer sous cette clé le rendrait invisible à toute lecture scopée.
  ///
  /// Les lignes inutilisables sont écartées **à l'écriture** (cf.
  /// [FeeCodeSectionLocalModel.isUsable]) : un titre vide remplacerait la nature
  /// localisée par du blanc, ce qui est pire que le repli qu'il prétend
  /// améliorer.
  ///
  /// Un catalogue servi **vide** purge quand même : c'est une réponse, pas une
  /// absence de réponse — les échecs, eux, n'arrivent jamais jusqu'ici.
  Future<void> replaceForSchool(
    List<FeeCodeSectionLocalModel> sections, {
    required String schoolId,
  }) async {
    if (schoolId.isEmpty) return;
    await _db.transaction((txn) async {
      await txn.delete(
        'ref_fee_code_sections',
        where: 'school_id = ?',
        whereArgs: [schoolId],
      );
      final batch = txn.batch();
      for (final section in sections) {
        if (!section.isUsable) continue;
        batch.insert(
          'ref_fee_code_sections',
          section.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Les titres de cette école, indexés par code — la forme dont un écran a
  /// besoin pour nommer une créance qu'il tient déjà.
  ///
  /// ⚠️ **`active` ne filtre pas.** Une section masquée garde son titre : la
  /// masquer dit « ne me la propose plus à la saisie », jamais « ne sais plus la
  /// nommer ». Une créance posée avant le masquage existe toujours, et c'est
  /// elle qu'on affiche.
  ///
  /// Le **code est normalisé en majuscules** : c'est la forme que le serveur
  /// sert, mais une base ancienne ou un import n'y oblige en rien, et la
  /// jointure se fait ici sur du texte — pas sur une clé étrangère qui aurait
  /// tranché à notre place.
  ///
  /// Une lecture ne remonte **jamais** d'erreur : sans école résolue, ou sans
  /// ligne, on rend une table vide et l'appelant retombe sur la nature
  /// localisée.
  Future<Map<String, String>> titlesForSchool(String schoolId) async {
    if (schoolId.isEmpty) return const <String, String>{};
    final rows = await _db.query(
      'ref_fee_code_sections',
      columns: ['code', 'label'],
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    return <String, String>{
      for (final row in rows)
        if (((row['code'] as String?) ?? '').trim().isNotEmpty &&
            ((row['label'] as String?) ?? '').trim().isNotEmpty)
          (row['code'] as String).trim().toUpperCase(): (row['label'] as String)
              .trim(),
    };
  }
}
