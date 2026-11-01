import 'dart:convert';

import 'package:school_app_flutter/features/cotes/data/models/cote_classe_dto.dart';
import 'package:school_app_flutter/features/cotes/data/models/cote_saisie_row.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le cache d'une classe et ses cellules.
class CotesLocalDataSource {
  final Database _db;

  const CotesLocalDataSource(this._db);

  static const String cacheTable = 'cote_classe_cache';
  static const String table = 'cote_saisie';

  /// La structure en cache, `null` si la classe n'a jamais été ouverte ici ou
  /// si la ligne ne se relit plus.
  Future<CoteClasse?> readClasse(String classroomId) async {
    final rows = await _db.query(
      cacheTable,
      where: 'classroom_id = ?',
      whereArgs: [classroomId],
    );
    if (rows.isEmpty) return null;
    try {
      final raw = jsonDecode(rows.first['structure_json'] as String);
      return coteClasseFromStructure(raw as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<List<CoteCell>> readCells(String classroomId) async {
    final rows = await _db.query(
      table,
      where: 'classroom_id = ?',
      whereArgs: [classroomId],
    );
    return rows.map(coteCellFromRow).toList(growable: false);
  }

  /// Remplace ce que le serveur a dit d'une classe, en une transaction.
  ///
  /// [syncedAt] est l'heure du départ de la requête : la réponse décrit le
  /// serveur à cet instant. Un envoi accepté pendant son trajet est plus récent
  /// qu'elle, et elle ne l'efface pas — l'horloge de la cellule tranche. Tout ce
  /// que la tablette retient survit : brouillon en attente, cote refusée (le
  /// serveur n'en garde aucune trace), frappe à corriger, cellule dépassée pas
  /// encore signalée.
  ///
  /// Une ligne ne se supprime jamais : une cote vidée ne redescend pas, son
  /// horloge resterait perdue et la saisie suivante pourrait la perdre.
  Future<void> replaceClasse({
    required String classroomId,
    required CoteClasseDto dto,
    required int syncedAt,
  }) async {
    await _db.transaction((txn) async {
      await txn.insert(cacheTable, {
        'classroom_id': classroomId,
        'structure_json': jsonEncode(dto.structure),
        'synced_at': syncedAt,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.update(
        table,
        {'server_cote': null, 'calculee': null},
        where:
            'classroom_id = ? AND superseded_at IS NULL '
            'AND (server_updated_at IS NULL OR server_updated_at < ?)',
        whereArgs: [classroomId, syncedAt],
      );
      final batch = txn.batch();
      for (final cell in dto.cellules) {
        batch.rawInsert(
          'INSERT INTO $table (student_id, cours_id, colonne_id, classroom_id, '
          'examen, server_cote, calculee, server_updated_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?) '
          'ON CONFLICT (student_id, cours_id, colonne_id) DO UPDATE SET '
          'calculee = excluded.calculee, '
          'server_cote = CASE WHEN $_localIsNewer '
          'THEN $table.server_cote ELSE excluded.server_cote END, '
          'server_updated_at = CASE WHEN $_localIsNewer '
          'THEN $table.server_updated_at '
          'ELSE excluded.server_updated_at END',
          [
            cell.studentId,
            cell.coursId,
            cell.colonneId,
            classroomId,
            if (cell.examen) 1 else 0,
            cell.cote,
            cell.calculee,
            cell.updatedAtMs,
          ],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  static const String _localIsNewer =
      'COALESCE($table.server_updated_at, 0) > '
      'COALESCE(excluded.server_updated_at, 0)';
}
