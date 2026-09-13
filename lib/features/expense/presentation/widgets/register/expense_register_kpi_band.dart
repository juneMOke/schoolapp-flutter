import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_kpi_cards.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_register_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre compteurs de la sélection (spec §4) — ils décrivent exactement
/// ce que le registre affiche, filtres compris, et ne filtrent rien : une
/// tuile qui ne filtre pas ne doit rien promettre (pas de `onTap`).
class ExpenseRegisterKpiBand extends StatelessWidget {
  final ExpenseRegisterView view;

  /// La période littérale — seul endroit où elle se répète sous les tuiles.
  final String periodDetail;

  const ExpenseRegisterKpiBand({
    super.key,
    required this.view,
    required this.periodDetail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      label: l10n.expenseKpiShownA11y(view.rows.length),
      child: EteeloKpiBand(
        cards: [
          expenseMoneyKpi(
            l10n: l10n,
            label: l10n.expenseKpiSelectionTotal,
            totals: view.total,
            accent: AppColors.terreCuite,
            accentSoft: AppColors.terreCuiteSoft,
            icon: Icons.account_balance_wallet_outlined,
            subline:
                view.total.usdCents == null && view.total.bag.isMultiCurrency
                ? l10n.expenseKpiNoRate
                : null,
          ),
          expenseMoneyKpi(
            l10n: l10n,
            label: l10n.expenseKpiPaid,
            totals: view.paid,
            accent: AppColors.feeStatusPaid,
            accentSoft: AppColors.feeStatusPaidSoft,
            icon: Icons.check_circle_outline,
            subline: l10n.expenseKpiPaidCount(view.paid.count),
          ),
          expenseMoneyKpi(
            l10n: l10n,
            label: l10n.expenseKpiUnpaid,
            totals: view.unpaid,
            accent: AppColors.feeStatusPartial,
            accentSoft: AppColors.feeStatusPartialSoft,
            icon: Icons.schedule,
            subline: l10n.expenseKpiUnpaidCount(view.unpaid.count),
          ),
          EteeloKpiCardData(
            label: l10n.expenseKpiShown,
            value: view.rows.length,
            accent: AppColors.bleuArdoise,
            accentSoft: AppColors.bleuArdoiseSoft,
            icon: Icons.receipt_long_outlined,
            subline: periodDetail,
          ),
        ],
      ),
    );
  }
}
