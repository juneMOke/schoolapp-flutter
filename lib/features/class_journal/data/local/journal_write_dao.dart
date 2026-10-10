import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/offline/outbox_gesture.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_outbox.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_rows.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_push.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Écriture locale d'une séance — **toujours avec son entrée d'outbox, dans la
/// même transaction**.
class JournalWriteDao {
  final Database _db;

  const JournalWriteDao(this._db);

  /// Enregistre la saisie de [entry] (horodatée par `clientUpdatedAt`) et la
  /// met en file ; elle remplace une saisie de la même séance encore en
  /// attente. Vider une séance passe par ici, champs vides et sans chapitre.
  Future<void> save(
    JournalEntry entry, {
    required String? schoolId,
    required int nowMs,
    String? authorId,
  }) => _db.transaction((txn) async {
    final columns = {
      ...JournalRowMapper.fieldColumns(
        chapitreId: entry.chapitreId,
        fields: entry.fields,
      ),
      'client_updated_at': entry.clientUpdatedAt?.toUtc().toIso8601String(),
      'sync_status': SyncState.pendingSync.dbValue,
      'sync_error_code': null,
      'updated_at': nowMs,
    };
    final updated = await txn.update(
      JournalTables.entry,
      columns,
      where: 'id = ?',
      whereArgs: [entry.id],
    );
    if (updated == 0) {
      await txn.insert(JournalTables.entry, {
        'id': entry.id,
        'cours_id': entry.coursId,
        'date_seance': DateOnlyJsonHelper.toJson(entry.date),
        'time_slot_id': entry.timeSlotId,
        ...columns,
      });
    }
    await enqueueOutboxGesture(
      txn,
      entryId: JournalOutbox.entry(entry.id),
      type: JournalOutbox.type,
      aggregateId: entry.id,
      payload: JournalEntryPayload.of(entry).toJson(),
      schoolId: schoolId,
      nowMs: nowMs,
      authorId: authorId,
    );
  });
}
