import 'dart:typed_data';

import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox_writer.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_note.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Écritures locales des notes de séance et des ressources d'un chapitre,
/// toujours avec leur entrée d'outbox (agrégat = le chapitre, pour que ses
/// gestes l'attendent et partent avec lui).
///
/// Retirer part **toujours** par un geste, qui remplace un ajout en attente :
/// un ajout en vol a pu être écrit par le serveur sans que l'accusé revienne,
/// et la note redescendrait. Ce que le serveur n'a jamais accusé quitte la
/// tablette tout de suite ; un 404 en retour acquiert le geste.
class ChapitreChildrenWriteDao {
  final Database _db;
  final ProgrammeBlobs _blobs;

  const ChapitreChildrenWriteDao({
    required Database db,
    required ProgrammeBlobs blobs,
  }) : _db = db,
       _blobs = blobs;

  Future<void> addNote(
    ChapitreNote note, {
    required String coursId,
    required String? schoolId,
    required int nowMs,
    String? authorId,
  }) => _db.transaction((txn) async {
    final payload = ChapitreNotePayload(
      op: ProgrammePushOp.save,
      id: note.id,
      chapitreId: note.chapitreId,
      texte: note.texte,
      ecriteLe: note.ecriteLe.toUtc().toIso8601String(),
    );
    await txn.insert(ProgrammeTables.note, {
      'id': note.id,
      'chapitre_id': note.chapitreId,
      'cours_id': coursId,
      'texte': note.texte,
      'ecrite_le': payload.ecriteLe,
      'auteur': note.auteur,
      'sync_status': SyncState.pendingSync.dbValue,
      'updated_at': nowMs,
    });
    await enqueueProgrammeGesture(
      txn,
      entryId: ProgrammeOutbox.noteEntry(note.id),
      type: ProgrammeOutbox.noteType,
      aggregateId: note.chapitreId,
      payload: payload.toJson(),
      schoolId: schoolId,
      nowMs: nowMs,
      authorId: authorId,
    );
  });

  Future<void> deleteNote(
    String noteId, {
    required String? schoolId,
    required int nowMs,
    String? authorId,
  }) => _db.transaction((txn) async {
    final row = await _row(txn, ProgrammeTables.note, noteId);
    if (row == null) return;
    final chapitreId = row['chapitre_id'] as String;
    await _retire(txn, ProgrammeTables.note, row, nowMs);
    await enqueueProgrammeGesture(
      txn,
      entryId: ProgrammeOutbox.noteEntry(noteId),
      type: ProgrammeOutbox.noteType,
      aggregateId: chapitreId,
      payload: ChapitreNotePayload(
        op: ProgrammePushOp.delete,
        id: noteId,
        chapitreId: chapitreId,
      ).toJson(),
      schoolId: schoolId,
      nowMs: nowMs,
      authorId: authorId,
    );
  });

  /// Joint une ressource ; [bytes] seulement pour un document, scellés dans le
  /// magasin avant l'insertion de la ligne. `false` si le fichier n'a pas pu
  /// être gardé — rien n'est alors écrit.
  Future<bool> addRessource(
    ChapitreRessource ressource, {
    required String coursId,
    Uint8List? bytes,
    required String? schoolId,
    required int nowMs,
    String? authorId,
  }) => _blobs.guarded(() async {
    if (bytes != null && !await _blobs.write(ressource.id, bytes)) return false;
    await _db.transaction((txn) async {
      await txn.insert(ProgrammeTables.ressource, {
        'id': ressource.id,
        'chapitre_id': ressource.chapitreId,
        'cours_id': coursId,
        'type': ressource.type.wireValue,
        'nom': ressource.nom,
        'url': ressource.url,
        'reference': ressource.reference,
        'taille': ressource.taille,
        'sha256': ressource.sha256,
        'mime_type': ressource.mimeType,
        'file_name': ressource.fileName,
        'sync_status': SyncState.pendingSync.dbValue,
        'updated_at': nowMs,
      });
      await enqueueProgrammeGesture(
        txn,
        entryId: ProgrammeOutbox.ressourceEntry(ressource.id),
        type: ProgrammeOutbox.ressourceType,
        aggregateId: ressource.chapitreId,
        payload: _ressourcePayload(ProgrammePushOp.save, ressource),
        schoolId: schoolId,
        nowMs: nowMs,
        authorId: authorId,
      );
    });
    return true;
  });

  /// Retire une ressource ; son fichier quitte le magasin tout de suite (une
  /// ressource accusée se retélécharge si son retrait est refusé).
  Future<void> deleteRessource(
    String ressourceId, {
    required String? schoolId,
    required int nowMs,
    String? authorId,
  }) async {
    await _db.transaction((txn) async {
      final row = await _row(txn, ProgrammeTables.ressource, ressourceId);
      if (row == null) return;
      await _retire(txn, ProgrammeTables.ressource, row, nowMs);
      final ressource = ChapitreRessourceRowMapper.toEntity(row);
      await enqueueProgrammeGesture(
        txn,
        entryId: ProgrammeOutbox.ressourceEntry(ressourceId),
        type: ProgrammeOutbox.ressourceType,
        aggregateId: ressource.chapitreId,
        payload: _ressourcePayload(ProgrammePushOp.delete, ressource),
        schoolId: schoolId,
        nowMs: nowMs,
        authorId: authorId,
      );
    });
    await _blobs.delete(ressourceId);
  }

  static Map<String, Object?> _ressourcePayload(
    ProgrammePushOp op,
    ChapitreRessource r,
  ) => ChapitreRessourcePayload(
    op: op,
    chapitreId: r.chapitreId,
    ressource: ChapitreRessourceDto(
      id: r.id,
      type: r.type.wireValue,
      nom: r.nom,
      url: r.url,
      reference: r.reference,
      taille: r.taille,
      sha256: r.sha256,
      mimeType: r.mimeType,
      fileName: r.fileName,
    ),
  ).toJson();

  static Future<Map<String, Object?>?> _row(
    DatabaseExecutor txn,
    String table,
    String id,
  ) async => (await txn.query(
    table,
    where: 'id = ? AND deleted_at IS NULL',
    whereArgs: [id],
  )).firstOrNull;

  /// Jamais accusé (en attente ou refusé) : la ligne part. Accusé : elle est
  /// masquée jusqu'à l'accusé de son retrait.
  static Future<void> _retire(
    DatabaseExecutor txn,
    String table,
    Map<String, Object?> row,
    int nowMs,
  ) async {
    if (row['sync_status'] != SyncState.synced.dbValue) {
      await txn.delete(table, where: 'id = ?', whereArgs: [row['id']]);
      return;
    }
    await txn.update(
      table,
      {
        'deleted_at': EpochIsoHelper.toIso(nowMs),
        'sync_status': SyncState.pendingSync.dbValue,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }
}
