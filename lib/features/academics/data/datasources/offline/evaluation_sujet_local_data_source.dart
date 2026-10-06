import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/evaluation_sujet_row.dart';

/// Accès sqflite au **sujet** d'une évaluation — les colonnes `sujet_*` et le
/// cadre de la ligne `evaluation`, sous-agrégat LWW à statut propre.
///
/// Le sujet se remplace d'un bloc ; son écriture et son entrée d'outbox se font
/// dans une seule transaction. L'accusé et le refus sont gardés par
/// `sujet_updated_at` : un sujet ré-édité pendant l'envoi reste en attente.
class EvaluationSujetLocalDataSource {
  final Database _db;

  const EvaluationSujetLocalDataSource(this._db);

  static const String _table = 'evaluation';

  /// Le sujet d'une évaluation ; `null` si l'évaluation n'existe pas.
  Future<EvaluationSujetRow?> getSujet(String evaluationId) async {
    final rows = await _db.query(
      _table,
      columns: EvaluationSujetRow.columns,
      where: 'id = ?',
      whereArgs: [evaluationId],
      limit: 1,
    );
    return rows.isEmpty ? null : EvaluationSujetRow.fromMap(rows.first);
  }

  /// Enregistre le sujet (statut `PENDING_SYNC`) et, si fourni, le nouveau
  /// [maxPoints] de l'évaluation, puis enfile l'entrée que construit
  /// [buildOutboxEntry] à partir du maximum relu — le tout dans une
  /// transaction. Renvoie `false` si l'évaluation n'existe pas (rien n'est
  /// écrit, aucune entrée n'est enfilée).
  Future<bool> saveSujet({
    required String evaluationId,
    required EvaluationSujetRow sujet,
    double? maxPoints,
    OutboxEntry Function(double maxPoints)? buildOutboxEntry,
  }) => _db.transaction((txn) async {
    final updated = await txn.update(
      _table,
      {
        ...sujet.toMap(),
        'sujet_sync_status': SyncState.pendingSync.dbValue,
        'sujet_rejection_code': null,
        'max_points': ?maxPoints,
      },
      where: 'id = ?',
      whereArgs: [evaluationId],
    );
    if (updated == 0) return false;
    if (buildOutboxEntry != null) {
      final rows = await txn.query(
        _table,
        columns: ['max_points'],
        where: 'id = ?',
        whereArgs: [evaluationId],
      );
      final max = (rows.single['max_points'] as num).toDouble();
      await OutboxDao(txn).enqueue(buildOutboxEntry(max));
    }
    return true;
  });

  /// Accusé : le sujet envoyé à [pushedUpdatedAt] passe `SYNCED`, sauf s'il a
  /// été ré-édité depuis.
  Future<void> markSujetSynced({
    required String evaluationId,
    required int pushedUpdatedAt,
  }) async {
    await _db.update(
      _table,
      {
        'sujet_sync_status': SyncState.synced.dbValue,
        'sujet_rejection_code': null,
      },
      where: 'id = ? AND sujet_updated_at = ?',
      whereArgs: [evaluationId, pushedUpdatedAt],
    );
  }

  /// Refus terminal du sujet envoyé à [pushedUpdatedAt], avec son code ; le
  /// brouillon reste lisible et modifiable.
  Future<void> markSujetSyncError({
    required String evaluationId,
    required int pushedUpdatedAt,
    String? rejectionCode,
  }) async {
    await _db.update(
      _table,
      {
        'sujet_sync_status': SyncState.syncError.dbValue,
        'sujet_rejection_code': rejectionCode,
      },
      where: 'id = ? AND sujet_updated_at = ?',
      whereArgs: [evaluationId, pushedUpdatedAt],
    );
  }

  /// Applique le sujet descendu du serveur sur [executor] (la transaction du
  /// pull). Un sujet local en attente ou refusé gagne : le brouillon reste,
  /// rien n'est écrit. [sujet] porte son statut (`SYNCED`, ou nul si aucun
  /// sujet n'a jamais été envoyé). Renvoie `true` si le sujet a été écrit.
  Future<bool> applyPulledSujet(
    DatabaseExecutor executor, {
    required String evaluationId,
    required EvaluationSujetRow sujet,
  }) async {
    final updated = await executor.update(
      _table,
      sujet.toMap(),
      where: 'id = ? AND (sujet_sync_status IS NULL OR sujet_sync_status = ?)',
      whereArgs: [evaluationId, SyncState.synced.dbValue],
    );
    return updated > 0;
  }

  /// Le serveur a gardé un sujet plus récent que celui envoyé à
  /// [pushedUpdatedAt] : on prend le sien, sauf si le brouillon local a été
  /// ré-édité depuis l'envoi (il repartira).
  Future<void> replaceSupersededSujet({
    required String evaluationId,
    required int pushedUpdatedAt,
    required EvaluationSujetRow serverSujet,
  }) async {
    await _db.update(
      _table,
      serverSujet.toMap(),
      where: 'id = ? AND sujet_updated_at = ?',
      whereArgs: [evaluationId, pushedUpdatedAt],
    );
  }
}
