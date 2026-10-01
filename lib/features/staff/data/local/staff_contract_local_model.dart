import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_dto.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_push_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Une ligne de `staff_contracts`.
///
/// `correction_pending_id` est **local** : l'identifiant d'une correction
/// écrite sur le poste et pas encore accusée. Aucune colonne serveur ne le
/// porte, donc ni un pull ni un accusé de pose ne l'effacent — il ne tombe
/// qu'avec l'accusé (ou le refus) de sa propre correction.
class StaffContractLocalModel {
  final Map<String, Object?> row;

  const StaffContractLocalModel(this.row);

  static const String table = 'staff_contracts';

  /// Ce que le serveur dit d'une période : tout, sauf le marqueur local.
  static Map<String, Object?> serverColumns(
    StaffContractDeltaDto d, {
    required int nowMs,
  }) => {
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
    'sync_status': RecordSyncState.synced.dbValue,
    'sync_error': null,
    'sync_error_code': null,
    'updated_at': nowMs,
  };

  /// Une période posée sur le poste, en attente d'accusé.
  static Map<String, Object?> pendingColumns(
    StaffContractInputDto input, {
    required String staffMemberId,
    required String schoolId,
    required int nowMs,
  }) => {
    'id': input.id,
    'school_id': schoolId,
    'staff_member_id': staffMemberId,
    'kind': input.kind,
    'pay_mode': input.payMode,
    'effective_from': input.effectiveFrom,
    'ends_on': input.endsOn,
    'amount_in_cents': input.amountInCents,
    'currency': input.currency,
    'secope_number': input.secopeNumber,
    'bonus_in_cents': input.bonusInCents,
    'bonus_currency': input.bonusCurrency,
    'recorded_at': input.recordedAt,
    'sync_status': RecordSyncState.pending.dbValue,
    'updated_at': nowMs,
  };

  StaffContract toEntity() {
    String? text(String key) => row[key] as String?;
    Money? money(String amount, String currency) {
      final cents = (row[amount] as num?)?.toInt();
      return cents == null ? null : Money(cents, text(currency) ?? '');
    }

    return StaffContract(
      id: text('id') ?? '',
      staffMemberId: text('staff_member_id') ?? '',
      kind: StaffContractKind.fromWire(text('kind')),
      payMode: StaffPayMode.fromWire(text('pay_mode')),
      effectiveFrom: text('effective_from') ?? '',
      endsOn: text('ends_on'),
      amount: money('amount_in_cents', 'currency'),
      secopeNumber: text('secope_number'),
      bonus: money('bonus_in_cents', 'bonus_currency'),
      recordedAt: text('recorded_at') ?? '',
      correctedAt: text('corrected_at'),
      correctedByName: text('corrected_by_name'),
      correctionReason: text('correction_reason'),
      correctionPending: text('correction_pending_id') != null,
      syncState: RecordSyncState.fromDb(text('sync_status')),
      syncError: text('sync_error'),
    );
  }
}
