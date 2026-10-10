import 'package:school_app_flutter/core/offline/outbox_gesture.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_outbox.dart';
import 'package:school_app_flutter/features/class_journal/data/local/journal_rows.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce qui retire le journal d'un cours de la tablette.
class JournalPurge {
  final Database _db;

  const JournalPurge(this._db);

  /// Un cours qui n'est plus au professeur (403 `COURS_NOT_OWNED`) : ses
  /// entrées partent, et ses saisies en attente — elles partiraient toutes en
  /// refus.
  Future<void> purgeCours(String coursId) => _db.transaction((txn) async {
    final ids = [
      for (final row in await txn.query(
        JournalTables.entry,
        columns: ['id'],
        where: 'cours_id = ?',
        whereArgs: [coursId],
      ))
        JournalOutbox.entry(row['id'] as String),
    ];
    await OutboxGestures.discard(txn, ids);
    await txn.delete(
      JournalTables.entry,
      where: 'cours_id = ?',
      whereArgs: [coursId],
    );
  });
}
