import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_dashboard_tones.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_money_text.dart';
import 'package:school_app_flutter/features/expense/presentation/projections/expense_dashboard_view.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_card.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_section_note.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/common/expense_type_tag.dart';
import 'package:school_app_flutter/features/expense/presentation/widgets/dashboard/expense_section_head.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Répartition par type : un anneau et sa légende chiffrée — la part de chaque
/// poste dans le total décaissé.
///
/// L'anneau partagé du socle compte des effectifs ; celui-ci pèse des
/// **montants**. Sans lecture en dollars (A5), les parts ne se comparent pas
/// entre devises : l'anneau répartit alors le **nombre** de dépenses, et une
/// note le dit.
class ExpenseBreakdownCard extends StatelessWidget {
  final ExpenseDashboardView view;

  const ExpenseBreakdownCard({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final byCount = view.sharesRankedByCount;
    num weight(ExpenseTypeShare s) =>
        byCount ? s.totals.count : (s.totals.usdCents ?? 0);
    final total = view.shares.fold<num>(0, (sum, s) => sum + weight(s));
    return ExpenseCard(
      surfaceColor: ExpenseDashboardTones.fondMarque,
      borderColor: ExpenseDashboardTones.bordMarque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpenseSectionHead(
            accent: ExpenseDashboardTones.accentMarque,
            accentSoft: ExpenseDashboardTones.accentSoftMarque,
            icon: Icons.donut_large_outlined,
            title: l10n.expenseBreakdownTitle,
            subtitle: l10n.expenseBreakdownSubtitle,
          ),
          Wrap(
            spacing: AppDimensions.spacingL,
            runSpacing: AppDimensions.spacingM,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox.square(
                dimension: AppDimensions.expenseDonutHeight,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 1,
                    centerSpaceRadius: AppDimensions.expenseDonutHeight / 3,
                    sections: [
                      for (final share in view.shares)
                        PieChartSectionData(
                          value: weight(share).toDouble(),
                          color: ExpenseTypeColors.of(share.type).color,
                          title: '',
                          radius: AppDimensions.expenseDonutHeight / 8,
                        ),
                    ],
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppDimensions.expenseDetailDialogMaxWidth / 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Les six premiers : au-delà, la légende d'un anneau se
                    // tronquerait en silence.
                    for (final share in view.shares.take(6))
                      _LegendRow(
                        share: share,
                        percent: total <= 0
                            ? 0
                            : (weight(share) * 100 / total).round(),
                        valueText: byCount
                            ? l10n.expenseDayCount(share.totals.count)
                            : ExpenseMoneyText.usd(share.totals.usdCents ?? 0),
                      ),
                  ],
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

class _LegendRow extends StatelessWidget {
  final ExpenseTypeShare share;
  final int percent;
  final String valueText;

  const _LegendRow({
    required this.share,
    required this.percent,
    required this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXS),
      child: Row(
        children: [
          Container(
            width: AppDimensions.expenseLegendDotSize,
            height: AppDimensions.expenseLegendDotSize,
            decoration: BoxDecoration(
              color: ExpenseTypeColors.of(share.type).color,
              borderRadius: BorderRadius.circular(
                AppDimensions.expenseLegendDotRadius,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              share.type?.shortLabel ?? l10n.expenseTypeUnknown,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(valueText, style: AppTextStyles.moneyTabular),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            l10n.expensePercent(percent),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMutedAa),
          ),
        ],
      ),
    );
  }
}
