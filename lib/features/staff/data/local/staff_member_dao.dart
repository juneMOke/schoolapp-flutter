import 'package:school_app_flutter/features/staff/data/local/staff_member_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Accès à `staff_members`.
class StaffMemberDao {
  final DatabaseExecutor _db;

  const StaffMemberDao(this._db);

  static const String table = StaffMemberLocalModel.table;

  /// Les fiches de l'école, dans l'ordre de l'état civil (nom, post-nom,
  /// prénom), sans égard à la casse.
  Future<List<StaffMemberLocalModel>> listForSchool(String schoolId) async {
    if (schoolId.isEmpty) return const [];
    final rows = await _db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
      orderBy:
          'last_name COLLATE NOCASE, middle_name COLLATE NOCASE, '
          'first_name COLLATE NOCASE',
    );
    return rows.map(StaffMemberLocalModel.new).toList(growable: false);
  }

  /// Une fiche, ou `null`.
  Future<StaffMemberLocalModel?> find(String staffMemberId) async {
    final rows = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [staffMemberId],
      limit: 1,
    );
    return rows.isEmpty ? null : StaffMemberLocalModel(rows.single);
  }

  /// Applique une page descendue. Rend le nombre de fiches écrites.
  ///
  /// Une fiche portant une saisie locale **pas encore remontée** ne perd que
  /// ce que le serveur seul écrit (matricule, frise, version) : son contenu
  /// attend l'accusé de sa propre remontée, qui tranchera au dernier écrit.
  Future<int> applyPulled(
    List<StaffMemberDeltaDto> deltas, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (deltas.isEmpty || schoolId.isEmpty) return 0;
    Future<void> apply(DatabaseExecutor txn) async {
      for (final delta in deltas) {
        final existing = await txn.query(
          table,
          columns: ['sync_status'],
          where: 'id = ?',
          whereArgs: [delta.id],
        );
        if (existing.isEmpty) {
          await txn.insert(table, {
            'id': delta.id,
            'school_id': schoolId,
            ...StaffMemberLocalModel.serverColumns(delta),
            ...StaffMemberLocalModel.contentColumns(delta),
            'sync_status': RecordSyncState.synced.dbValue,
            'updated_at': nowMs,
          });
          continue;
        }
        final synced =
            existing.single['sync_status'] == RecordSyncState.synced.dbValue;
        await txn.update(
          table,
          {
            ...StaffMemberLocalModel.serverColumns(delta),
            if (synced) ...StaffMemberLocalModel.contentColumns(delta),
            'updated_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [delta.id],
        );
      }
    }

    final db = _db;
    if (db is Database) {
      await db.transaction(apply);
    } else {
      await apply(db);
    }
    return deltas.length;
  }
}
