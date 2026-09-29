import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_push_dto.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';

/// Passe d'un contrat saisi à ce qui part au serveur. Chaque champ étranger au
/// statut part à `null` : le serveur refuse un montant pour un conventionné, un
/// matricule SECOPE ou une prime pour un permanent (`INVALID_CONTRACT`).
///
/// Rend `null` si le contrat est incomplet : la validation aurait dû le
/// refuser, et le dépôt ne fabrique pas de valeur à sa place.
abstract final class StaffContractInputMapper {
  static StaffContractInputDto? of(
    StaffContractDraft draft, {
    required String id,
    required String recordedAt,
  }) {
    final kind = draft.kind;
    final from = draft.effectiveFrom;
    if (kind == null || from == null) return null;
    final amount = draft.needsAmount ? AmountInput.toCents(draft.amount) : null;
    if (draft.needsAmount && amount == null) return null;
    if (draft.isVacataire && draft.payMode == null) return null;
    final secope = draft.secopeNumber.trim();
    if (draft.isConventionne && secope.isEmpty) return null;
    final bonus = draft.isConventionne
        ? AmountInput.toCents(draft.bonus)
        : null;
    return StaffContractInputDto(
      id: id,
      kind: kind.wire,
      payMode: draft.isVacataire ? draft.payMode!.wire : null,
      effectiveFrom: from,
      endsOn: draft.endsOn,
      amountInCents: amount,
      currency: amount == null ? null : CurrencyCode.normalize(draft.currency),
      secopeNumber: draft.isConventionne ? secope : null,
      bonusInCents: bonus,
      bonusCurrency: bonus == null
          ? null
          : CurrencyCode.normalize(draft.bonusCurrency),
      recordedAt: recordedAt,
    );
  }
}
