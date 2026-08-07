import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';

/// État canonique serveur (`NoteSyncView`) à écrire sur une note lors du
/// réalignement post-ACK — `null` si le serveur n'a pas renvoyé de `note`
/// exploitable pour cette ligne (parsing tolérant, DF-I).
class NoteCanonicalState {
  final double? pointsObtenus;
  final String statut;

  /// Epoch ms — `null` → on garde [NoteSyncAck.pushedUpdatedAt].
  final int? updatedAt;

  /// Epoch ms — temps de visibilité serveur (curseur), propre à cette note.
  final int? serverUpdatedAt;

  const NoteCanonicalState({
    this.pointsObtenus,
    required this.statut,
    this.updatedAt,
    this.serverUpdatedAt,
  });
}

/// Instruction de réalignement d'UNE note après ACK — [pushedUpdatedAt] sert
/// de garde LWW (n'aligne que si la note poussée n'a pas été ré-éditée depuis).
class NoteSyncAck {
  final int pushedUpdatedAt;
  final NoteCanonicalState? canonical;

  const NoteSyncAck({required this.pushedUpdatedAt, this.canonical});
}

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

  /// Évaluations d'un cours (composition du détail cours), triées par date.
  Future<List<EvaluationRow>> getEvaluationsForCours(String coursId) async {
    final rows = await _db.query(
      evaluationTable,
      where: 'cours_id = ?',
      whereArgs: [coursId],
      orderBy: 'eval_date ASC',
    );
    return rows.map(EvaluationRow.fromMap).toList(growable: false);
  }

  /// Nombre de notes SAISIES par évaluation (statut NOTEE) pour une liste
  /// d'évaluations — alimente le taux de saisie du détail. Absent = 0.
  /// Les notes `SYNC_ERROR` (rejetées terminalement par le serveur) sont
  /// EXCLUES : elles ne doivent pas gonfler le taux et faire croire « saisie
  /// complète » alors que le serveur les a refusées.
  Future<Map<String, int>> notedCountByEvaluation(
    List<String> evaluationIds,
  ) async {
    if (evaluationIds.isEmpty) return const {};
    final placeholders = List.filled(evaluationIds.length, '?').join(',');
    final rows = await _db.rawQuery(
      'SELECT evaluation_id AS eid, COUNT(*) AS n FROM $noteTable '
      "WHERE evaluation_id IN ($placeholders) AND statut = 'NOTEE' "
      "AND sync_status != '${SyncState.syncError.dbValue}' "
      'GROUP BY evaluation_id',
      evaluationIds,
    );
    return {for (final r in rows) r['eid'] as String: (r['n'] as num).toInt()};
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

  /// Notes de plusieurs évaluations, groupées par `evaluation_id` — alimente
  /// la moyenne indicative (ADR-006/FRONT §8). Même exclusion que
  /// [notedCountByEvaluation] : les notes `SYNC_ERROR` (rejetées terminalement
  /// par le serveur) sont EXCLUES, elles ne doivent pas fausser la moyenne
  /// affichée avec une valeur que le serveur a refusée.
  Future<Map<String, List<NoteEvaluationRow>>> getNotesForEvaluations(
    List<String> evaluationIds,
  ) async {
    if (evaluationIds.isEmpty) return const {};
    final placeholders = List.filled(evaluationIds.length, '?').join(',');
    final rows = await _db.query(
      noteTable,
      where:
          'evaluation_id IN ($placeholders) '
          "AND sync_status != '${SyncState.syncError.dbValue}'",
      whereArgs: evaluationIds,
      orderBy: 'student_id ASC',
    );
    final byEvaluation = <String, List<NoteEvaluationRow>>{};
    for (final row in rows) {
      final note = NoteEvaluationRow.fromMap(row);
      (byEvaluation[note.evaluationId] ??= []).add(note);
    }
    return byEvaluation;
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
        // Saisie UTILISATEUR : gagne toujours (geste explicite, jamais un
        // replay). Horloge **monotone** — l'`updated_at` avance au-delà du local
        // (`local + 1` si l'horloge device est en retard) : une correction
        // survit à un skew serveur / une horloge qui recule (le local peut
        // porter l'horloge serveur après un pull) ET bat le LWW serveur au push.
        final localUpdatedAt = (existing.first['updated_at'] as int?) ?? 0;
        final effectiveUpdatedAt = note.updatedAt > localUpdatedAt
            ? note.updatedAt
            : localUpdatedAt + 1;
        await txn.update(
          noteTable,
          {
            'points_obtenus': note.pointsObtenus,
            'statut': note.statut,
            'updated_at': effectiveUpdatedAt,
            'sync_status': SyncState.pendingSync.dbValue,
            'synced_at': null,
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
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
  /// `APPLIED`/`SUPERSEDED`), **note par note**, résolues par la **clé naturelle**
  /// `(evaluationId, studentId)` (la forme de la réponse serveur), avec garde
  /// LWW : on ne marque SYNCED que si la note est toujours `PENDING_SYNC` **et**
  /// que son `updated_at` est resté celui qui a été poussé
  /// ([NoteSyncAck.pushedUpdatedAt]). Une note ré-éditée pendant le dispatch
  /// garde son `PENDING_SYNC` et sera re-poussée.
  ///
  /// Quand [NoteSyncAck.canonical] est renseigné (état `NoteSyncView` renvoyé
  /// par le serveur), le local est **réaligné** sur cet état — indispensable
  /// sur un `SUPERSEDED` : la valeur poussée par CE client a perdu le LWW face
  /// à un état serveur plus récent, le local doit refléter ce dernier, pas ce
  /// qui a été envoyé. Sans `canonical` (parsing tolérant, outcome sans `note`
  /// exploitable), on se contente de basculer `sync_status` sans toucher aux
  /// valeurs — comportement de repli inchangé.
  Future<void> markNotesSynced({
    required String evaluationId,
    required Map<String, NoteSyncAck> studentIdToAck,
    required int syncedAt,
  }) async {
    if (studentIdToAck.isEmpty) return;
    await _db.transaction((txn) async {
      for (final entry in studentIdToAck.entries) {
        final ack = entry.value;
        final canonical = ack.canonical;
        final values = <String, Object?>{
          'sync_status': SyncState.synced.dbValue,
          'synced_at': syncedAt,
          if (canonical != null) ...{
            'points_obtenus': canonical.pointsObtenus,
            'statut': canonical.statut,
            'updated_at': canonical.updatedAt ?? ack.pushedUpdatedAt,
            'server_updated_at': ?canonical.serverUpdatedAt,
          },
        };
        await txn.update(
          noteTable,
          values,
          where:
              'evaluation_id = ? AND student_id = ? AND updated_at = ? '
              'AND sync_status = ?',
          whereArgs: [
            evaluationId,
            entry.key,
            ack.pushedUpdatedAt,
            SyncState.pendingSync.dbValue,
          ],
        );
      }
    });
  }

  /// Marque en erreur (rejet métier terminal, outcome `REJECTED`) les notes
  /// données, résolues par la clé naturelle `(evaluationId, studentId)`, avec la
  /// même garde LWW que [markNotesSynced] (ne touche pas une note ré-éditée
  /// depuis le push). [studentIdToReason] persiste le motif serveur
  /// (`UNKNOWN_EVALUATION`/`PERIODE_CLOSE`/`INVALID: …`/
  /// `EVALUATION_CONTEXT_UNAVAILABLE`) — surfacé à l'UI, jamais perdu en silence.
  Future<void> markNotesSyncError({
    required String evaluationId,
    required Map<String, int> studentIdToPushedUpdatedAt,
    Map<String, String?> studentIdToReason = const {},
  }) async {
    if (studentIdToPushedUpdatedAt.isEmpty) return;
    await _db.transaction((txn) async {
      for (final entry in studentIdToPushedUpdatedAt.entries) {
        await txn.update(
          noteTable,
          {
            'sync_status': SyncState.syncError.dbValue,
            'rejection_reason': studentIdToReason[entry.key],
          },
          where:
              'evaluation_id = ? AND student_id = ? AND updated_at = ? '
              'AND sync_status = ?',
          whereArgs: [
            evaluationId,
            entry.key,
            entry.value,
            SyncState.pendingSync.dbValue,
          ],
        );
      }
    });
  }

  /// Marque une évaluation `SYNC_ERROR` (backstop `422` terminal à la création,
  /// DF-N : `PERIOD_CLOSED`/`EXAM_NOT_ALLOWED`/`MAX_REACHED`), persistant le
  /// code pour surfaçage UI. Même garde TOCTOU que [markEvaluationSynced] — une
  /// évaluation étant immuable, elle protège surtout contre un réalignement
  /// d'une entrée périmée.
  Future<void> markEvaluationSyncError({
    required String id,
    String? rejectionCode,
    int? updatedAtGuard,
  }) async {
    await _db.update(
      evaluationTable,
      {
        'sync_status': SyncState.syncError.dbValue,
        'rejection_code': rejectionCode,
      },
      where: updatedAtGuard == null ? 'id = ?' : 'id = ? AND updated_at = ?',
      whereArgs: updatedAtGuard == null ? [id] : [id, updatedAtGuard],
    );
  }

  // ── Application du pull métier (skip PENDING_SYNC : jamais de clobber) ───────

  /// Applique un lot d'évaluations pullées (régime A). Money-grade : une
  /// évaluation locale `PENDING_SYNC` (créée offline, pas encore poussée) est
  /// **sautée** (elle sera poussée puis réalignée par uuid). Une ligne
  /// `SYNC_ERROR` (rejetée TERMINALEMENT par le serveur) est en revanche
  /// **réconciliée** : la vérité serveur remplace un état que le serveur a
  /// refusé — sinon la ligne rejetée survivrait à jamais comme si elle était
  /// valide. Une évaluation absente est matérialisée SYNCED ; une déjà SYNCED
  /// est rafraîchie (fait immuable : REPLACE sans risque). Renvoie le nombre
  /// appliqué.
  Future<int> applyPulledEvaluations(List<EvaluationRow> rows) async {
    var applied = 0;
    await applyInBatches<EvaluationRow>(
      _db,
      rows,
      apply: (txn, chunk) async {
        for (final row in chunk) {
          final existing = await txn.query(
            evaluationTable,
            columns: ['sync_status'],
            where: 'id = ?',
            whereArgs: [row.id],
            limit: 1,
          );
          if (existing.isNotEmpty &&
              existing.first['sync_status'] == SyncState.pendingSync.dbValue) {
            continue; // écriture locale en attente de push = gagnante.
          }
          await txn.insert(
            evaluationTable,
            row.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          applied++;
        }
      },
    );
    return applied;
  }

  /// Applique un lot de notes pullées (régime C, clé naturelle). Même garde :
  /// une note locale `PENDING_SYNC` est **sautée** (jamais clobber d'une
  /// écriture en attente de push) ; une `SYNC_ERROR` (rejet terminal) est
  /// **réconciliée** par la vérité serveur (arbitrage période close, etc.).
  /// Une note absente est insérée SYNCED (id serveur) ; une existante est
  /// rafraîchie **en conservant l'id de transport local** (pas de réécriture
  /// de PK).
  Future<int> applyPulledNotes(List<NoteEvaluationRow> rows) async {
    var applied = 0;
    await applyInBatches<NoteEvaluationRow>(
      _db,
      rows,
      apply: (txn, chunk) async {
        for (final row in chunk) {
          final existing = await txn.query(
            noteTable,
            columns: ['id', 'sync_status'],
            where: 'evaluation_id = ? AND student_id = ?',
            whereArgs: [row.evaluationId, row.studentId],
            limit: 1,
          );
          if (existing.isEmpty) {
            // `replace` défensif : une collision de PK `id` inattendue (payload
            // serveur pathologique) ne doit pas lever et figer le curseur.
            await txn.insert(
              noteTable,
              row.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            applied++;
            continue;
          }
          if (existing.first['sync_status'] == SyncState.pendingSync.dbValue) {
            continue; // écriture locale en attente de push = gagnante.
          }
          await txn.update(
            noteTable,
            {
              'points_obtenus': row.pointsObtenus,
              'statut': row.statut,
              'updated_at': row.updatedAt,
              'server_updated_at': row.serverUpdatedAt,
              'sync_status': SyncState.synced.dbValue,
              'synced_at': row.syncedAt,
            },
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
          applied++;
        }
      },
    );
    return applied;
  }

  // ── Réconciliation (DF-L) — cours perdu (réaffectation prof) ────────────────

  /// Purge les évaluations d'un cours évincé (référence perdue — réaffectation,
  /// garde d'ownership 403) et leurs notes, dans une seule transaction. Emporte
  /// aussi le contenu `PENDING_SYNC` non encore poussé : une fois le cours
  /// perdu, ce travail ne peut plus être poussé (le serveur le rejetterait en
  /// 403 à son tour) — ce n'est pas une perte due à un bug de synchro, mais une
  /// conséquence légitime de la perte d'accès.
  Future<void> evictCoursData(String coursId) async {
    await _db.transaction((txn) async {
      final evalRows = await txn.query(
        evaluationTable,
        columns: ['id'],
        where: 'cours_id = ?',
        whereArgs: [coursId],
      );
      final evalIds = evalRows.map((r) => r['id'] as String).toList();
      if (evalIds.isNotEmpty) {
        final placeholders = List.filled(evalIds.length, '?').join(',');
        await txn.delete(
          noteTable,
          where: 'evaluation_id IN ($placeholders)',
          whereArgs: evalIds,
        );
      }
      await txn.delete(
        evaluationTable,
        where: 'cours_id = ?',
        whereArgs: [coursId],
      );
    });
  }
}
