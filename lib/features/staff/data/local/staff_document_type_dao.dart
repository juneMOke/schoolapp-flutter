import 'package:school_app_flutter/core/staff/local/staff_document_type_local_model.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Accès à `ref_staff_document_types` — remplacé d'un bloc par école à chaque
/// référentiel qui porte la section.
class StaffDocumentTypeDao {
  final Database _db;

  const StaffDocumentTypeDao(this._db);

  static const String table = 'ref_staff_document_types';

  Future<void> replaceForSchool(
    List<StaffDocumentTypeLocalModel> types, {
    required String schoolId,
  }) async {
    if (schoolId.isEmpty) return;
    await _db.transaction((txn) async {
      await txn.delete(table, where: 'school_id = ?', whereArgs: [schoolId]);
      final batch = txn.batch();
      for (final type in types) {
        if (!type.isUsable) continue;
        batch.insert(
          table,
          type.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Les pièces du dossier, dans l'ordre servi.
  Future<List<StaffDocumentTypeLocalModel>> forSchool(String schoolId) async {
    if (schoolId.isEmpty) return const [];
    final rows = await _db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      orderBy: 'sort_order ASC, code ASC',
    );
    return rows
        .map(StaffDocumentTypeLocalModel.fromMap)
        .toList(growable: false);
  }
}
