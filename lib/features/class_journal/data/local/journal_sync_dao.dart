import 'package:school_app_flutter/core/offline/outbox_gesture.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_outbox.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_pull_writer.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_rows.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_push.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Les accusés du serveur sur les saisies du journal, appliqués **sans défaire
/// une saisie locale plus récente** : une ligne dont l'horloge a changé
/// pendant le vol a remis son entrée en file, elle repartira.
class JournalSyncDao {
  final Database _db;

  const JournalSyncDao(this._db);

  /// Accusé d'un envoi. Ligne inchangée depuis l'envoi : l'entrée **retenue**
  /// s'applique telle que le serveur la rend — la sienne si la nôtre était
  /// dépassée, la nôtre détachée si son chapitre avait été supprimé. Ligne
  /// changée : seule l'horloge serveur se pose.
  Future<void> applyAck(
    JournalEntryAck ack, {
    required String? sentClientUpdatedAt,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final dto = ack.entry;
    final unchanged =
        await txn.update(
          JournalTables.entry,
          JournalPullWriter.syncedColumnsOf(dto, nowMs: nowMs),
          where: 'id = ? AND client_updated_at IS ?',
          whereArgs: [dto.id, sentClientUpdatedAt],
        ) >
        0;
    if (!unchanged) {
      await txn.update(
        JournalTables.entry,
        {'server_updated_at': dto.serverUpdatedAt},
        where: 'id = ?',
        whereArgs: [dto.id],
      );
    }
  });

  /// Refus déterministe : « à corriger », sauf si une saisie plus récente l'a
  /// remplacée pendant le vol (rend `false` : elle repartira).
  Future<bool> markRejected(
    String entryId, {
    required String? sentClientUpdatedAt,
    required String code,
    required int nowMs,
  }) async =>
      await _db.update(
        JournalTables.entry,
        {
          'sync_status': SyncState.syncError.dbValue,
          'sync_error_code': code,
          'updated_at': nowMs,
        },
        where: 'id = ? AND client_updated_at IS ?',
        whereArgs: [entryId, sentClientUpdatedAt],
      ) >
      0;

  /// L'entrée de file de [entryId] a-t-elle été remplacée par une saisie plus
  /// récente depuis l'envoi de celle créée à [sentCreatedAt] ?
  Future<bool> entryReplaced(String entryId, int sentCreatedAt) =>
      OutboxGestures.replacedSince(
        _db,
        JournalOutbox.entry(entryId),
        sentCreatedAt,
      );
}
