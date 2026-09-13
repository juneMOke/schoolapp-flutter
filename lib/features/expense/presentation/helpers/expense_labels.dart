import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Libellé d'une source de fonds.
String expenseFundingLabel(
  AppLocalizations l10n,
  ExpenseFundingSource source,
) => switch (source) {
  ExpenseFundingSource.cash => l10n.expenseFundingCash,
  ExpenseFundingSource.bank => l10n.expenseFundingBank,
  ExpenseFundingSource.mobileMoney => l10n.expenseFundingMobileMoney,
};

/// Le motif d'un refus serveur, dit à l'économe (A4) — par son code machine
/// quand on le connaît, par la phrase générique sinon.
String expenseRejectionLabel(AppLocalizations l10n, String? code) =>
    switch (code) {
      'UNKNOWN_EXPENSE_TYPE' => l10n.expenseRejectedUnknownType,
      'EXPENSE_DATE_IN_FUTURE' => l10n.expenseRejectedDateInFuture,
      'PAYMENT_DATE_IN_FUTURE' => l10n.expenseRejectedPaidOnInFuture,
      'HTTP_403' => l10n.expenseRejectedForbidden,
      _ => l10n.expenseRejectedGeneric,
    };
