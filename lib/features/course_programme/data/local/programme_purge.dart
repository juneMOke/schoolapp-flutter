import 'package:school_app_flutter/core/offline/outbox_gesture.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce qui retire des chapitres de la tablette **avec tout ce qui pend à
/// eux** : notes, ressources, gestes devenus sans objet, place dans un ordre
/// en attente, fichiers.
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
    final files = await _db.transaction((txn) async {
      final ids = [
        for (final row in await txn.query(
          ProgrammeTables.chapitre,
          columns: ['id'],
          where: 'cours_id = ?',
          whereArgs: [coursId],
        ))
          row['id'] as String,
      ];
      await OutboxGestures.discard(txn, [ProgrammeOutbox.ordreEntry(coursId)]);
      return removeChapitres(txn, ids);
    });
    await _blobs.deleteAll(files);
  }

  /// Retire [chapitreIds] et leurs enfants dans la transaction de l'appelant,
  /// retire leurs gestes de la file et leur place dans l'ordre en attente.
  /// Rend les ressources-documents retirées : leurs fichiers partent **après**
  /// la transaction ([ProgrammeBlobs.deleteAll]).
  static Future<List<String>> removeChapitres(
    DatabaseExecutor txn,
    List<String> chapitreIds,
  ) async {
    final files = <String>[];
    for (final chapitreId in chapitreIds) {
      final row = (await txn.query(
        ProgrammeTables.chapitre,
        columns: ['cours_id'],
        where: 'id = ?',
        whereArgs: [chapitreId],
      )).firstOrNull;
      if (row != null) {
        await ProgrammeOutbox.detachFromOrdre(
          txn,
          coursId: row['cours_id'] as String,
          chapitreId: chapitreId,
        );
      }
      await OutboxGestures.discard(txn, [
        ProgrammeOutbox.chapitreEntry(chapitreId),
      ]);
      await ProgrammeOutbox.discardChildren(txn, chapitreId);
      files.addAll([
        for (final r in await txn.query(
          ProgrammeTables.ressource,
          columns: ['id'],
          where: 'chapitre_id = ? AND type = ?',
          whereArgs: [chapitreId, RessourceType.document.wireValue],
        ))
          r['id'] as String,
      ]);
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
    return files;
  }
}
