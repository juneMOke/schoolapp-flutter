import 'dart:typed_data';

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
/// Retirer ce que le serveur n'a jamais accusé ne part pas : l'ajout en
/// attente est neutralisé et la ligne disparaît — l'ajout puis le retrait
/// d'une note jamais envoyée n'en font aucun.
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
    await _enqueue(
      txn,
      ProgrammeOutbox.noteEntry(note.id),
      ProgrammeOutbox.noteType,
      note.chapitreId,
      payload.toJson(),
      schoolId,
      nowMs,
    );
  });

  Future<void> deleteNote(
    String noteId, {
    required String? schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final row = await _row(txn, ProgrammeTables.note, noteId);
    if (row == null) return;
    final chapitreId = row['chapitre_id'] as String;
    if (await _dropIfLocalOnly(
      txn,
      ProgrammeTables.note,
      row,
      ProgrammeOutbox.noteEntry(noteId),
    )) {
      return;
    }
    await _markDeleting(txn, ProgrammeTables.note, noteId, nowMs);
    await _enqueue(
      txn,
      ProgrammeOutbox.noteEntry(noteId),
      ProgrammeOutbox.noteType,
      chapitreId,
      ChapitreNotePayload(
        op: ProgrammePushOp.delete,
        id: noteId,
        chapitreId: chapitreId,
      ).toJson(),
      schoolId,
      nowMs,
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
      await _enqueue(
        txn,
        ProgrammeOutbox.ressourceEntry(ressource.id),
        ProgrammeOutbox.ressourceType,
        ressource.chapitreId,
        ChapitreRessourcePayload(
          op: ProgrammePushOp.save,
          chapitreId: ressource.chapitreId,
          ressource: _dtoOf(ressource),
        ).toJson(),
        schoolId,
        nowMs,
      );
    });
    return true;
  });

  /// Retire une ressource ; son fichier quitte le magasin tout de suite.
  Future<void> deleteRessource(
    String ressourceId, {
    required String? schoolId,
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      final row = await _row(txn, ProgrammeTables.ressource, ressourceId);
      if (row == null) return;
      if (await _dropIfLocalOnly(
        txn,
        ProgrammeTables.ressource,
        row,
        ProgrammeOutbox.ressourceEntry(ressourceId),
      )) {
        return;
      }
      await _markDeleting(txn, ProgrammeTables.ressource, ressourceId, nowMs);
      final chapitreId = row['chapitre_id'] as String;
      await _enqueue(
        txn,
        ProgrammeOutbox.ressourceEntry(ressourceId),
        ProgrammeOutbox.ressourceType,
        chapitreId,
        ChapitreRessourcePayload(
          op: ProgrammePushOp.delete,
          chapitreId: chapitreId,
          ressource: _dtoOf(ChapitreRessourceRowMapper.toEntity(row)),
        ).toJson(),
        schoolId,
        nowMs,
      );
    });
    await _blobs.delete(ressourceId);
  }

  static ChapitreRessourceDto _dtoOf(ChapitreRessource r) =>
      ChapitreRessourceDto(
        id: r.id,
        type: r.type.wireValue,
        nom: r.nom,
        url: r.url,
        reference: r.reference,
        taille: r.taille,
        sha256: r.sha256,
        mimeType: r.mimeType,
        fileName: r.fileName,
      );

  static Future<Map<String, Object?>?> _row(
    DatabaseExecutor txn,
    String table,
    String id,
  ) async => (await txn.query(
    table,
    where: 'id = ? AND deleted_at IS NULL',
    whereArgs: [id],
  )).firstOrNull;

  /// Un ajout jamais accusé (en attente ou refusé) : la ligne part, l'ajout
  /// est neutralisé, rien ne part au serveur.
  static Future<bool> _dropIfLocalOnly(
    DatabaseExecutor txn,
    String table,
    Map<String, Object?> row,
    String entryId,
  ) async {
    if (row['sync_status'] == SyncState.synced.dbValue) return false;
    await ProgrammeOutbox.neutralize(txn, [entryId]);
    await txn.delete(table, where: 'id = ?', whereArgs: [row['id']]);
    return true;
  }

  static Future<void> _markDeleting(
    DatabaseExecutor txn,
    String table,
    String id,
    int nowMs,
  ) => txn.update(
    table,
    {
      'deleted_at': programmeInstant(nowMs),
      'sync_status': SyncState.pendingSync.dbValue,
      'updated_at': nowMs,
    },
    where: 'id = ?',
    whereArgs: [id],
  );

  static Future<void> _enqueue(
    DatabaseExecutor txn,
    String entryId,
    String type,
    String chapitreId,
    Map<String, Object?> payload,
    String? schoolId,
    int nowMs,
  ) => enqueueProgrammeGesture(
    txn,
    entryId: entryId,
    type: type,
    aggregateId: chapitreId,
    payload: payload,
    schoolId: schoolId,
    nowMs: nowMs,
  );
}
