import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_dto.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_member_dto.dart';

/// Accès sqflite aux tables read-only du module Classe (`ref_classrooms` +
/// `ref_classroom_members`). Upsert du delta de pull (CF2) et lectures offline
/// (CF3 : classes, roster ACTIVE, recherche locale insensible à la casse).
class ClassroomLocalDataSource {
  final Database _db;

  const ClassroomLocalDataSource(this._db);

  static const String classroomsTable = 'ref_classrooms';
  static const String membersTable = 'ref_classroom_members';

  /// Upsert transactionnel du delta reçu (CF2). `synced_at` posé sur chaque
  /// ligne touchée (fraîcheur ADR-002). `REPLACE` sur la PK = idempotent.
  Future<void> upsertDelta({
    required List<ClassroomDto> classrooms,
    required List<ClassroomMemberDto> members,
    required int syncedAt,
  }) async {
    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (final c in classrooms) {
        batch.insert(
          classroomsTable,
          c.toMap(syncedAt: syncedAt),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final m in members) {
        batch.insert(
          membersTable,
          m.toMap(syncedAt: syncedAt),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Classes d'une année (et niveau optionnel), triées par nom. Lecture directe
  /// des compteurs pré-agrégés — **sans charger le roster** (CF3).
  Future<List<ClassroomDto>> getClassrooms({
    required String academicYearId,
    String? schoolLevelId,
  }) async {
    final where = StringBuffer('academic_year_id = ?');
    final args = <Object?>[academicYearId];
    if (schoolLevelId != null) {
      where.write(' AND school_level_id = ?');
      args.add(schoolLevelId);
    }
    final rows = await _db.query(
      classroomsTable,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(ClassroomDto.fromMap).toList(growable: false);
  }

  /// Une classe par id (`null` si absente localement).
  Future<ClassroomDto?> getClassroomById(String classroomId) async {
    final rows = await _db.query(
      classroomsTable,
      where: 'id = ?',
      whereArgs: [classroomId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ClassroomDto.fromMap(rows.first);
  }

  /// Roster ACTIVE d'une classe (CF3) : `WHERE classroom_id=? AND status='ACTIVE'`,
  /// trié nom → post-nom → prénom, zéro jointure (snapshot dénormalisé).
  Future<List<ClassroomMemberDto>> getRoster(String classroomId) async {
    final rows = await _db.query(
      membersTable,
      where: 'classroom_id = ? AND status = ?',
      whereArgs: [classroomId, 'ACTIVE'],
      orderBy:
          'student_last_name COLLATE NOCASE ASC, '
          'student_middle_name COLLATE NOCASE ASC, '
          'student_first_name COLLATE NOCASE ASC',
    );
    return rows.map(ClassroomMemberDto.fromMap).toList(growable: false);
  }

  /// Recherche locale dans le roster ACTIVE (CF3) : filtre nom / post-nom /
  /// prénom, insensible à la casse — reproduit `members/search` sans réseau.
  Future<List<ClassroomMemberDto>> searchRoster({
    required String classroomId,
    required String query,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getRoster(classroomId);
    final like = '%${trimmed.toLowerCase()}%';
    final rows = await _db.query(
      membersTable,
      where:
          "classroom_id = ? AND status = 'ACTIVE' AND ("
          'LOWER(student_first_name) LIKE ? OR '
          'LOWER(student_last_name) LIKE ? OR '
          'LOWER(student_middle_name) LIKE ?)',
      whereArgs: [classroomId, like, like, like],
      orderBy:
          'student_last_name COLLATE NOCASE ASC, '
          'student_first_name COLLATE NOCASE ASC',
    );
    return rows.map(ClassroomMemberDto.fromMap).toList(growable: false);
  }

  /// Nombre d'élèves ACTIVE d'une classe (effectif pour le taux dérivé AF-3).
  Future<int> countActiveRoster(String classroomId) async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM $membersTable '
      'WHERE classroom_id = ? AND status = ?',
      [classroomId, 'ACTIVE'],
    );
    return (rows.first['c'] as int?) ?? 0;
  }
}
