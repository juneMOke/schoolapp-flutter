import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/evolution_line_chart.dart';
import 'package:school_app_flutter/core/components/charts/line_chart_point.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_evolution_granularity.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section « Évolution » du tableau de bord des présences : courbe du taux de
/// présence par bucket (mois / semaine / jour) avec ligne d'objectif.
///
/// Lecture seule. Le bucket courant est mis en évidence et l'indice de la carte
/// décrit la granularité affichée.
class AttendanceOverviewEvolutionSection extends StatelessWidget {
  final AttendanceEvolution evolution;

  const AttendanceOverviewEvolutionSection({
    super.key,
    required this.evolution,
  });

  /// Indice de la carte selon la granularité des buckets.
  String _hint(AppLocalizations l10n) => switch (evolution.granularity) {
    AttendanceEvolutionGranularity.month =>
      l10n.attendanceOverviewEvolutionHintMonth,
    AttendanceEvolutionGranularity.week =>
      l10n.attendanceOverviewEvolutionHintWeek,
    AttendanceEvolutionGranularity.day =>
      l10n.attendanceOverviewEvolutionHintDay,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AttendanceOverviewCard(
      title: l10n.attendanceOverviewEvolutionTitle,
      hint: _hint(l10n),
      child: evolution.buckets.isEmpty
          ? _buildPlaceholder(l10n)
          : _buildChart(l10n),
    );
  }

  /// Courbe du taux de présence (un point par bucket, objectif à 95 %).
  Widget _buildChart(AppLocalizations l10n) {
    // Accent garanti sur le dernier point (marqueur terre-cuite de la spec),
    // même si le backend ne marque aucun bucket `isCurrent`.
    final lastIndex = evolution.buckets.length - 1;
    final points = [
      for (var i = 0; i < evolution.buckets.length; i++)
        LineChartPoint(
          label: evolution.buckets[i].key,
          value: evolution.buckets[i].presenceRate,
          isHighlighted: evolution.buckets[i].isCurrent || i == lastIndex,
        ),
    ];

    return Semantics(
      label: l10n.attendanceOverviewEvolutionTitle,
      child: EvolutionLineChart(
        points: points,
        lineColor: AppColors.vertSavane,
        highlightColor: AppColors.terreCuite,
        minY: AppDimensions.attendanceOverviewTrendMinRate,
        maxY: AppDimensions.attendanceOverviewTrendMaxRate,
        targetLine: AppDimensions.attendanceOverviewTargetRate,
        targetLineColor: AppColors.terreCuite,
        targetLineLabel: l10n.attendanceOverviewEvolutionTarget(
          AppDimensions.attendanceOverviewTargetRate.toInt().toString(),
        ),
        leftLabelFormatter: (value) => '${value.toInt()} %',
      ),
    );
  }

  /// Substitut discret affiché quand aucun bucket n'est disponible.
  Widget _buildPlaceholder(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingL),
      child: Text(
        l10n.attendanceOverviewEmptyDescription,
        style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}
