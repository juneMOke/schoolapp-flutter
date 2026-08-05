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
/// ne réclamera.
///
/// C'est pourquoi la réaffectation d'école se lit ici en deux gestes —
/// [foreignSchoolEntries] désigne, l'appelant efface, puis [deleteEntries]
/// retire les lignes de ce qui est réellement parti. [purgeAll] fait
/// exception : il rend les entrées après les avoir supprimées, parce que son
/// appelant efface le répertoire **entier** et détruit la clé, geste qui ne
/// laisse rien à réclamer même interrompu.
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
      // Seules les pièces réellement détenues : une ligne apprise par le delta
      // n'occupe rien, donc l'évincer ne libère rien — et lui retirer sa ligne
      // ferait perdre une connaissance que le prochain cycle devrait racheter.
      where: 'content_sha256 IS NOT NULL',
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

  /// Retire les **octets** d'une pièce, sans retirer ce qu'on sait d'elle. Rend
  /// le nombre de lignes rétrogradées.
  ///
  /// C'est ce qu'« évincer » veut dire, et la nuance vaut des documents : le
  /// curseur du delta est monotone, donc une pièce déjà descendue ne redescend
  /// jamais. Supprimer sa ligne à l'éviction la ferait disparaître du catalogue
  /// **pour toujours** — l'agent ne saurait même plus qu'elle existe, alors que
  /// le serveur la conserve et qu'elle reste re-téléchargeable. Rétrograder
  /// libère la place sans effacer la connaissance.
  ///
  /// L'appelant a supprimé le fichier AVANT : c'est ce qui rend ce geste sûr.
  Future<int> downgradeToKnown(List<String> ids) async {
    final targets = ids.where((id) => id.isNotEmpty).toList(growable: false);
    if (targets.isEmpty) return 0;

    var downgraded = 0;
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
      downgraded += await _db.update(
        kEditiqueCacheTable,
        // Le poids retombe à zéro avec l'empreinte : la colonne mesure les
        // octets détenus, et il n'y en a plus. Le delta le renseignera à
        // nouveau s'il repasse.
        {'content_sha256': null, 'size_bytes': 0},
        where: 'id IN ($placeholders)',
        whereArgs: chunk,
      );
    }
    return downgraded;
  }

  /// Entrées qui n'appartiennent pas à l'école courante — la tablette vient
  /// d'être réaffectée (D-7, RG-012-21).
  ///
  /// **Désigne, n'efface pas.** L'appelant retire les fichiers d'abord et les
  /// lignes ensuite, jamais l'inverse : supprimer les lignes en premier
  /// laisserait, si l'application s'arrête entre les deux, des pièces d'un
  /// autre établissement sur le disque — déchiffrables, invisibles à la
  /// comptabilité de budget, et que plus aucune ligne ne désignerait pour les
  /// réclamer. C'est exactement ce que D-7 interdit.
  ///
  /// Refuse une école vide plutôt que de l'interpréter. `CurrentUserContext`
  /// rend `null` avant l'authentification — la DI offline est câblée avant elle
  /// —, et « aucune école courante » signifierait ici « toutes les écoles sont
  /// étrangères », donc un cache vidé à chaque démarrage à froid. Tout vider
  /// reste possible, mais alors explicitement, par [purgeAll].
  Future<List<EditiqueCacheEntry>> foreignSchoolEntries(
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
    return rows.map(EditiqueCacheEntry.fromMap).toList(growable: false);
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
