import 'package:school_app_flutter/features/student_photo/data/local/student_photo_local_model.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_dto.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/student_photo.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Lectures de `student_photos`, descente du flux et marques de cache.
class StudentPhotoDao {
  final DatabaseExecutor _db;

  const StudentPhotoDao(this._db);

  static const String table = StudentPhotoLocalModel.table;

  Future<List<StudentPhotoLocalModel>> forSchool(String schoolId) async {
    if (schoolId.isEmpty) return const [];
    final rows = await _db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    return rows.map(StudentPhotoLocalModel.new).toList(growable: false);
  }

  Future<StudentPhotoLocalModel?> find(String studentId) async {
    final rows = await _db.query(
      table,
      where: 'student_id = ?',
      whereArgs: [studentId],
      limit: 1,
    );
    return rows.isEmpty ? null : StudentPhotoLocalModel(rows.single);
  }

  /// Applique une page descendue : seules les colonnes du serveur bougent. Un
  /// geste en attente reste en place — il partira, et c'est l'arbitrage du
  /// serveur qui dira lequel des deux est le plus récent.
  Future<int> applyPulled(
    List<StudentPhotoStateDto> states, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (states.isEmpty || schoolId.isEmpty) return 0;
    final batch = _db.batch();
    for (final state in states) {
      // Créer la ligne si elle manque, puis n'écrire que les colonnes du
      // serveur : un `REPLACE` effacerait le geste en attente et les marques
      // de cache.
      batch.insert(table, {
        'student_id': state.studentId,
        'school_id': schoolId,
        'updated_at': nowMs,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      batch.update(
        table,
        {
          'school_id': schoolId,
          'sha256': state.sha256,
          'thumbnail_sha256': state.thumbnailSha256,
          'taken_at': state.takenAt,
          'server_updated_at': state.serverUpdatedAt,
          'updated_at': nowMs,
        },
        where: 'student_id = ?',
        whereArgs: [state.studentId],
      );
    }
    await batch.commit(noResult: true);
    return states.length;
  }

  /// Les copies locales devenues sans objet : la photo du serveur a été
  /// retirée alors qu'une copie d'elle reste sur le poste.
  Future<List<StudentPhotoLocalModel>> staleCaches(String schoolId) async {
    final rows = await _db.query(
      table,
      where:
          'school_id = ? AND sha256 IS NULL AND '
          '(cached_96_sha IS NOT NULL OR cached_512_sha IS NOT NULL)',
      whereArgs: [schoolId],
    );
    return rows.map(StudentPhotoLocalModel.new).toList(growable: false);
  }

  /// Les élèves dont la vignette du serveur n'est pas encore sur le poste.
  Future<List<StudentPhotoLocalModel>> missingThumbnails(
    String schoolId,
  ) async {
    final rows = await _db.query(
      table,
      where:
          'school_id = ? AND sha256 IS NOT NULL AND '
          '(cached_96_sha IS NULL OR cached_96_sha != sha256)',
      whereArgs: [schoolId],
    );
    return rows.map(StudentPhotoLocalModel.new).toList(growable: false);
  }

  /// La copie de [size] porte désormais l'empreinte [sha256] (`null` = plus
  /// de copie).
  Future<void> markCached(
    String studentId,
    StudentPhotoSize size, {
    required String? sha256,
  }) => _db.update(
    table,
    {StudentPhotoLocalModel.cachedColumnOf(size): sha256},
    where: 'student_id = ?',
    whereArgs: [studentId],
  );

  /// Toutes les copies ont disparu (clé du magasin renouvelée).
  Future<void> forgetAllCaches() =>
      _db.update(table, {'cached_96_sha': null, 'cached_512_sha': null});
}
