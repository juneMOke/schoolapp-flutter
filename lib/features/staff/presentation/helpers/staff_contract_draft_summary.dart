import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/money/amount_input.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_draft.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un contrat en saisie dit en une ligne, tel que le dépôt le posera :
/// « Vacataire · Taux horaire : 15,00 $ · Depuis le 01/09/2026 ».
///
/// Ce qui ne se lit pas encore (montant vide ou faux, date absente) est tu,
/// jamais deviné.
abstract final class StaffContractDraftSummary {
  static String line(AppLocalizations l10n, StaffContractDraft draft) => [
    StaffLabels.contract(l10n, draft.kind),
    ?pay(l10n, draft),
    ?period(l10n, draft),
  ].join(' · ');

  /// Le montant converti comme le fera le dépôt, ou le matricule SECOPE.
  static String? pay(AppLocalizations l10n, StaffContractDraft draft) {
    if (draft.isConventionne) {
      final secope = draft.secopeNumber.trim();
      return secope.isEmpty ? null : l10n.staffPaySecope(secope);
    }
    final cents = AmountInput.toCents(draft.amount);
    if (cents == null) return null;
    final amount = MoneyFormat.format(Money.parse(cents, draft.currency));
    return switch ((draft.kind, draft.payMode)) {
      (StaffContractKind.vacataire, StaffPayMode.hourly) =>
        l10n.staffPayHourlyRate(amount),
      (StaffContractKind.vacataire, _) => l10n.staffPayMonthlyFlat(amount),
      _ => l10n.staffPaySalary(amount),
    };
  }

  static String? period(AppLocalizations l10n, StaffContractDraft draft) {
    final from = draft.effectiveFrom;
    if (from == null) return null;
    final ends = draft.endsOn;
    return ends == null
        ? l10n.staffContractFrom(formatIsoDay(from))
        : l10n.staffContractBetween(formatIsoDay(from), formatIsoDay(ends));
  }
}
