import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/donut_chart_section.dart';
import 'package:school_app_flutter/core/components/charts/gender_donut_chart.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_chart_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_empty_chart_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section "Répartition par genre" du dashboard.
/// Adapte [GenderDistribution] vers [GenderDonutChart].
class EnrollmentStatsGenderSection extends StatelessWidget {
  final GenderDistribution distribution;

  const EnrollmentStatsGenderSection({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sections = distribution.segments.map((s) {
      final label = switch (s.code) {
        GenderSegmentCode.male => l10n.enrollmentStatsGenderMale,
        GenderSegmentCode.female => l10n.enrollmentStatsGenderFemale,
        GenderSegmentCode.other => l10n.enrollmentStatsGenderOther,
      };
      final color = switch (s.code) {
        GenderSegmentCode.male => AppColors.enrollmentStatsMale,
        GenderSegmentCode.female => AppColors.enrollmentStatsFemale,
        GenderSegmentCode.other => AppColors.enrollmentStatsInProgress,
      };
      return DonutChartSection(
        label: label,
        count: s.value,
        percent: s.percent.toDouble(),
        color: color,
      );
    }).toList();

    return EnrollmentStatsChartCard(
      title: l10n.enrollmentStatsSectionGenderEvolution,
      child: sections.isEmpty || distribution.total <= 0
          ? EnrollmentStatsEmptyChartState(message: l10n.enrollmentStatsNoData)
          : GenderDonutChart(
              sections: sections,
              total: distribution.total,
              centerLabel: l10n.enrollmentStatsStudents,
            ),
    );
  }
}
