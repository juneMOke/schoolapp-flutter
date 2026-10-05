import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_note.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Lectures du programme. Une ligne dont la suppression attend son accusé
/// (`deleted_at`) n'est jamais rendue : pour l'écran, elle n'existe plus.
class ChapitreDao {
  final DatabaseExecutor _db;

  const ChapitreDao(this._db);

  /// Les chapitres d'un cours dans l'ordre de progression. `rowid` départage
  /// deux rangs égaux (un chapitre créé ici avant d'avoir reçu le sien).
  Future<List<Chapitre>> chapitresOfCours(String coursId) async {
    final rows = await _db.query(
      ProgrammeTables.chapitre,
      where: 'cours_id = ? AND deleted_at IS NULL',
      whereArgs: [coursId],
      orderBy: 'ordre ASC, rowid ASC',
    );
    return rows.map(ChapitreRowMapper.toEntity).toList(growable: false);
  }

  Future<Chapitre?> find(String id) async {
    final rows = await _db.query(
      ProgrammeTables.chapitre,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : ChapitreRowMapper.toEntity(rows.single);
  }

  /// Notes visibles par chapitre d'un cours ; un chapitre absent n'en a pas.
  Future<Map<String, int>> notesCountByChapitre(String coursId) async {
    final rows = await _db.rawQuery(
      'SELECT chapitre_id, COUNT(*) AS n FROM ${ProgrammeTables.note} '
      'WHERE cours_id = ? AND deleted_at IS NULL GROUP BY chapitre_id',
      [coursId],
    );
    return {
      for (final row in rows) row['chapitre_id'] as String: row['n'] as int,
    };
  }

  /// Les notes d'un chapitre, la plus récente en tête.
  Future<List<ChapitreNote>> notesOf(String chapitreId) async {
    final rows = await _db.query(
      ProgrammeTables.note,
      where: 'chapitre_id = ? AND deleted_at IS NULL',
      whereArgs: [chapitreId],
      orderBy: 'ecrite_le DESC, rowid DESC',
    );
    return rows.map(ChapitreNoteRowMapper.toEntity).toList(growable: false);
  }

  /// Les ressources d'un chapitre, dans l'ordre où elles ont été jointes.
  Future<List<ChapitreRessource>> ressourcesOf(String chapitreId) async {
    final rows = await _db.query(
      ProgrammeTables.ressource,
      where: 'chapitre_id = ? AND deleted_at IS NULL',
      whereArgs: [chapitreId],
      orderBy: 'rowid ASC',
    );
    return rows
        .map(ChapitreRessourceRowMapper.toEntity)
        .toList(growable: false);
  }

  Future<ChapitreRessource?> findRessource(String id) async {
    final rows = await _db.query(
      ProgrammeTables.ressource,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty
        ? null
        : ChapitreRessourceRowMapper.toEntity(rows.single);
  }
}
