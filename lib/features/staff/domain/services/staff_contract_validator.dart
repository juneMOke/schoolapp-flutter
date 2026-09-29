import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';

/// Les champs d'un contrat.
enum StaffContractField {
  kind,
  payMode,
  effectiveFrom,
  endsOn,
  amount,
  secope,
  bonus,
  reason,
}

/// Pourquoi un champ de contrat est refusé — les règles du serveur, jugées
/// avant la mise en file (`AMOUNT_REQUIRED`, `PAY_MODE_REQUIRED`,
/// `SECOPE_NUMBER_REQUIRED`, `INVALID_CONTRACT`).
enum StaffContractError { required, amountInvalid, endBeforeStart }

/// Valide un contrat — fonction pure.
abstract final class StaffContractValidator {
  /// En [correcting], le motif est exigé : le serveur garde « ce qui était
  /// faux » avec la période corrigée.
  static Map<StaffContractField, StaffContractError> validate(
    StaffContractDraft draft, {
    bool correcting = false,
  }) {
    final errors = <StaffContractField, StaffContractError>{
      ...reasonErrors(draft, correcting: correcting),
    };
    if (draft.kind == null) {
      errors[StaffContractField.kind] = StaffContractError.required;
    }
    if (draft.isVacataire && draft.payMode == null) {
      errors[StaffContractField.payMode] = StaffContractError.required;
    }
    final from = draft.effectiveFrom;
    if (from == null) {
      errors[StaffContractField.effectiveFrom] = StaffContractError.required;
    }
    final ends = draft.endsOn;
    if (from != null && ends != null && ends.compareTo(from) < 0) {
      errors[StaffContractField.endsOn] = StaffContractError.endBeforeStart;
    }
    if (draft.needsAmount) {
      if (draft.amount.trim().isEmpty) {
        errors[StaffContractField.amount] = StaffContractError.required;
      } else if (AmountInput.toCents(draft.amount) == null) {
        errors[StaffContractField.amount] = StaffContractError.amountInvalid;
      }
    }
    if (draft.isConventionne) {
      if (draft.secopeNumber.trim().isEmpty) {
        errors[StaffContractField.secope] = StaffContractError.required;
      }
      if (draft.bonus.trim().isNotEmpty &&
          AmountInput.toCents(draft.bonus) == null) {
        errors[StaffContractField.bonus] = StaffContractError.amountInvalid;
      }
    }
    return errors;
  }

  /// Le seul contrôle d'« annuler seulement » : sans remplaçant, il ne reste
  /// que le motif à juger.
  static Map<StaffContractField, StaffContractError> reasonErrors(
    StaffContractDraft draft, {
    required bool correcting,
  }) => correcting && draft.reason.trim().isEmpty
      ? const {StaffContractField.reason: StaffContractError.required}
      : const {};
}
