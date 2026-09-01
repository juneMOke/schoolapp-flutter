import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/gender_donut_chart.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_level_donut.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_chart_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_empty_chart_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section « Répartition des effectifs par classe » du dashboard.
/// Agrège les niveaux depuis [CycleDistribution] vers un anneau de répartition.
class EnrollmentStatsCycleSection extends StatelessWidget {
  final CycleDistribution distribution;

  const EnrollmentStatsCycleSection({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final donut = buildLevelDonut(distribution);
    final layout = levelDonutLayout(donut.sections.length);

    return EnrollmentStatsChartCard(
      title: l10n.enrollmentStatsSectionLevelDistribution,
      child: donut.total <= 0
          ? EnrollmentStatsEmptyChartState(message: l10n.enrollmentStatsNoData)
          // Le donut porte lui-même le total central et une légende texte
          // (classe + effectif + %) : l'information n'est jamais portée par la
          // seule couleur.
          : Semantics(
              label: l10n.enrollmentStatsSectionLevelDistribution,
              child: GenderDonutChart(
                sections: donut.sections,
                total: donut.total,
                centerLabel: l10n.enrollmentStatsStudents,
                height: layout.height,
                legendColumns: layout.columns,
                expandToFit: true,
              ),
            ),
    );
  }
}
