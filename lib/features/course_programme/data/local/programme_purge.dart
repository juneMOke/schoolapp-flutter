import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce qui retire des chapitres de la tablette **avec tout ce qui pend à
/// eux** : notes, ressources, entrées d'outbox devenues sans objet, fichiers.
///
/// sqflite n'applique aucune cascade : chaque retrait nomme ses enfants.
class ProgrammePurge {
  final Database _db;
  final ProgrammeBlobs _blobs;

  const ProgrammePurge({required Database db, required ProgrammeBlobs blobs})
    : _db = db,
      _blobs = blobs;

  /// Un cours qui n'est plus au professeur (403 `COURS_NOT_OWNED`) : ses
  /// gestes en attente partiraient tous en refus, ils sont abandonnés.
  Future<void> purgeCours(String coursId) async {
    await _db.transaction((txn) async {
      final ids = await _ids(
        txn,
        ProgrammeTables.chapitre,
        'cours_id',
        coursId,
      );
      await removeChapitres(txn, ids);
      await ProgrammeOutbox.neutralize(txn, [
        ProgrammeOutbox.ordreEntry(coursId),
      ]);
    });
    await _blobs.reclaimOrphans();
  }

  /// Retire [chapitreIds] et leurs enfants dans la transaction de l'appelant,
  /// et neutralise leurs entrées d'outbox. Les fichiers partent ensuite, au
  /// ménage des orphelins ([ProgrammeBlobs.reclaimOrphans]).
  static Future<void> removeChapitres(
    DatabaseExecutor txn,
    List<String> chapitreIds,
  ) async {
    for (final chapitreId in chapitreIds) {
      await ProgrammeOutbox.neutralize(txn, [
        ProgrammeOutbox.chapitreEntry(chapitreId),
      ]);
      await ProgrammeOutbox.neutralizeChildren(txn, chapitreId);
      for (final table in [ProgrammeTables.note, ProgrammeTables.ressource]) {
        await txn.delete(
          table,
          where: 'chapitre_id = ?',
          whereArgs: [chapitreId],
        );
      }
      await txn.delete(
        ProgrammeTables.chapitre,
        where: 'id = ?',
        whereArgs: [chapitreId],
      );
    }
  }

  static Future<List<String>> _ids(
    DatabaseExecutor txn,
    String table,
    String column,
    String value,
  ) async => [
    for (final row in await txn.query(
      table,
      columns: ['id'],
      where: '$column = ?',
      whereArgs: [value],
    ))
      row['id'] as String,
  ];
}
