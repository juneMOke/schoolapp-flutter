import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_models.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_targets.dart';

/// Ce qu'une page de retraits a produit localement.
class TombstoneApplyResult {
  /// Lignes réellement effacées (tables filles non comptées).
  final int removed;

  /// Retraits **différés** : la ligne visée porte une écriture locale non
  /// poussée. On ne l'efface pas — on perdrait le travail de quelqu'un sans le
  /// dire — et le serveur la redemandera au cycle suivant, la pierre tombale
  /// étant conservée le temps de la rétention.
  final int deferred;

  const TombstoneApplyResult({required this.removed, required this.deferred});

  TombstoneApplyResult operator +(TombstoneApplyResult other) =>
      TombstoneApplyResult(
        removed: removed + other.removed,
        deferred: deferred + other.deferred,
      );

  static const TombstoneApplyResult none = TombstoneApplyResult(
    removed: 0,
    deferred: 0,
  );
}

/// Applique les retraits venus du serveur sur les tables locales.
///
/// ## L'ordre remplace une garde d'horloge, et ce n'est pas un raccourci
///
/// On pourrait vouloir refuser d'effacer une ligne « plus récente » que la
/// pierre tombale. Deux choses l'en dispensent, une troisième l'en empêche. Le
/// flux des retraits descend **avant** tous ceux dont il retire des lignes : une
/// ligne recréée côté serveur est donc réinsérée juste après, dans le même
/// cycle, par son propre flux ; une ligne réellement supprimée, elle, n'est
/// réinsérée par personne. Et surtout, les horloges locales ne sont pas
/// comparables — `server_updated_at` est un entier ici, un texte ISO là, et
/// `synced_at` est l'heure de l'appareil, jamais celle du serveur. Une garde
/// écrite sur ces colonnes comparerait des grandeurs différentes en croyant se
/// protéger.
///
/// ## Ce qui garde vraiment
///
/// L'état de synchronisation. Une ligne qui n'est pas `SYNCED` porte une
/// écriture que le poste n'a pas encore poussée : l'effacer ferait disparaître
/// un encaissement ou une inscription que personne n'a jamais vus ailleurs. Elle
/// est conservée, et comptée à part.
class TombstoneDao {
  final DatabaseExecutor _db;
  final SyncMetaDao _syncMetaDao;

  const TombstoneDao(this._db, this._syncMetaDao);

  /// Applique une page de retraits.
  Future<TombstoneApplyResult> apply(List<TombstoneDto> tombstones) async {
    var total = TombstoneApplyResult.none;
    for (final tombstone in tombstones) {
      final target = kTombstoneTargets[tombstone.resource];
      // Ressource inconnue de cette version : non-événement, pas une panne. Le
      // contrat prévoit qu'un flux existe côté serveur avant que le parc sache
      // le traiter. Motif inconnu : même règle, en plus prudent — effacer sur
      // une consigne qu'on ne sait pas lire serait pire que de ne rien faire.
      if (target == null || tombstone.reason == TombstoneReason.unknown) {
        continue;
      }
      total = total + await _applyOne(tombstone, target);
    }
    return total;
  }

  Future<TombstoneApplyResult> _applyOne(
    TombstoneDto tombstone,
    TombstoneTarget target,
  ) async {
    final where = <String>['${target.idColumn} = ?'];
    final args = <Object?>[tombstone.entityId];

    if (tombstone.reason == TombstoneReason.outOfScope &&
        !target.scopeIsImplicit) {
      final scopeColumn = target.scopeColumn;
      // Un retrait conditionnel sans colonne de portée ne peut pas être vérifié.
      // L'appliquer quand même effacerait chez le NOUVEAU porteur ce qu'il vient
      // légitimement de recevoir.
      if (scopeColumn == null || tombstone.scopeKey == null) {
        return TombstoneApplyResult.none;
      }
      where.add('$scopeColumn = ?');
      args.add(tombstone.scopeKey);
    } else if (target.pairedByScope) {
      // Le couple (élève, parent), pas une portée : l'élève seul n'identifie pas
      // le lien, et effacer par le seul élève emporterait ses autres tuteurs.
      if (tombstone.scopeKey == null) return TombstoneApplyResult.none;
      where.add('${target.scopeColumn} = ?');
      args.add(tombstone.scopeKey);
    }

    final clause = where.join(' AND ');
    // On identifie la ligne AVANT d'effacer quoi que ce soit : les descendants se
    // suppriment par l'identifiant du parent, et un retrait conditionnel qui ne
    // s'applique pas ne doit toucher aucun d'eux.
    final matched = await _db.query(
      target.table,
      columns: [
        target.idColumn,
        if (target.syncStatusColumn != null) target.syncStatusColumn!,
      ],
      where: clause,
      whereArgs: args,
      limit: 1,
    );
    if (matched.isEmpty) return TombstoneApplyResult.none;

    final statusColumn = target.syncStatusColumn;
    if (statusColumn != null && matched.first[statusColumn] != kSyncedStatus) {
      return const TombstoneApplyResult(removed: 0, deferred: 1);
    }

    final parentId = matched.first[target.idColumn] as String;

    // Les descendants d'abord : sqflite n'applique aucune cascade, et un
    // versement retiré qui laisserait ses imputations derrière lui laisserait la
    // caisse les compter.
    for (final sql in target.descendantsSql) {
      await _db.rawDelete(sql, [parentId]);
    }
    for (final child in target.children.entries) {
      await _db.delete(
        child.key,
        where: '${child.value} = ?',
        whereArgs: [parentId],
      );
    }

    final removed = await _db.delete(
      target.table,
      where: clause,
      whereArgs: args,
    );

    // Les curseurs des flux scopés à cette ligne. Sans cette purge, une
    // réaffectation en retour reprendrait un curseur périmé au lieu de
    // rebootstraper, et perdrait silencieusement tout ce qui existait avant.
    for (final prefix in target.scopedCursorPrefixes) {
      await _syncMetaDao.deleteCursor('$prefix:$parentId');
      await _syncMetaDao.deleteCursor('${prefix}_bootstrap:$parentId');
    }

    return TombstoneApplyResult(removed: removed, deferred: 0);
  }
}
