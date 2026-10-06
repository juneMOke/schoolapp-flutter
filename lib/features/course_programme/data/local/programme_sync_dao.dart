import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_pull_writer.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_purge.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce que le serveur sait d'un chapitre, vu de la tablette.
enum ChapitreServerState {
  /// Plus sur la tablette (supprimé, cours évincé).
  gone,

  /// Créé ici, jamais accusé : ses enfants l'attendent.
  unknown,

  /// Connu du serveur.
  known,
}

/// Les accusés du serveur sur les gestes du programme, appliqués **sans
/// défaire une écriture locale plus récente** : une ligne dont l'horloge a
/// changé pendant le vol a remis son entrée en file, elle repartira.
class ProgrammeSyncDao {
  final Database _db;
  final ProgrammeBlobs _blobs;

  const ProgrammeSyncDao({required Database db, required ProgrammeBlobs blobs})
    : _db = db,
      _blobs = blobs;

  Future<ChapitreServerState> chapitreState(String chapitreId) async {
    final row = (await _db.query(
      ProgrammeTables.chapitre,
      columns: ['server_known'],
      where: 'id = ?',
      whereArgs: [chapitreId],
    )).firstOrNull;
    if (row == null) return ChapitreServerState.gone;
    return row['server_known'] == 1
        ? ChapitreServerState.known
        : ChapitreServerState.unknown;
  }

  /// Un des [chapitreIds] n'est-il pas encore connu du serveur ? (Une
  /// évaluation qui le cite doit l'attendre.)
  Future<bool> anyUnknown(List<String> chapitreIds) async {
    if (chapitreIds.isEmpty) return false;
    final marks = List.filled(chapitreIds.length, '?').join(', ');
    final rows = await _db.query(
      ProgrammeTables.chapitre,
      columns: ['1'],
      where: 'id IN ($marks) AND server_known = 0',
      whereArgs: chapitreIds,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<String?> coursOf(String chapitreId) async {
    final row = (await _db.query(
      ProgrammeTables.chapitre,
      columns: ['cours_id'],
      where: 'id = ?',
      whereArgs: [chapitreId],
    )).firstOrNull;
    return row?['cours_id'] as String?;
  }

  /// L'entrée [entryId] a-t-elle été remplacée par un geste plus récent
  /// depuis l'envoi de celle créée à [sentCreatedAt] ?
  Future<bool> entryReplaced(String entryId, int sentCreatedAt) =>
      ProgrammeOutbox.replacedSince(_db, entryId, sentCreatedAt);

  /// Accusé d'une fiche. Ligne inchangée depuis l'envoi : la fiche retenue
  /// s'applique (celle du serveur si la nôtre a été ignorée, plus ancienne).
  /// Ligne changée : seul « connu du serveur » se pose.
  Future<void> applyFicheAck(
    ChapitreFicheAck ack, {
    required String? sentClientUpdatedAt,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final dto = ack.chapitre;
    final known = {'server_known': 1, 'server_updated_at': dto.serverUpdatedAt};
    final unchanged =
        await txn.update(
          ProgrammeTables.chapitre,
          ack.ignored
              ? ChapitrePullWriter.ficheColumnsOf(dto, nowMs: nowMs)
              : {
                  ...known,
                  'sync_status': SyncState.synced.dbValue,
                  'sync_error_code': null,
                  'updated_at': nowMs,
                },
          where: 'id = ? AND deleted_at IS NULL AND client_updated_at IS ?',
          whereArgs: [dto.id, sentClientUpdatedAt],
        ) >
        0;
    if (!unchanged) {
      await txn.update(
        ProgrammeTables.chapitre,
        known,
        where: 'id = ?',
        whereArgs: [dto.id],
      );
    }
  });

  /// Refus déterministe d'une fiche : « à corriger », sauf si une saisie plus
  /// récente l'a remplacée pendant le vol (rend `false` : elle repartira).
  Future<bool> markChapitreRejected(
    String chapitreId, {
    required String? sentClientUpdatedAt,
    required String code,
    required int nowMs,
  }) async =>
      await _db.update(
        ProgrammeTables.chapitre,
        {
          'sync_status': SyncState.syncError.dbValue,
          'sync_error_code': code,
          'updated_at': nowMs,
        },
        where: 'id = ? AND client_updated_at IS ?',
        whereArgs: [chapitreId, sentClientUpdatedAt],
      ) >
      0;

  /// Le chapitre n'existe plus côté serveur (suppression accusée, 410) : il
  /// quitte la tablette avec ses enfants et leurs fichiers.
  Future<void> removeChapitre(String chapitreId) async {
    final files = await _db.transaction(
      (txn) => ProgrammePurge.removeChapitres(txn, [chapitreId]),
    );
    await _blobs.deleteAll(files);
  }

  /// Refus définitif d'une suppression : la ligne réapparaît, « à corriger »
  /// — elle existe toujours au serveur, des évaluations peuvent la citer.
  Future<void> restoreChapitre(String chapitreId, String code, int nowMs) =>
      restoreChild(ProgrammeTables.chapitre, chapitreId, code, nowMs);

  /// Refus définitif du retrait d'une note ou d'une ressource : elle
  /// réapparaît, « à corriger ». Une ligne jamais accusée, partie de la
  /// tablette au geste, ne revient pas.
  Future<void> restoreChild(String table, String id, String code, int nowMs) =>
      _db.update(
        table,
        {
          'deleted_at': null,
          'sync_status': SyncState.syncError.dbValue,
          'sync_error_code': code,
          'updated_at': nowMs,
        },
        where: 'id = ? AND deleted_at IS NOT NULL',
        whereArgs: [id],
      );

  /// L'ordre retenu par le serveur, appliqué sauf si un nouvel ordre a été
  /// mis en file pendant le vol (l'entrée porte alors un autre `created_at`).
  Future<void> applyOrdreAck(
    String coursId,
    List<String> chapitreIds, {
    required int sentCreatedAt,
    required int nowMs,
  }) => _db.transaction((txn) async {
    if (await ProgrammeOutbox.replacedSince(
      txn,
      ProgrammeOutbox.ordreEntry(coursId),
      sentCreatedAt,
    )) {
      return;
    }
    await ProgrammeTables.applyOrdre(txn, coursId, chapitreIds, nowMs: nowMs);
  });

  /// Ajout d'une note ou d'une ressource accusé.
  Future<void> markChildSynced(String table, String id, int nowMs) =>
      _db.update(
        table,
        {
          'sync_status': SyncState.synced.dbValue,
          'sync_error_code': null,
          'updated_at': nowMs,
        },
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [id],
      );

  /// Retrait d'une note ou d'une ressource accusé : la ligne part.
  Future<void> removeChild(String table, String id) =>
      _db.delete(table, where: 'id = ?', whereArgs: [id]);

  /// Refus déterministe d'un ajout : la ligne reste, « à corriger ».
  Future<void> markChildRejected(
    String table,
    String id,
    String code,
    int nowMs,
  ) => _db.update(
    table,
    {
      'sync_status': SyncState.syncError.dbValue,
      'sync_error_code': code,
      'updated_at': nowMs,
    },
    where: 'id = ? AND deleted_at IS NULL',
    whereArgs: [id],
  );
}
