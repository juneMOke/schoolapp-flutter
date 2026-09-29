import 'package:school_app_flutter/features/staff/domain/services/staff_contract_validator.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les textes des refus d'un champ de contrat.
abstract final class StaffContractMessages {
  static Map<StaffContractField, String> of(
    AppLocalizations l10n,
    Map<StaffContractField, StaffContractError> errors,
  ) => {
    for (final entry in errors.entries)
      entry.key: switch (entry.value) {
        StaffContractError.required => switch (entry.key) {
          StaffContractField.amount => l10n.staffContractAmountRequired,
          StaffContractField.secope => l10n.staffContractSecopeRequired,
          StaffContractField.reason => l10n.staffContractReasonRequired,
          _ => l10n.staffFieldRequired,
        },
        StaffContractError.amountInvalid => l10n.staffContractAmountInvalid,
        StaffContractError.endBeforeStart => l10n.staffContractEndBeforeStart,
      },
  };
}
