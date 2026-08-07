import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_comment_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_pull_models.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_disciplinary_case_row.dart';

/// Accès sqflite à `disciplinary_cases` + `disciplinary_case_comments` (DF-1/B).
/// Écriture locale + enfilage d'outbox dans une seule transaction (atomicité
/// « fait / traitement / commentaire enregistré »). `content` SENSIBLE (chiffré).
class DisciplinaryLocalDataSource {
  final Database _db;

  const DisciplinaryLocalDataSource(this._db);

  static const String table = 'disciplinary_cases';
  static const String commentsTable = 'disciplinary_case_comments';

  /// Cas d'un élève sur une année, du plus récent au plus ancien.
  Future<List<OfflineDisciplinaryCaseRow>> getCasesForStudent({
    required String studentId,
    required String academicYearId,
  }) async {
    final rows = await _db.query(
      table,
      where: 'student_id = ? AND academic_year_id = ?',
      whereArgs: [studentId, academicYearId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(OfflineDisciplinaryCaseRow.fromMap).toList(growable: false);
  }

  Future<OfflineDisciplinaryCaseRow?> getCase(String id) async {
    final rows = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return OfflineDisciplinaryCaseRow.fromMap(rows.first);
  }

  /// Commentaires d'un cas, du plus ancien au plus récent (fil chronologique).
  Future<List<DisciplinaryCommentRow>> getCommentsForCase(String caseId) async {
    final rows = await _db.query(
      commentsTable,
      where: 'disciplinary_case_id = ?',
      whereArgs: [caseId],
      orderBy: 'created_at ASC',
    );
    return rows.map(DisciplinaryCommentRow.fromMap).toList(growable: false);
  }

  /// Nombre de commentaires par cas (pour la liste — `content` non chargé).
  Future<Map<String, int>> commentCounts(List<String> caseIds) async {
    if (caseIds.isEmpty) return const {};
    final placeholders = List.filled(caseIds.length, '?').join(',');
    final rows = await _db.rawQuery(
      'SELECT disciplinary_case_id AS cid, COUNT(*) AS n '
      'FROM $commentsTable WHERE disciplinary_case_id IN ($placeholders) '
      'GROUP BY disciplinary_case_id',
      caseIds,
    );
    return {for (final r in rows) r['cid'] as String: (r['n'] as num).toInt()};
  }

  /// Création du FAIT (régime A) : INSERT du cas + entrée d'outbox (agrégat),
  /// atomiquement. `ConflictAlgorithm.replace` = idempotent sur l'uuid client.
  Future<void> createCaseWithOutbox({
    required OfflineDisciplinaryCaseRow row,
    required OutboxEntry outboxEntry,
  }) async {
    await _db.transaction((txn) async {
      await txn.insert(
        table,
        row.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await OutboxDao(txn).enqueue(outboxEntry);
    });
  }

  /// Traitement (régime C, LWW) : UPDATE status/sanction si `updatedAt` >= local,
  /// + entrée d'outbox (agrégat re-figé), atomiquement.
  Future<void> updateCaseWithOutbox({
    required String caseId,
    required String status,
    required String? sanction,
    required int updatedAt,
    required OutboxEntry outboxEntry,
  }) async {
    await _db.transaction((txn) async {
      final existing = await txn.query(
        table,
        columns: ['updated_at'],
        where: 'id = ?',
        whereArgs: [caseId],
        limit: 1,
      );
      final localUpdatedAt = existing.isEmpty
          ? null
          : (existing.first['updated_at'] as int?);
      if (localUpdatedAt == null || updatedAt >= localUpdatedAt) {
        await txn.update(
          table,
          {
            'status': status,
            'sanction': sanction,
            'updated_at': updatedAt,
            'sync_status': SyncState.pendingSync.dbValue,
            'synced_at': null,
          },
          where: 'id = ?',
          whereArgs: [caseId],
        );
      }
      await OutboxDao(txn).enqueue(outboxEntry);
    });
  }

  /// Ajout d'un commentaire (append-only, régime A) : INSERT du commentaire +
  /// **bump de `case.updated_at`** (DF-F : sinon la racine ne bouge pas et le cas
  /// n'est jamais re-pullé) + entrée d'outbox (agrégat re-figé), atomiquement.
  Future<void> addCommentWithCaseBump({
    required DisciplinaryCommentRow comment,
    required int caseUpdatedAt,
    required OutboxEntry outboxEntry,
  }) async {
    await _db.transaction((txn) async {
      await txn.insert(
        commentsTable,
        comment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.update(
        table,
        {
          'updated_at': caseUpdatedAt,
          'sync_status': SyncState.pendingSync.dbValue,
          'synced_at': null,
        },
        where: 'id = ?',
        whereArgs: [comment.disciplinaryCaseId],
      );
      await OutboxDao(txn).enqueue(outboxEntry);
    });
  }

  /// Réalignement post-ACK de l'agrégat poussé : marque le cas SYNCED (+
  /// `server_updated_at`) **seulement si le cas n'a pas re-muté depuis le push**
  /// (garde LWW `updated_at = [updatedAtGuard]`), et marque SYNCED les
  /// commentaires effectivement poussés (par id). Un commentaire ajouté après le
  /// dispatch reste PENDING_SYNC et sera re-poussé.
  ///
  /// [winningStatus]/[winningSanction] : sur un ACK `SUPERSEDED` (un état serveur
  /// plus récent existait), on adopte le traitement gagnant renvoyé — sinon le
  /// local resterait sur l'état perdant jusqu'au prochain pull.
  Future<void> markAggregateSynced({
    required String caseId,
    required List<String> commentIds,
    required int? updatedAtGuard,
    int? serverUpdatedAt,
    String? winningStatus,
    String? winningSanction,
    bool applyWinningTreatment = false,
    required int syncedAt,
  }) async {
    await _db.transaction((txn) async {
      final caseValues = <String, Object?>{
        'sync_status': SyncState.synced.dbValue,
        'synced_at': syncedAt,
        'server_updated_at': ?serverUpdatedAt,
        if (applyWinningTreatment) 'status': winningStatus,
        if (applyWinningTreatment) 'sanction': winningSanction,
      };
      if (updatedAtGuard == null) {
        await txn.update(
          table,
          caseValues,
          where: 'id = ?',
          whereArgs: [caseId],
        );
      } else {
        await txn.update(
          table,
          caseValues,
          where: 'id = ? AND updated_at = ?',
          whereArgs: [caseId, updatedAtGuard],
        );
      }
      if (commentIds.isNotEmpty) {
        final placeholders = List.filled(commentIds.length, '?').join(',');
        await txn.update(
          commentsTable,
          {'sync_status': SyncState.synced.dbValue, 'synced_at': syncedAt},
          where: 'id IN ($placeholders)',
          whereArgs: commentIds,
        );
      }
    });
  }

  /// Applique un lot de cas pullés (upsert par uuid + commentaires imbriqués).
  /// Renvoie le nombre de cas **effectivement** appliqués.
  ///
  /// Money-grade — le pull **ne clobbère jamais une écriture locale non
  /// synchronisée** : un cas local `PENDING_SYNC` (créé/traité hors-ligne, pas
  /// encore poussé) est plus récent que ce que le serveur porte → on le **saute**
  /// (il sera poussé puis réaligné par uuid). Idem pour un commentaire local
  /// non synchronisé (append-only : jamais écrasé par le pull).
  Future<int> applyPulledCases(
    List<PulledDisciplinaryCase> pulled,
    int syncedAt,
  ) async {
    var applied = 0;
    await applyInBatches<PulledDisciplinaryCase>(
      _db,
      pulled,
      apply: (txn, chunk) async {
        for (final item in chunk) {
          final row = item.caseRow;
          final existing = await txn.query(
            table,
            columns: ['sync_status'],
            where: 'id = ?',
            whereArgs: [row.id],
            limit: 1,
          );
          if (existing.isEmpty) {
            // Cas serveur inconnu localement : matérialisé tel quel.
            await txn.insert(table, row.toMap());
          } else {
            // Écriture locale non synchronisée = gagnante : ne pas la remplacer.
            if (existing.first['sync_status'] != SyncState.synced.dbValue) {
              continue;
            }
            // Cas déjà SYNCED re-pullé : **le FAIT est immuable** → on ne
            // réécrit QUE le traitement (status/sanction) + les timestamps de
            // visibilité. Un REPLACE plein effacerait `student_gender` (jamais
            // porté par le delta → 'OTHER'), et blanchirait `content` sensible /
            // les noms / `version` que le delta peut omettre (contrat).
            await txn.update(
              table,
              {
                'status': row.status,
                'sanction': row.sanction,
                'updated_at': row.updatedAt,
                'server_updated_at': row.serverUpdatedAt,
                'sync_status': SyncState.synced.dbValue,
                'synced_at': row.syncedAt,
              },
              where: 'id = ?',
              whereArgs: [row.id],
            );
          }
          for (final comment in item.comments) {
            final existingComment = await txn.query(
              commentsTable,
              columns: ['sync_status'],
              where: 'id = ?',
              whereArgs: [comment.id],
              limit: 1,
            );
            if (existingComment.isNotEmpty &&
                existingComment.first['sync_status'] !=
                    SyncState.synced.dbValue) {
              continue; // commentaire local pending : ne pas écraser.
            }
            await txn.insert(
              commentsTable,
              comment.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          applied++;
        }
      },
    );
    return applied;
  }
}
