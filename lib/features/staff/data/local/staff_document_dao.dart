import 'package:school_app_flutter/features/staff/data/local/staff_document_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Accès à `staff_documents` — les métadonnées des pièces.
class StaffDocumentDao {
  final DatabaseExecutor _db;

  const StaffDocumentDao(this._db);

  static const String table = StaffDocumentLocalModel.table;

  /// Les pièces de l'école, la plus récente d'abord pour chaque code.
  Future<List<StaffDocumentLocalModel>> listForSchool(String schoolId) async {
    if (schoolId.isEmpty) return const [];
    final rows = await _db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      orderBy: 'staff_member_id, code, captured_at DESC',
    );
    return rows.map(StaffDocumentLocalModel.new).toList(growable: false);
  }

  /// Applique une page descendue. Une pièce est un fait figé : la version du
  /// serveur remplace la ligne locale de même `id`, accusé compris.
  Future<int> applyPulled(
    List<StaffDocumentDeltaDto> deltas, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (deltas.isEmpty || schoolId.isEmpty) return 0;
    final batch = _db.batch();
    for (final delta in deltas) {
      batch.insert(
        table,
        StaffDocumentLocalModel.columns(
          delta,
          schoolId: schoolId,
          nowMs: nowMs,
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    return deltas.length;
  }
}
