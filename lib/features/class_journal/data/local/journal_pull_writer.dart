import 'package:school_app_flutter/core/offline/lww_clock.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_rows.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_entry_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Range en local les entrées descendues, **sans jamais écraser une saisie
/// locale plus récente** : une ligne qui attend (envoi en attente ou refusé)
/// n'est remplacée que si l'entrée serveur est plus récente qu'elle
/// (`clientUpdatedAt`).
class JournalPullWriter {
  final Database _db;

  const JournalPullWriter(this._db);

  /// Rend le nombre d'entrées écrites.
  Future<int> apply(List<JournalEntryDto> entries, {required int nowMs}) {
    if (entries.isEmpty) return Future.value(0);
    return _db.transaction((txn) async {
      var written = 0;
      for (final dto in entries) {
        if (await _apply(txn, dto, nowMs)) written++;
      }
      return written;
    });
  }

  Future<bool> _apply(
    DatabaseExecutor txn,
    JournalEntryDto dto,
    int nowMs,
  ) async {
    final local = (await txn.query(
      JournalTables.entry,
      columns: ['sync_status', 'client_updated_at'],
      where: 'id = ?',
      whereArgs: [dto.id],
      limit: 1,
    )).firstOrNull;
    if (local == null) {
      await txn.insert(JournalTables.entry, {
        'id': dto.id,
        'cours_id': dto.coursId,
        'date_seance': dto.date,
        'time_slot_id': dto.timeSlotId,
        ...syncedColumnsOf(dto, nowMs: nowMs),
      });
      return true;
    }
    if (local['sync_status'] != SyncState.synced.dbValue &&
        !isNewerClock(dto.clientUpdatedAt, local['client_updated_at'])) {
      // La saisie locale est la plus récente : elle partira.
      await txn.update(
        JournalTables.entry,
        {'server_updated_at': dto.serverUpdatedAt},
        where: 'id = ?',
        whereArgs: [dto.id],
      );
      return false;
    }
    await txn.update(
      JournalTables.entry,
      syncedColumnsOf(dto, nowMs: nowMs),
      where: 'id = ?',
      whereArgs: [dto.id],
    );
    return true;
  }

  /// L'entrée serveur [dto], synchronisée, telle qu'elle se range — sans les
  /// colonnes d'identité, que l'appelant pose ou garde.
  static Map<String, Object?> syncedColumnsOf(
    JournalEntryDto dto, {
    required int nowMs,
  }) => {
    ...JournalRowMapper.fieldColumns(
      chapitreId: dto.chapitreId,
      fields: dto.fields,
    ),
    'client_updated_at': dto.clientUpdatedAt,
    'server_updated_at': dto.serverUpdatedAt,
    'sync_status': SyncState.synced.dbValue,
    'sync_error_code': null,
    'updated_at': nowMs,
  };
}
