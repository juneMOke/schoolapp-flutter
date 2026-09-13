import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_period.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les mots d'une période (spec §2) : le nom relatif (« Ce mois-ci »), la
/// période littérale (« septembre 2026 ») et la forme démonstrative des états
/// vides (« ce mois-ci »).
class ExpensePeriodLabel {
  final String relative;
  final String detail;
  final String demonstrative;

  const ExpensePeriodLabel({
    required this.relative,
    required this.detail,
    required this.demonstrative,
  });

  factory ExpensePeriodLabel.of(
    BuildContext context,
    ExpensePeriod period,
    ExpenseDateRange range,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final offset = period.offset;
    switch (period.granularity) {
      case ExpenseGranularity.day:
        return ExpensePeriodLabel(
          relative: offset == 0
              ? l10n.expensePeriodToday
              : offset == -1
              ? l10n.expensePeriodYesterday
              : l10n.expensePeriodDay,
          detail: dates.formatFullDate(range.from),
          demonstrative: l10n.expensePeriodDemonstrative('day'),
        );
      case ExpenseGranularity.week:
        return ExpensePeriodLabel(
          relative: offset == 0
              ? l10n.expensePeriodThisWeek
              : offset == -1
              ? l10n.expensePeriodLastWeek
              : l10n.expensePeriodWeek,
          detail: l10n.expensePeriodWeekRange(
            dates.formatShortMonthDay(range.from),
            dates.formatShortMonthDay(range.to),
          ),
          demonstrative: l10n.expensePeriodDemonstrative('week'),
        );
      case ExpenseGranularity.month:
        return ExpensePeriodLabel(
          relative: offset == 0
              ? l10n.expensePeriodThisMonth
              : offset == -1
              ? l10n.expensePeriodLastMonth
              : l10n.expensePeriodMonth,
          detail: dates.formatMonthYear(range.from),
          demonstrative: l10n.expensePeriodDemonstrative('month'),
        );
      case ExpenseGranularity.schoolYear:
        return ExpensePeriodLabel(
          relative: offset == 0
              ? l10n.expensePeriodThisSchoolYear
              : offset == -1
              ? l10n.expensePeriodLastSchoolYear
              : l10n.expensePeriodSchoolYear,
          detail: l10n.expensePeriodSchoolYearRange(
            range.from.year.toString(),
            range.to.year.toString(),
          ),
          demonstrative: l10n.expensePeriodDemonstrative('year'),
        );
    }
  }
}

/// Le nom d'une granularité, pour le sélecteur.
String expenseGranularityLabel(
  AppLocalizations l10n,
  ExpenseGranularity granularity,
) => switch (granularity) {
  ExpenseGranularity.day => l10n.expenseGranularityDay,
  ExpenseGranularity.week => l10n.expenseGranularityWeek,
  ExpenseGranularity.month => l10n.expenseGranularityMonth,
  ExpenseGranularity.schoolYear => l10n.expenseGranularitySchoolYear,
};
