import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/attendance_closure_models.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_closure.dart';

/// Les clôtures de mois de l'appel, par classe (`attendance_month_closures`).
///
/// Une clôture saisie fige le mois dès la saisie ; une clôture refusée par le
/// serveur ne fige rien (elle reste lisible, avec sa raison).
class AttendanceClosureLocalDataSource {
  final Database _db;

  const AttendanceClosureLocalDataSource(this._db);

  static const String table = 'attendance_month_closures';
  static const String _keyWhere =
      'classroom_id = ? AND academic_year_id = ? AND month = ?';

  /// La clôture du mois `YYYY-MM` de la classe, refusée comprise ; `null`
  /// sans clôture.
  Future<ClassPresenceClosure?> closureOf({
    required String classroomId,
    required String academicYearId,
    required String month,
  }) async {
    final rows = await _db.query(
      table,
      where: _keyWhere,
      whereArgs: [classroomId, academicYearId, month],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return ClassPresenceClosure(
      closedAt: row['closed_at'] as String?,
      closedBy: row['closed_by'] as String?,
      sync: SyncState.fromDbValue(row['sync_status'] as String?),
      refusal: row['sync_error'] as String?,
    );
  }

  /// Le mois est-il clos — ou en passe de l'être sur cette tablette ?
  Future<bool> isClosed({
    required String classroomId,
    required String academicYearId,
    required String month,
  }) async =>
      (await closureOf(
        classroomId: classroomId,
        academicYearId: academicYearId,
        month: month,
      ))?.closes ??
      false;

  /// Écrit la clôture saisie et son geste en file, en une transaction. Une
  /// clôture refusée du même mois est remplacée : c'est un nouveau geste.
  Future<void> record({
    required String gestureId,
    required String classroomId,
    required String academicYearId,
    required String month,
    required String closedAt,
    required OutboxEntry entry,
  }) => _db.transaction((txn) async {
    await txn.delete(
      table,
      where: _keyWhere,
      whereArgs: [classroomId, academicYearId, month],
    );
    await txn.insert(table, {
      'gesture_id': gestureId,
      'classroom_id': classroomId,
      'academic_year_id': academicYearId,
      'month': month,
      'closed_at': closedAt,
      'sync_status': SyncState.pendingSync.dbValue,
    });
    await OutboxDao(txn).enqueue(entry);
  });

  /// L'accusé du serveur : la clôture qu'il retient (la nôtre, ou celle
  /// d'une autre tablette pour le même mois).
  Future<void> applyAck(String gestureId, AttendanceClosureDto closure) =>
      _db.update(
        table,
        {
          'closed_at': closure.closedAt,
          'closed_by': closure.closedBy,
          'server_updated_at': closure.serverUpdatedAt,
          'sync_status': SyncState.synced.dbValue,
          'sync_error': null,
        },
        where: 'gesture_id = ?',
        whereArgs: [gestureId],
      );

  /// Un refus définitif : la clôture ne fige plus le mois, sa raison reste.
  Future<void> markRefused(String gestureId, String reason) => _db.update(
    table,
    {'sync_status': SyncState.syncError.dbValue, 'sync_error': reason},
    where: 'gesture_id = ?',
    whereArgs: [gestureId],
  );

  /// Les clôtures reçues du serveur : elles font autorité, y compris sur une
  /// clôture locale encore en file pour le même mois (le serveur répondra à
  /// celle-ci par la clôture existante).
  Future<int> applyPulled(List<AttendanceClosureDto> closures) async {
    var applied = 0;
    await applyInBatches<AttendanceClosureDto>(
      _db,
      closures,
      apply: (txn, chunk) async {
        for (final closure in chunk) {
          final keyArgs = [
            closure.classroomId,
            closure.academicYearId,
            closure.month,
          ];
          final existing = await txn.query(
            table,
            columns: ['gesture_id'],
            where: _keyWhere,
            whereArgs: keyArgs,
            limit: 1,
          );
          final values = {
            'classroom_id': closure.classroomId,
            'academic_year_id': closure.academicYearId,
            'month': closure.month,
            'closed_at': closure.closedAt,
            'closed_by': closure.closedBy,
            'server_updated_at': closure.serverUpdatedAt,
            'sync_status': SyncState.synced.dbValue,
            'sync_error': null,
          };
          if (existing.isEmpty) {
            await txn.insert(table, {
              'gesture_id':
                  closure.gestureId ?? closure.id ?? keyArgs.join('|'),
              ...values,
            });
          } else {
            await txn.update(
              table,
              values,
              where: _keyWhere,
              whereArgs: keyArgs,
            );
          }
          applied++;
        }
      },
    );
    return applied;
  }
}
