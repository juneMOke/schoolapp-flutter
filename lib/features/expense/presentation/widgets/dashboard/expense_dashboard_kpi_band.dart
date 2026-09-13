import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_kpi_cards.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_type_visuals.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_dashboard_view.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_type_tag.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre chiffres clés du tableau de bord : total dépensé (et sa
/// variation), restant à payer, nombre et moyenne, poste principal.
class ExpenseDashboardKpiBand extends StatelessWidget {
  final ExpenseDashboardView view;

  /// « mois précédent » — la référence de la variation, accordée.
  final String previousLabel;

  const ExpenseDashboardKpiBand({
    super.key,
    required this.view,
    required this.previousLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloKpiBand(
      cards: [
        _total(l10n),
        expenseMoneyKpi(
          l10n: l10n,
          label: l10n.expenseKpiRemaining,
          totals: view.unpaid,
          accent: AppColors.feeStatusPartial,
          accentSoft: AppColors.feeStatusPartialSoft,
          icon: Icons.schedule,
          subline: l10n.expenseKpiUnpaidCount(view.unpaid.count),
        ),
        EteeloKpiCardData(
          label: l10n.expenseKpiRecorded,
          value: view.total.count,
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.bleuArdoiseSoft,
          icon: Icons.receipt_long_outlined,
          subline: view.total.averageUsdCents == null
              ? null
              : l10n.expenseKpiAverage(
                  ExpenseMoneyText.usd(view.total.averageUsdCents!),
                ),
        ),
        _mainType(l10n),
      ],
    );
  }

  EteeloKpiCardData _total(AppLocalizations l10n) {
    final variation = view.variationPercent;
    final card = expenseMoneyKpi(
      l10n: l10n,
      label: l10n.expenseKpiTotalSpent,
      totals: view.total,
      accent: AppColors.terreCuite,
      accentSoft: AppColors.terreCuiteSoft,
      icon: Icons.account_balance_wallet_outlined,
    );
    if (variation == null) return card;
    // Hausse en rouge, baisse en vert : l'axe du bien est inversé par rapport
    // aux recettes — la couleur est portée par le mot, jamais seule.
    final trend = view.variationElapsedOnly
        ? l10n.expenseVariationElapsed(_signed(variation), previousLabel)
        : l10n.expenseVariation(_signed(variation), previousLabel);
    return EteeloKpiCardData(
      label: card.label,
      valueText: card.valueText,
      valueLines: card.valueLines,
      accent: card.accent,
      accentSoft: card.accentSoft,
      icon: card.icon,
      subline: card.subline == null
          ? trend
          : l10n.expenseJoin(card.subline!, trend),
    );
  }

  EteeloKpiCardData _mainType(AppLocalizations l10n) {
    if (view.shares.isEmpty) {
      return EteeloKpiCardData(
        label: l10n.expenseKpiMainType,
        valueText: l10n.expenseNoValue,
        accent: AppColors.textMuted,
        accentSoft: AppColors.surfaceAlt,
        icon: Icons.layers_outlined,
        subline: l10n.expenseKpiMainTypeNone,
      );
    }
    final top = view.shares.first;
    final colors = ExpenseTypeColors.of(top.type);
    final usd = top.totals.usdCents;
    final total = view.total.usdCents;
    return EteeloKpiCardData(
      label: l10n.expenseKpiMainType,
      valueText: top.type?.shortLabel ?? l10n.expenseTypeUnknown,
      accent: colors.color,
      accentSoft: colors.soft,
      icon: top.type == null
          ? ExpenseTypeVisuals.fallbackIcon
          : ExpenseTypeVisuals.icon(top.type!.icon),
      subline: usd != null && total != null && total > 0
          ? l10n.expenseKpiMainTypeShare(
              ExpenseMoneyText.usd(usd),
              (usd * 100 / total).round(),
            )
          : l10n.expenseDayCount(top.totals.count),
    );
  }

  static String _signed(int value) => value > 0 ? '+$value' : '$value';
}
