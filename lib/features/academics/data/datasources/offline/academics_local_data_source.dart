import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';

/// Accès sqflite aux tables d'écriture Notes/Cours (`evaluation` régime A,
/// `note_evaluation` régime C). Chaque écriture locale et son enfilage d'outbox
/// se font dans **une seule transaction** (atomicité « saisie enregistrée /
/// entrée de push créée » — jamais l'un sans l'autre).
class AcademicsLocalDataSource {
  final Database _db;

  const AcademicsLocalDataSource(this._db);

  static const String evaluationTable = 'evaluation';
  static const String noteTable = 'note_evaluation';

  // ── Lectures du chemin d'écriture ───────────────────────────────────────────

  Future<EvaluationRow?> getEvaluation(String id) async {
    final rows = await _db.query(
      evaluationTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return EvaluationRow.fromMap(rows.first);
  }

  /// Toutes les notes d'une évaluation (clé de résolution de la grille de
  /// saisie), triées par élève pour un affichage stable.
  Future<List<NoteEvaluationRow>> getNotesForEvaluation(
    String evaluationId,
  ) async {
    final rows = await _db.query(
      noteTable,
      where: 'evaluation_id = ?',
      whereArgs: [evaluationId],
      orderBy: 'student_id ASC',
    );
    return rows.map(NoteEvaluationRow.fromMap).toList(growable: false);
  }

  /// Notes encore à pousser d'une évaluation (alimente le payload de lot).
  Future<List<NoteEvaluationRow>> getPendingNotesForEvaluation(
    String evaluationId,
  ) async {
    final rows = await _db.query(
      noteTable,
      where: 'evaluation_id = ? AND sync_status = ?',
      whereArgs: [evaluationId, SyncState.pendingSync.dbValue],
      orderBy: 'student_id ASC',
    );
    return rows.map(NoteEvaluationRow.fromMap).toList(growable: false);
  }

  // ── Écritures (régime A / régime C) ─────────────────────────────────────────

  /// Création d'une évaluation (**régime A**) : INSERT + entrée d'outbox, dans
  /// une seule transaction. `ConflictAlgorithm.replace` = idempotent sur l'uuid
  /// client (un rejeu local ne duplique jamais).
  Future<void> createEvaluationWithOutbox({
    required EvaluationRow row,
    required OutboxEntry outboxEntry,
  }) async {
    await _db.transaction((txn) async {
      await txn.insert(
        evaluationTable,
        row.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await OutboxDao(txn).enqueue(outboxEntry);
    });
  }

  /// Saisie/correction d'un lot de notes (**régime C**, LWW) dans une seule
  /// transaction :
  /// 1. upsert de chaque note entrante sur la clé naturelle
  ///    `(evaluation_id, student_id)`, appliqué **seulement si plus récent**
  ///    (`updatedAt >= local`) — une note stale est ignorée sans effet ;
  /// 2. **re-lecture, dans la même transaction**, de TOUTES les notes encore
  ///    `PENDING_SYNC` de l'évaluation, pour construire un payload de lot
  ///    **coalescé** (l'entrée d'outbox porte l'état courant complet, pas
  ///    seulement les notes de cet appel — sinon une sauvegarde suivante,
  ///    coalescée par `evaluationId`, effacerait de l'outbox les notes
  ///    précédentes) ;
  /// 3. enfilage de l'entrée construite par [buildOutboxEntry].
  ///
  /// Renvoie les notes `PENDING_SYNC` gelées dans le payload.
  Future<List<NoteEvaluationRow>> upsertNotesWithOutbox({
    required String evaluationId,
    required List<NoteEvaluationRow> incoming,
    required OutboxEntry Function(List<NoteEvaluationRow> pending)
    buildOutboxEntry,
  }) async {
    late List<NoteEvaluationRow> pending;
    await _db.transaction((txn) async {
      for (final note in incoming) {
        final existing = await txn.query(
          noteTable,
          columns: ['id', 'updated_at'],
          where: 'evaluation_id = ? AND student_id = ?',
          whereArgs: [note.evaluationId, note.studentId],
          limit: 1,
        );
        if (existing.isEmpty) {
          await txn.insert(noteTable, note.toMap());
          continue;
        }
        final localUpdatedAt = existing.first['updated_at'] as int?;
        if (localUpdatedAt == null || note.updatedAt >= localUpdatedAt) {
          await txn.update(
            noteTable,
            {
              'points_obtenus': note.pointsObtenus,
              'statut': note.statut,
              'updated_at': note.updatedAt,
              'sync_status': SyncState.pendingSync.dbValue,
              'synced_at': null,
            },
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        }
        // else : note stale (le local est plus récent) → ignorée (LWW).
      }
      final pendingMaps = await txn.query(
        noteTable,
        where: 'evaluation_id = ? AND sync_status = ?',
        whereArgs: [evaluationId, SyncState.pendingSync.dbValue],
        orderBy: 'student_id ASC',
      );
      pending = pendingMaps
          .map(NoteEvaluationRow.fromMap)
          .toList(growable: false);
      await OutboxDao(txn).enqueue(buildOutboxEntry(pending));
    });
    return pending;
  }

  // ── Réalignement post-ACK (primitives, consommées par les handlers) ─────────

  /// Marque une évaluation SYNCED (+ `server_updated_at`) après ACK du push
  /// (régime A). Garde TOCTOU : ne marque QUE si `updated_at` n'a pas changé
  /// depuis le gel du payload ([updatedAtGuard]) — une évaluation étant immuable,
  /// la garde protège surtout contre un réalignement d'une entrée périmée.
  Future<void> markEvaluationSynced({
    required String id,
    int? serverUpdatedAt,
    required int syncedAt,
    int? updatedAtGuard,
  }) async {
    final values = <String, Object?>{
      'sync_status': SyncState.synced.dbValue,
      'synced_at': syncedAt,
      'server_updated_at': ?serverUpdatedAt,
    };
    await _db.update(
      evaluationTable,
      values,
      where: updatedAtGuard == null ? 'id = ?' : 'id = ? AND updated_at = ?',
      whereArgs: updatedAtGuard == null ? [id] : [id, updatedAtGuard],
    );
  }

  /// Marque SYNCED les notes effectivement appliquées côté serveur (outcome
  /// `APPLIED`/`SUPERSEDED`), **note par note**, avec garde LWW : on ne marque
  /// SYNCED que si la note est toujours `PENDING_SYNC` **et** que son `updated_at`
  /// est resté celui qui a été poussé ([idToPushedUpdatedAt]). Une note ré-éditée
  /// pendant le dispatch garde son `PENDING_SYNC` et sera re-poussée.
  Future<void> markNotesSynced({
    required Map<String, int> idToPushedUpdatedAt,
    int? serverUpdatedAt,
    required int syncedAt,
  }) async {
    if (idToPushedUpdatedAt.isEmpty) return;
    await _db.transaction((txn) async {
      for (final entry in idToPushedUpdatedAt.entries) {
        await txn.update(
          noteTable,
          {
            'sync_status': SyncState.synced.dbValue,
            'synced_at': syncedAt,
            'server_updated_at': ?serverUpdatedAt,
          },
          where: 'id = ? AND updated_at = ? AND sync_status = ?',
          whereArgs: [entry.key, entry.value, SyncState.pendingSync.dbValue],
        );
      }
    });
  }

  /// Marque en erreur (rejet métier terminal, outcome `REJECTED`) les notes
  /// données, avec la même garde LWW que [markNotesSynced] (ne touche pas une
  /// note ré-éditée depuis le push). Le motif de rejet est porté par l'UI, pas
  /// stocké sur la ligne (la table `note_evaluation` n'a pas de colonne d'erreur).
  Future<void> markNotesSyncError({
    required Map<String, int> idToPushedUpdatedAt,
  }) async {
    if (idToPushedUpdatedAt.isEmpty) return;
    await _db.transaction((txn) async {
      for (final entry in idToPushedUpdatedAt.entries) {
        await txn.update(
          noteTable,
          {'sync_status': SyncState.syncError.dbValue},
          where: 'id = ? AND updated_at = ? AND sync_status = ?',
          whereArgs: [entry.key, entry.value, SyncState.pendingSync.dbValue],
        );
      }
    });
  }
}
