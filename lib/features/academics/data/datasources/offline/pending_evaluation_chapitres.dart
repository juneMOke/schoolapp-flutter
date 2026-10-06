import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_input_model.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_push_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/repositories/offline/evaluation_offline_repository_impl.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les chapitres cités par les évaluations **pas encore accusées**.
///
/// Un chapitre supprimé avant d'avoir jamais été envoyé ne partira jamais : le
/// serveur refuserait toute évaluation qui le cite (409
/// `CHAPITRE_NOT_YET_SYNCED`) — indéfiniment. Il est donc retiré de ces
/// évaluations, **ligne et payload d'outbox** ensemble : l'évaluation est
/// immuable une fois partie, mais tant qu'elle attend, c'est son payload qui
/// partira.
class PendingEvaluationChapitres {
  PendingEvaluationChapitres._();

  /// Retire [chapitreId] des évaluations en attente, dans la transaction de
  /// l'appelant. Rend le nombre d'évaluations touchées.
  static Future<int> detach(DatabaseExecutor txn, String chapitreId) async {
    final rows = await txn.query(
      'evaluation',
      where: 'sync_status <> ? AND chapitre_ids_json LIKE ?',
      whereArgs: [SyncState.synced.dbValue, '%"$chapitreId"%'],
    );
    var touched = 0;
    for (final map in rows) {
      final row = EvaluationRow.fromMap(map);
      final kept = [
        for (final id in row.chapitreIds)
          if (id != chapitreId) id,
      ];
      if (kept.length == row.chapitreIds.length) continue;
      await txn.update(
        'evaluation',
        {'chapitre_ids_json': EvaluationRow.encodeChapitreIds(kept)},
        where: 'id = ?',
        whereArgs: [row.id],
      );
      await _rewritePayload(txn, row.id, kept);
      touched++;
    }
    return touched;
  }

  static Future<void> _rewritePayload(
    DatabaseExecutor txn,
    String evaluationId,
    List<String> chapitreIds,
  ) async {
    final entryId = EvaluationOfflineRepositoryImpl.aggregateOutboxId(
      evaluationId,
    );
    final entries = await txn.query(
      OutboxDao.table,
      columns: ['payload'],
      where: 'id = ? AND status <> ?',
      whereArgs: [entryId, OutboxStatus.acked.dbValue],
    );
    if (entries.isEmpty) return;
    final request = EvaluationPushRequestModel.fromJsonString(
      entries.single['payload'] as String,
    );
    final sent = request.evaluation;
    final rewritten = EvaluationPushRequestModel(
      authorId: request.authorId,
      coursId: request.coursId,
      evaluation: EvaluationInputModel(
        id: sent.id,
        coursId: sent.coursId,
        type: sent.type,
        date: sent.date,
        maxPoints: sent.maxPoints,
        poids: sent.poids,
        sousPeriodeId: sent.sousPeriodeId,
        periodeScolaireId: sent.periodeScolaireId,
        chapitreIds: chapitreIds,
      ),
    );
    await txn.update(
      OutboxDao.table,
      {'payload': rewritten.toJsonString()},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }
}
