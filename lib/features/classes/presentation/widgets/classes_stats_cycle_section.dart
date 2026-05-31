import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_item.dart';
import 'package:school_app_flutter/core/components/charts/cycle_bar_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_chart_card.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_empty_chart_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesStatsCycleSection extends StatefulWidget {
  final ClassroomStats stats;

  const ClassesStatsCycleSection({super.key, required this.stats});

  @override
  State<ClassesStatsCycleSection> createState() =>
      _ClassesStatsCycleSectionState();
}

class _ClassesStatsCycleSectionState extends State<ClassesStatsCycleSection> {
  int _selectedCycleIndex = 0;

  static const _cycleColors = [
    AppColors.bleuArdoise,
    AppColors.orDoux,
    AppColors.vertSavane,
    AppColors.terreCuite,
  ];

  static const _levelColors = [
    AppColors.bleuProfond,
    AppColors.bleuArdoise,
    AppColors.orDoux,
    AppColors.vertSavane,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cycles = widget.stats.distributionByCycle;

    if (cycles.isEmpty) {
      return ClassesStatsChartCard(
        title: l10n.classesStatsSectionCycleDistribution,
        child: ClassesStatsEmptyChartState(message: l10n.classesStatsNoData),
      );
    }

    final safeSelectedIndex = _selectedCycleIndex.clamp(0, cycles.length - 1);
    final selectedCycle = cycles[safeSelectedIndex];

    final cycleItems = [
      for (int i = 0; i < cycles.length; i++)
        BarChartItem(
          label: cycles[i].cycleCode,
          value: cycles[i].total.toDouble(),
          color: _cycleColors[i % _cycleColors.length],
        ),
    ];

    final levelItems = [
      for (int i = 0; i < selectedCycle.levels.length; i++)
        BarChartItem(
          label: selectedCycle.levels[i].levelCode,
          value: selectedCycle.levels[i].total.toDouble(),
          color: _levelColors[i % _levelColors.length],
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassesStatsChartCard(
          title: l10n.classesStatsSectionCycleDistribution,
          child: Semantics(
            container: true,
            label: l10n.classesStatsCycleChartA11yLabel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CycleBarChart(
                  items: cycleItems,
                  highlightedIndexes: {safeSelectedIndex},
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Wrap(
                  spacing: AppDimensions.spacingS,
                  runSpacing: AppDimensions.spacingS,
                  children: [
                    for (int i = 0; i < cycles.length; i++)
                      ChoiceChip(
                        label: Text(cycles[i].cycleCode),
                        selected: safeSelectedIndex == i,
                        onSelected: (_) =>
                            setState(() => _selectedCycleIndex = i),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        ClassesStatsChartCard(
          title: l10n.classesStatsSectionLevelDistribution(
            selectedCycle.cycleCode,
          ),
          child: Semantics(
            container: true,
            label: l10n.classesStatsLevelChartA11yLabel(
              selectedCycle.cycleCode,
            ),
            child: levelItems.isEmpty
                ? ClassesStatsEmptyChartState(message: l10n.classesStatsNoData)
                : CycleBarChart(items: levelItems),
          ),
        ),
      ],
    );
  }
}
