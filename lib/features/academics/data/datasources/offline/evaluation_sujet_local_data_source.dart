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

  /// Enregistre le sujet (statut `PENDING_SYNC`) et enfile l'entrée que
  /// construit [buildOutboxEntry], dans une transaction. Renvoie l'horloge
  /// retenue (`clientUpdatedAt`), ou `null` si l'évaluation n'existe pas —
  /// rien n'est alors écrit ni enfilé.
  ///
  /// - **Horloge monotone** : `max(now, précédent + 1)`. Une horloge qui
  ///   recule ferait juger le nouvel enregistrement plus ancien que le
  ///   précédent, et le serveur garderait l'ancien.
  /// - **Maximum ajusté** : [maxPoints] (« Ajuster le maximum ») est gardé
  ///   dans `sujet_max_points` tant que le sujet n'est pas accusé —
  ///   `max_points` reste la valeur du serveur, et la lecture de
  ///   l'évaluation retient l'ajustement s'il existe. Il part
  ///   avec chaque enregistrement suivant — un enregistrement sans ajustement
  ///   ne l'efface pas — et seul un ajustement voyage : un maximum inchangé
  ///   est omis (le serveur garde le sien). [dropPendingMax] l'abandonne
  ///   (renvoi après `MAX_LOCKED`).
  Future<int?> saveSujet({
    required String evaluationId,
    required EvaluationSujetRow sujet,
    required int now,
    double? maxPoints,
    bool dropPendingMax = false,
    OutboxEntry Function(int clientUpdatedAt, double? maxPoints)?
    buildOutboxEntry,
  }) => _db.transaction((txn) async {
    final rows = await txn.query(
      _table,
      columns: ['sujet_updated_at', 'sujet_max_points'],
      where: 'id = ?',
      whereArgs: [evaluationId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final previous = (rows.single['sujet_updated_at'] as num?)?.toInt();
    final clientUpdatedAt = previous != null && previous >= now
        ? previous + 1
        : now;
    final pendingMax = dropPendingMax
        ? null
        : maxPoints ?? (rows.single['sujet_max_points'] as num?)?.toDouble();
    await txn.update(
      _table,
      {
        ...sujet.toMap(),
        'sujet_updated_at': clientUpdatedAt,
        'sujet_sync_status': SyncState.pendingSync.dbValue,
        'sujet_rejection_code': null,
        'sujet_max_points': pendingMax,
      },
      where: 'id = ?',
      whereArgs: [evaluationId],
    );
    if (buildOutboxEntry != null) {
      await OutboxDao(
        txn,
      ).enqueue(buildOutboxEntry(clientUpdatedAt, pendingMax));
    }
    return clientUpdatedAt;
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
        'sujet_max_points': null,
      },
      where: 'id = ? AND sujet_updated_at = ?',
      whereArgs: [evaluationId, pushedUpdatedAt],
    );
  }

  /// Refus terminal du sujet envoyé à [pushedUpdatedAt], avec son code ; le
  /// brouillon reste lisible et modifiable.
  ///
  /// [dropPendingMax] : le maximum ajusté est refusé (`MAX_LOCKED`) — la
  /// tablette revient au maximum du serveur.
  Future<void> markSujetSyncError({
    required String evaluationId,
    required int pushedUpdatedAt,
    String? rejectionCode,
    bool dropPendingMax = false,
  }) async {
    await _db.update(
      _table,
      {
        'sujet_sync_status': SyncState.syncError.dbValue,
        'sujet_rejection_code': rejectionCode,
        if (dropPendingMax) 'sujet_max_points': null,
      },
      where: 'id = ? AND sujet_updated_at = ?',
      whereArgs: [evaluationId, pushedUpdatedAt],
    );
  }

  /// Applique le sujet descendu du serveur sur [executor] (la transaction du
  /// pull). Un sujet local en attente ou refusé gagne : le brouillon reste,
  /// rien n'est écrit. Un sujet plus ancien que le local est ignoré. [sujet] porte son statut (`SYNCED`, ou nul si aucun
  /// sujet n'a jamais été envoyé). Renvoie `true` si le sujet a été écrit.
  Future<bool> applyPulledSujet(
    DatabaseExecutor executor, {
    required String evaluationId,
    required EvaluationSujetRow sujet,
  }) async {
    // Garde LWW : une page lue avant l'accusé d'un envoi ne remet pas un
    // sujet plus ancien par-dessus.
    final incoming = sujet.updatedAt;
    final updated = await executor.update(
      _table,
      sujet.toMap(),
      where:
          'id = ? AND (sujet_sync_status IS NULL OR sujet_sync_status = ?) '
          'AND (sujet_updated_at IS NULL OR '
          '(? IS NOT NULL AND sujet_updated_at <= ?))',
      whereArgs: [evaluationId, SyncState.synced.dbValue, incoming, incoming],
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
      {...serverSujet.toMap(), 'sujet_max_points': null},
      where: 'id = ? AND sujet_updated_at = ?',
      whereArgs: [evaluationId, pushedUpdatedAt],
    );
  }
}
