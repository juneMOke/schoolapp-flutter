import 'package:school_app_flutter/features/class_journal/data/local/journal_rows.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Lectures locales du journal.
class JournalDao {
  final Database _db;

  const JournalDao(this._db);

  /// Toutes les entrées des cours [coursIds], par jour.
  Future<List<JournalEntry>> entriesOfCours(Set<String> coursIds) async {
    if (coursIds.isEmpty) return const [];
    final marks = List.filled(coursIds.length, '?').join(', ');
    final rows = await _db.query(
      JournalTables.entry,
      where: 'cours_id IN ($marks)',
      whereArgs: coursIds.toList(growable: false),
      orderBy: 'date_seance, id',
    );
    return rows.map(JournalRowMapper.toEntity).toList(growable: false);
  }
}
