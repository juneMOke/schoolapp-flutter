import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/level_code_sorter.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_chart_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_empty_chart_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section "Évolution par niveau" du dashboard.
/// Agrège les niveaux depuis [CycleDistribution] vers [CycleBarChart].
class EnrollmentStatsCycleSection extends StatelessWidget {
  final CycleDistribution distribution;

  const EnrollmentStatsCycleSection({super.key, required this.distribution});

  static const _levelColors = [
    AppColors.enrollmentStatsAccent,
    AppColors.enrollmentStatsFirst,
    AppColors.enrollmentStatsRe,
    AppColors.enrollmentStatsPre,
    AppColors.enrollmentStatsInProgress,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final levelTotals = <String, int>{};
    for (final cycle in distribution.cycles) {
      for (final level in cycle.levels) {
        levelTotals[level.code] = (levelTotals[level.code] ?? 0) + level.value;
      }
    }

    final levelEntries = levelTotals.entries.toList()
      ..sort((a, b) => compareLevelCodes(a.key, b.key));

    final items = [
      for (int i = 0; i < levelEntries.length; i++)
        BarChartItem(
          label: levelEntries[i].key,
          value: levelEntries[i].value.toDouble(),
          color: _levelColors[i % _levelColors.length],
        ),
    ];

    return EnrollmentStatsChartCard(
      title: l10n.enrollmentStatsSectionLevelEvolution,
      child: items.isEmpty
          ? EnrollmentStatsEmptyChartState(message: l10n.enrollmentStatsNoData)
          : CycleBarChart(items: items),
    );
  }
}