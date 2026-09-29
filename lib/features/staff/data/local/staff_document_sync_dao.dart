import 'package:school_app_flutter/features/staff/data/local/staff_document_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_document_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce que l'envoi d'une pièce fait à sa ligne, et ce qu'on relit d'elle pour
/// l'ouvrir.
class StaffDocumentSyncDao {
  final Database _db;

  const StaffDocumentSyncDao(this._db);

  static const String table = StaffDocumentLocalModel.table;

  Future<StaffDocumentLocalModel?> find(String documentId) async {
    final rows = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [documentId],
      limit: 1,
    );
    return rows.isEmpty ? null : StaffDocumentLocalModel(rows.single);
  }

  /// Les pièces accusées de la base ouverte — celles dont les octets peuvent
  /// être redemandés au serveur.
  Future<List<String>> syncedIds() async {
    final rows = await _db.query(
      table,
      columns: ['id'],
      where: 'sync_status = ?',
      whereArgs: [StaffSyncState.synced.dbValue],
    );
    return [for (final row in rows) row['id']! as String];
  }

  /// Accusé : la pièce devient celle du serveur.
  Future<void> applyAck(
    StaffDocumentDeltaDto canonical, {
    required String schoolId,
    required int nowMs,
  }) => _db.insert(
    table,
    StaffDocumentLocalModel.columns(
      canonical,
      schoolId: schoolId,
      nowMs: nowMs,
    ),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  /// Refus déterministe : la pièce reste, marquée refusée, pour être revue.
  Future<void> markRejected(
    String documentId, {
    required String? code,
    required String reason,
    required int nowMs,
  }) => _db.update(
    table,
    {
      'sync_status': StaffSyncState.failed.dbValue,
      'sync_error': reason,
      'sync_error_code': code,
      'updated_at': nowMs,
    },
    where: 'id = ?',
    whereArgs: [documentId],
  );

  /// La pièce a été purgée côté serveur (410).
  Future<void> delete(String documentId) =>
      _db.delete(table, where: 'id = ?', whereArgs: [documentId]);
}
