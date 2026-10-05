import 'dart:convert';

import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_fiche_codec.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Range en local les chapitres descendus (flux, ou fiche retenue rendue par
/// un envoi), **sans jamais écraser une écriture locale plus récente** :
///
/// - **fiche** : une ligne qui attend (envoi en attente ou refusé) n'est
///   remplacée que si la fiche serveur est plus récente qu'elle
///   (`clientUpdatedAt`) ; une ligne dont la suppression attend ne bouge pas ;
/// - **ordre** : le rang serveur s'applique, sauf si un geste d'ordre du cours
///   attend encore ;
/// - **notes et ressources** : la liste serveur remplace les lignes déjà
///   synchronisées ; celles qui attendent (ajout ou suppression) restent.
class ChapitrePullWriter {
  final Database _db;

  const ChapitrePullWriter(this._db);

  /// Rend le nombre de chapitres écrits.
  Future<int> apply(List<ChapitreDto> chapitres, {required int nowMs}) {
    if (chapitres.isEmpty) return Future.value(0);
    return _db.transaction((txn) async {
      var written = 0;
      final ordrePending = <String, bool>{};
      for (final dto in chapitres) {
        final keepOrdre = ordrePending[dto.coursId] ??=
            await ProgrammeOutbox.hasPending(
              txn,
              type: ProgrammeOutbox.ordreType,
              aggregateId: dto.coursId,
            );
        if (await _applyFiche(txn, dto, keepOrdre: keepOrdre, nowMs: nowMs)) {
          written++;
        }
        await _replaceSynced(
          txn,
          ProgrammeTables.note,
          chapitreId: dto.id,
          rows: [for (final note in dto.notes) _noteRow(dto, note, nowMs)],
        );
        await _replaceSynced(
          txn,
          ProgrammeTables.ressource,
          chapitreId: dto.id,
          rows: [for (final r in dto.ressources) _ressourceRow(dto, r, nowMs)],
        );
      }
      return written;
    });
  }

  Future<bool> _applyFiche(
    DatabaseExecutor txn,
    ChapitreDto dto, {
    required bool keepOrdre,
    required int nowMs,
  }) async {
    final local = (await txn.query(
      ProgrammeTables.chapitre,
      where: 'id = ?',
      whereArgs: [dto.id],
      limit: 1,
    )).firstOrNull;
    final row = ficheColumnsOf(dto, nowMs: nowMs);
    if (local == null) {
      await txn.insert(ProgrammeTables.chapitre, {
        'id': dto.id,
        'ordre': dto.ordre,
        ...row,
      });
      return true;
    }
    if (local['deleted_at'] != null) return false;
    final ordre = keepOrdre ? <String, Object?>{} : {'ordre': dto.ordre};
    if (local['sync_status'] != SyncState.synced.dbValue &&
        !_isNewer(dto.clientUpdatedAt, local['client_updated_at'])) {
      // L'écriture locale est la plus récente : elle partira. Le serveur
      // la connaît désormais, et son rang s'applique.
      await txn.update(
        ProgrammeTables.chapitre,
        {...ordre, 'server_known': 1, 'server_updated_at': dto.serverUpdatedAt},
        where: 'id = ?',
        whereArgs: [dto.id],
      );
      return false;
    }
    await txn.update(
      ProgrammeTables.chapitre,
      {...row, ...ordre},
      where: 'id = ?',
      whereArgs: [dto.id],
    );
    return true;
  }

  /// La fiche serveur [dto], synchronisée, telle qu'elle se range — sans
  /// `ordre`, que l'appelant pose ou garde.
  static Map<String, Object?> ficheColumnsOf(
    ChapitreDto dto, {
    required int nowMs,
  }) => {
    'cours_id': dto.coursId,
    'titre': dto.titre,
    'resume': dto.resume,
    'statut': dto.statut,
    'seances': dto.seances,
    'sous_periode_id': dto.sousPeriodeId,
    'objectifs_json': jsonEncode(
      ChapitreFicheCodec.objectifsToJson(dto.objectifs),
    ),
    'strategies_json': jsonEncode(dto.strategies),
    'blocs_json': jsonEncode(ChapitreFicheCodec.blocsToJson(dto.blocs)),
    'client_updated_at': dto.clientUpdatedAt,
    'server_updated_at': dto.serverUpdatedAt,
    'server_known': 1,
    'sync_status': SyncState.synced.dbValue,
    'sync_error_code': null,
    'updated_at': nowMs,
  };

  static bool _isNewer(String? server, Object? local) {
    final s = server == null ? null : DateTime.tryParse(server);
    final l = local is String ? DateTime.tryParse(local) : null;
    if (s == null) return false;
    return l == null || s.isAfter(l);
  }

  /// Remplace les lignes `SYNCED` de [table] pour ce chapitre par [rows], sans
  /// toucher une ligne qui attend (ajout pas encore accusé, suppression).
  Future<void> _replaceSynced(
    DatabaseExecutor txn,
    String table, {
    required String chapitreId,
    required List<Map<String, Object?>> rows,
  }) async {
    final waiting = {
      for (final r in await txn.query(
        table,
        columns: ['id'],
        where:
            'chapitre_id = ? AND (sync_status <> ? OR deleted_at IS NOT NULL)',
        whereArgs: [chapitreId, SyncState.synced.dbValue],
      ))
        r['id'] as String,
    };
    await txn.delete(
      table,
      where: 'chapitre_id = ? AND sync_status = ? AND deleted_at IS NULL',
      whereArgs: [chapitreId, SyncState.synced.dbValue],
    );
    for (final row in rows) {
      if (waiting.contains(row['id'])) continue;
      await txn.insert(
        table,
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Map<String, Object?> _noteRow(
    ChapitreDto chapitre,
    ChapitreNoteDto note,
    int nowMs,
  ) => {
    'id': note.id,
    'chapitre_id': chapitre.id,
    'cours_id': chapitre.coursId,
    'texte': note.texte,
    'ecrite_le': note.ecriteLe,
    'auteur': note.auteur,
    'sync_status': SyncState.synced.dbValue,
    'updated_at': nowMs,
  };

  static Map<String, Object?> _ressourceRow(
    ChapitreDto chapitre,
    ChapitreRessourceDto r,
    int nowMs,
  ) => {
    'id': r.id,
    'chapitre_id': chapitre.id,
    'cours_id': chapitre.coursId,
    'type': r.type,
    'nom': r.nom,
    'url': r.url,
    'reference': r.reference,
    'taille': r.taille,
    'sha256': r.sha256,
    'mime_type': r.mimeType,
    'file_name': r.fileName,
    'sync_status': SyncState.synced.dbValue,
    'updated_at': nowMs,
  };
}
