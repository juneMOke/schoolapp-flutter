import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_dao.dart';
import 'package:school_app_flutter/features/documents/domain/cache/editique_cache_eviction_policy.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';

/// Ce qui **retire** des pièces du cache de restitution : balayage LRU et
/// effacement de D-7.
///
/// Séparé d'[EditiqueCacheDao], qui sert la vie normale de l'index (retrouver,
/// mesurer, enregistrer un accès). Les deux n'ont ni les mêmes appelants ni les
/// mêmes conséquences : ici, chaque appel détruit de la donnée locale.
///
/// ## Ordre d'effacement à respecter côté appelant
///
/// Toujours supprimer le **fichier d'abord**, la ligne d'index **ensuite**. Une
/// ligne survivant à son fichier est un simple défaut de cache : la relecture
/// ne trouve rien, la pièce se retélécharge. Un fichier survivant à sa ligne
/// est un octet orphelin, invisible à la comptabilité de budget, que plus rien
/// ne réclamera. C'est pour cela que les purges rendent les entrées
/// supprimées : leurs identifiants nomment les fichiers à effacer.
class EditiqueCacheMaintenanceDao {
  /// Découpage des `IN (…)` : SQLite plafonne le nombre de paramètres liés
  /// (999 sur les moteurs les plus anciens encore rencontrés).
  static const int _maxParametersPerStatement = 200;

  final DatabaseExecutor _db;

  const EditiqueCacheMaintenanceDao(this._db);

  /// Empreintes triées du **moins récemment utilisé** au plus récent : l'ordre
  /// que [EditiqueCacheEvictionPolicy] attend.
  ///
  /// Ne rend que l'identifiant et la taille : un balayage n'a besoin de rien
  /// d'autre, et le cache entier tient en quelques dizaines de milliers de
  /// lignes de deux colonnes.
  Future<List<EditiqueCacheFootprint>> footprintsByLeastRecentlyUsed() async {
    final rows = await _db.query(
      kEditiqueCacheTable,
      columns: const ['id', 'size_bytes'],
      // `created_at` puis `id` départagent les égalités d'accès : sans eux,
      // deux balayages successifs pourraient évincer des entrées différentes
      // pour un même état de cache.
      orderBy: 'last_accessed_at ASC, created_at ASC, id ASC',
    );
    return rows
        .map(
          (row) => EditiqueCacheFootprint(
            id: (row['id'] as String?) ?? '',
            sizeBytes: (row['size_bytes'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList(growable: false);
  }

  /// Supprime les lignes d'index désignées. Rend le nombre de lignes retirées.
  ///
  /// Les fichiers correspondants doivent avoir été effacés **avant** l'appel.
  Future<int> deleteEntries(List<String> ids) async {
    final targets = ids.where((id) => id.isNotEmpty).toList(growable: false);
    if (targets.isEmpty) return 0;

    var deleted = 0;
    for (
      var start = 0;
      start < targets.length;
      start += _maxParametersPerStatement
    ) {
      final end = start + _maxParametersPerStatement < targets.length
          ? start + _maxParametersPerStatement
          : targets.length;
      final chunk = targets.sublist(start, end);
      final placeholders = List.filled(chunk.length, '?').join(', ');
      deleted += await _db.delete(
        kEditiqueCacheTable,
        where: 'id IN ($placeholders)',
        whereArgs: chunk,
      );
    }
    return deleted;
  }

  /// Efface tout ce qui n'appartient pas à l'école courante (D-7, RG-012-21) et
  /// rend les entrées supprimées, pour que leurs fichiers le soient aussi.
  ///
  /// Sélection **avant** suppression, délibérément : un arrêt entre les deux
  /// laisse des fichiers à réclamer, ce qu'un balayage ultérieur sait faire ;
  /// l'ordre inverse laisserait des octets orphelins que plus rien ne désigne.
  ///
  /// Refuse une école vide plutôt que de l'interpréter. `CurrentUserContext`
  /// rend `null` avant l'authentification — la DI offline est câblée avant elle
  /// —, et « aucune école courante » signifierait ici « toutes les écoles sont
  /// étrangères », donc un cache vidé à chaque démarrage à froid. Tout vider
  /// reste possible, mais alors explicitement, par [purgeAll].
  Future<List<EditiqueCacheEntry>> purgeForeignSchools(
    String currentSchoolId,
  ) async {
    if (currentSchoolId.isEmpty) {
      throw ArgumentError.value(
        currentSchoolId,
        'currentSchoolId',
        'École courante inconnue : sans elle, toute entrée paraîtrait '
            'étrangère. Utiliser purgeAll() pour vider délibérément',
      );
    }

    final rows = await _db.query(
      kEditiqueCacheTable,
      where: 'school_id <> ?',
      whereArgs: [currentSchoolId],
    );
    final removed = rows
        .map(EditiqueCacheEntry.fromMap)
        .toList(growable: false);
    if (removed.isEmpty) return removed;

    await _db.delete(
      kEditiqueCacheTable,
      where: 'school_id <> ?',
      whereArgs: [currentSchoolId],
    );
    return removed;
  }

  /// Efface tout le cache et rend les entrées supprimées. Primitive de
  /// l'effacement physique exigé par D-7 (réaffectation, changement de profil).
  Future<List<EditiqueCacheEntry>> purgeAll() async {
    final rows = await _db.query(kEditiqueCacheTable);
    final removed = rows
        .map(EditiqueCacheEntry.fromMap)
        .toList(growable: false);
    if (removed.isEmpty) return removed;

    await _db.delete(kEditiqueCacheTable);
    return removed;
  }
}
