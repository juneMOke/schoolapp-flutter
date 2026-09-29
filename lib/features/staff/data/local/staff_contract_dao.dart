import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Accès à `staff_contracts` — les périodes **avec** leurs montants, présentes
/// seulement sur une tablette dont le compte détient `hr.pay.read`.
class StaffContractDao {
  final DatabaseExecutor _db;

  const StaffContractDao(this._db);

  static const String table = 'staff_contracts';

  /// Applique une page descendue. Une période est un fait figé : la version du
  /// serveur (correction comprise) remplace la ligne locale de même `id`.
  Future<int> applyPulled(
    List<StaffContractDeltaDto> deltas, {
    required String schoolId,
    required int nowMs,
  }) async {
    if (deltas.isEmpty || schoolId.isEmpty) return 0;
    final batch = _db.batch();
    for (final d in deltas) {
      batch.insert(table, {
        'id': d.id,
        'school_id': schoolId,
        'staff_member_id': d.staffMemberId,
        'kind': d.kind,
        'pay_mode': d.payMode,
        'effective_from': d.effectiveFrom,
        'ends_on': d.endsOn,
        'amount_in_cents': d.amountInCents,
        'currency': d.currency,
        'secope_number': d.secopeNumber,
        'bonus_in_cents': d.bonusInCents,
        'bonus_currency': d.bonusCurrency,
        'recorded_at': d.recordedAt,
        'corrected_at': d.correctedAt,
        'corrected_by_name': d.correctedByName,
        'replaced_by': d.replacedBy,
        'correction_reason': d.correctionReason,
        'version': d.version,
        'server_updated_at': d.serverUpdatedAt,
        'sync_status': StaffSyncState.synced.dbValue,
        'sync_error': null,
        'sync_error_code': null,
        'updated_at': nowMs,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    return deltas.length;
  }
}
