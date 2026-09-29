import 'package:school_app_flutter/features/staff/data/local/staff_contract_local_model.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Accès à `staff_contracts` — les périodes **avec** leurs montants : celles
/// descendues sous `hr.pay.read`, et celles posées sur ce poste en attente
/// d'accusé.
class StaffContractDao {
  final DatabaseExecutor _db;

  const StaffContractDao(this._db);

  static const String table = StaffContractLocalModel.table;

  /// Les périodes d'un agent, par date d'effet — corrigées comprises.
  Future<List<StaffContractLocalModel>> forMember(String staffMemberId) async {
    final rows = await _db.query(
      table,
      where: 'staff_member_id = ?',
      whereArgs: [staffMemberId],
      orderBy: 'effective_from ASC, recorded_at ASC',
    );
    return rows.map(StaffContractLocalModel.new).toList(growable: false);
  }

  /// Toutes les périodes de l'école, corrigées comprises — de quoi compléter
  /// la frise de chaque fiche à la lecture.
  Future<List<StaffContractLocalModel>> forSchool(String schoolId) async {
    if (schoolId.isEmpty) return const [];
    final rows = await _db.query(
      table,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    return rows.map(StaffContractLocalModel.new).toList(growable: false);
  }

  /// Applique une page descendue. Une période est un fait figé : la version du
  /// serveur (correction comprise) l'emporte — sans effacer le marqueur local
  /// d'une correction encore en vol.
  Future<int> applyPulled(
    List<StaffContractDeltaDto> deltas, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (deltas.isEmpty || schoolId.isEmpty) return 0;
    Future<void> apply(DatabaseExecutor txn) async {
      for (final delta in deltas) {
        await upsert(txn, delta, schoolId: schoolId, nowMs: nowMs);
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

  /// Met à jour la période, ou l'insère si le poste ne la connaît pas.
  static Future<void> upsert(
    DatabaseExecutor txn,
    StaffContractDeltaDto delta, {
    required String schoolId,
    required int nowMs,
  }) async {
    final columns = StaffContractLocalModel.serverColumns(delta, nowMs: nowMs);
    final updated = await txn.update(
      table,
      columns,
      where: 'id = ?',
      whereArgs: [delta.id],
    );
    if (updated == 0) {
      await txn.insert(table, {
        'id': delta.id,
        'school_id': schoolId,
        ...columns,
      });
    }
  }
}
