import 'package:school_app_flutter/features/staff/data/local/staff_lww.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce que l'accusé d'une remontée fait à la fiche locale.
///
/// Toutes les décisions se prennent sur **l'horloge envoyée** : si la fiche a
/// été modifiée sur le poste pendant le vol, sa nouvelle horloge diffère, et
/// l'accusé ne doit ni écraser cette saisie ni la geler en erreur — elle
/// partira à son tour.
class StaffMemberSyncDao {
  final Database _db;

  const StaffMemberSyncDao(this._db);

  static const String table = StaffMemberLocalModel.table;

  /// Applique l'état retenu par le serveur (`APPLIED` ou `SUPERSEDED`).
  Future<void> applyAck(
    StaffMemberDeltaDto canonical, {
    required String sentClientUpdatedAt,
    required String schoolId,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final rows = await txn.query(
      table,
      columns: ['client_updated_at'],
      where: 'id = ?',
      whereArgs: [canonical.id],
    );
    if (rows.isEmpty) {
      await txn.insert(table, {
        'id': canonical.id,
        'school_id': schoolId,
        ...StaffMemberLocalModel.serverColumns(canonical),
        ...StaffMemberLocalModel.contentColumns(canonical),
        'sync_status': StaffSyncState.synced.dbValue,
        'updated_at': nowMs,
      });
      return;
    }
    final latest = sameInstant(
      rows.single['client_updated_at'] as String?,
      sentClientUpdatedAt,
    );
    await txn.update(
      table,
      {
        ...StaffMemberLocalModel.serverColumns(canonical),
        if (latest) ...StaffMemberLocalModel.contentColumns(canonical),
        if (latest) 'sync_status': StaffSyncState.synced.dbValue,
        if (latest) 'sync_error': null,
        if (latest) 'sync_error_code': null,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [canonical.id],
    );
  });

  /// Marque la fiche « refusée » — sauf si une saisie plus récente l'a
  /// remplacée pendant le vol (rend alors `false` : l'entrée repart avec elle
  /// plutôt que d'être gelée).
  Future<bool> markRejected(
    String staffMemberId, {
    required String sentClientUpdatedAt,
    required String? code,
    required String reason,
    required int nowMs,
  }) => _db.transaction((txn) async {
    final rows = await txn.query(
      table,
      columns: ['client_updated_at'],
      where: 'id = ?',
      whereArgs: [staffMemberId],
    );
    if (rows.isEmpty) return true;
    if (!sameInstant(
      rows.single['client_updated_at'] as String?,
      sentClientUpdatedAt,
    )) {
      return false;
    }
    await txn.update(
      table,
      {
        'sync_status': StaffSyncState.failed.dbValue,
        'sync_error': reason,
        'sync_error_code': code,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [staffMemberId],
    );
    return true;
  });

  /// La fiche a été purgée côté serveur (410) : elle s'efface du poste.
  Future<void> delete(String staffMemberId) =>
      _db.delete(table, where: 'id = ?', whereArgs: [staffMemberId]);

  /// Voir [StaffLww.sameInstant].
  static bool sameInstant(String? a, String? b) => StaffLww.sameInstant(a, b);
}
