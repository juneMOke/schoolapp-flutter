import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_bar_rows.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_dashboard_tones.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_dashboard_view.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_section_note.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_type_tag.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/dashboard/expense_section_head.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les cinq postes les plus coûteux — un clic ouvre le registre pré-filtré
/// sur le poste (spec, sorties de navigation).
class ExpenseTopTypesCard extends StatelessWidget {
  final ExpenseDashboardView view;
  final ValueChanged<String> onOpenType;

  const ExpenseTopTypesCard({
    super.key,
    required this.view,
    required this.onOpenType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byCount = view.sharesRankedByCount;
    return ExpenseCard(
      surfaceColor: ExpenseDashboardTones.fondNeutre,
      borderColor: ExpenseDashboardTones.bordNeutre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpenseSectionHead(
            accent: ExpenseDashboardTones.accentNeutre,
            accentSoft: ExpenseDashboardTones.accentSoftNeutre,
            icon: Icons.bar_chart_rounded,
            title: l10n.expenseTopTypesTitle,
            subtitle: l10n.expenseTopTypesSubtitle,
          ),
          EteeloBarRows(
            scale: EteeloBarRowsScale.byMax,
            rows: [
              for (final share in view.shares.take(5))
                EteeloBarRow(
                  label: share.type?.shortLabel ?? l10n.expenseTypeUnknown,
                  value: byCount
                      ? share.totals.count.toDouble()
                      : share.totals.usdCents! / 100,
                  valueLabel: byCount
                      ? l10n.expenseDayCount(share.totals.count)
                      : ExpenseMoneyText.usd(share.totals.usdCents!),
                  color: ExpenseTypeColors.of(share.type).color,
                  onTap: () => onOpenType(share.typeId),
                  semanticsLabel: l10n.expenseTopTypeA11y(
                    share.type?.label ?? l10n.expenseTypeUnknown,
                  ),
                ),
            ],
          ),
          if (byCount) ExpenseSectionNote(text: l10n.expenseSharesByCountNote),
        ],
      ),
    );
  }
}
