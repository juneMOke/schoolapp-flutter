import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/student_photo/data/local/student_photo_local_model.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_dto.dart';
import 'package:school_app_flutter/features/student_photo/data/sync/student_photo_push_request.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce que l'envoi d'un geste fait à sa ligne, et ce qu'il relit de l'élève.
///
/// Chaque écriture ne touche au geste en attente que s'il est **encore** celui
/// qui vient d'être envoyé : un geste plus récent, posé pendant l'envoi,
/// partira à son tour et ne doit pas être effacé par l'accusé de l'ancien.
class StudentPhotoSyncDao {
  final Database _db;

  const StudentPhotoSyncDao(this._db);

  static const String table = StudentPhotoLocalModel.table;

  Future<StudentPhotoLocalModel?> find(String studentId) async {
    final rows = await _db.query(
      table,
      where: 'student_id = ?',
      whereArgs: [studentId],
      limit: 1,
    );
    return rows.isEmpty ? null : StudentPhotoLocalModel(rows.single);
  }

  /// L'état de synchronisation de la fiche de l'élève sur ce poste, `null` si
  /// le poste ne la porte pas (élève d'une autre année, ou purgé).
  Future<SyncState?> studentSyncState(String studentId) async {
    final rows = await _db.query(
      'students',
      columns: ['sync_status'],
      where: 'id = ?',
      whereArgs: [studentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SyncState.fromDbValue(rows.single['sync_status'] as String?);
  }

  /// Accusé : la ligne prend l'état du serveur ; le geste envoyé est soldé
  /// s'il est encore en place. Rend `true` dans ce cas.
  Future<bool> applyAck(
    StudentPhotoPushRequest request,
    StudentPhotoStateDto state, {
    required int nowMs,
  }) => _db.transaction((txn) async {
    final settled = await _holds(txn, request);
    await txn.update(
      table,
      {
        'sha256': state.sha256,
        'taken_at': state.takenAt,
        'server_updated_at': state.serverUpdatedAt,
        if (settled) ...{
          'pending_op': null,
          'pending_sha256': null,
          'pending_at': null,
          'sync_status': RecordSyncState.synced.dbValue,
          'sync_error': null,
          'sync_error_code': null,
        },
        'updated_at': nowMs,
      },
      where: 'student_id = ?',
      whereArgs: [request.studentId],
    );
    return settled;
  });

  /// Refus déterministe : le geste est abandonné, sa raison gardée pour être
  /// montrée. Rend `false` si un geste plus récent l'a déjà remplacé.
  Future<bool> markRejected(
    StudentPhotoPushRequest request, {
    required String code,
    required String reason,
    required int nowMs,
  }) => _db.transaction((txn) async {
    if (!await _holds(txn, request)) return false;
    await txn.update(
      table,
      {
        'pending_op': null,
        'pending_sha256': null,
        'pending_at': null,
        'sync_status': RecordSyncState.failed.dbValue,
        'sync_error': reason,
        'sync_error_code': code,
        'updated_at': nowMs,
      },
      where: 'student_id = ?',
      whereArgs: [request.studentId],
    );
    return true;
  });

  static Future<bool> _holds(
    DatabaseExecutor db,
    StudentPhotoPushRequest request,
  ) async {
    final rows = await db.query(
      table,
      where: 'student_id = ?',
      whereArgs: [request.studentId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return StudentPhotoLocalModel(
      rows.single,
    ).holdsGesture(request.op, request.at);
  }
}
