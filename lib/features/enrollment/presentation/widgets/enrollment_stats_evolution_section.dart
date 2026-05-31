import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/evolution_line_chart.dart';
import 'package:school_app_flutter/core/components/charts/line_chart_point.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_chart_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_empty_chart_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section "Évolution des inscriptions" du dashboard.
/// Adapte [EnrollmentEvolution] vers [EvolutionLineChart].
class EnrollmentStatsEvolutionSection extends StatelessWidget {
  final EnrollmentEvolution evolution;

  const EnrollmentStatsEvolutionSection({super.key, required this.evolution});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = evolution.buckets
        .map(
          (bucket) => LineChartPoint(
            label: _shortKey(bucket.key),
            value: bucket.value.toDouble(),
            isHighlighted: bucket.isCurrent,
          ),
        )
        .toList();

    return EnrollmentStatsChartCard(
      title: l10n.enrollmentStatsSectionEvolutionEnrollments,
      child: points.isEmpty
          ? EnrollmentStatsEmptyChartState(message: l10n.enrollmentStatsNoData)
          : EvolutionLineChart(
              points: points,
              lineColor: AppColors.enrollmentStatsAccent,
              highlightColor: AppColors.enrollmentStatsRe,
            ),
    );
  }

  /// Abrège la clé de bucket pour l'affichage sur l'axe X.
  /// Ex. "2024-03" -> "03", "S12" -> "S12".
  String _shortKey(String key) {
    final parts = key.split('-');
    if (parts.length == 2) return parts[1];
    if (key.length > 6) return key.substring(key.length - 4);
    return key;
  }
}
