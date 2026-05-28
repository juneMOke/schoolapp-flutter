import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FinanceStatsEvolutionSection extends StatelessWidget {
  final FinanceEvolution evolution;

  const FinanceStatsEvolutionSection({super.key, required this.evolution});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (evolution.buckets.isEmpty) {
      return FinanceStatsChartCard(
        title: l10n.financeStatsSectionEvolution,
        child: FinanceStatsEmptyState(
          message: l10n.financeStatsNoData,
          hint: l10n.financeStatsNoDataHint,
          semanticLabel: l10n.financeStatsEmptyA11yLabel,
        ),
      );
    }

    final items = [
      for (final bucket in evolution.buckets)
        BarChartItem(
          label: _shortKey(bucket.key),
          value: bucket.value.toDouble(),
          color: bucket.isCurrent
              ? AppColors.terreCuite
              : AppColors.bleuArdoise,
        ),
    ];

    final highlightedIndexes = <int>{
      for (var i = 0; i < evolution.buckets.length; i++)
        if (evolution.buckets[i].isCurrent) i,
    };

    return FinanceStatsChartCard(
      title: l10n.financeStatsSectionEvolution,
      child: Semantics(
        container: true,
        label: l10n.financeStatsEvolutionChartA11yLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CycleBarChart(items: items, highlightedIndexes: highlightedIndexes),
            const SizedBox(height: AppDimensions.spacingS),
            Row(
              children: [
                _LegendItem(
                  color: AppColors.terreCuite,
                  label: l10n.financeStatsLegendCurrentPeriod,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                _LegendItem(
                  color: AppColors.bleuArdoise,
                  label: l10n.financeStatsLegendOtherPeriods,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortKey(String key) {
    final parts = key.split('-');
    if (parts.length == 2) return parts[1];
    if (key.length > 6) return key.substring(key.length - 4);
    return key;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppDimensions.spacingS,
          height: AppDimensions.spacingS,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
