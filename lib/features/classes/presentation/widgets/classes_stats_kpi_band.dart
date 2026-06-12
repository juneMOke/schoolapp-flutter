import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bandeau KPI du tableau de bord Classes, aligné sur le composant DS partagé
/// `KpiBand`/`KpiCard` (même rendu + responsivité que les dashboards Inscription,
/// Finance et la composition des classes). Les parts filles/garçons sont
/// exposées via le badge `percent` de la carte (anciens donuts custom).
class ClassesStatsKpiBand extends StatelessWidget {
  final ClassroomStats stats;

  const ClassesStatsKpiBand({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalStudents = stats.kpis.totalActive + stats.kpis.inactive;
    final activeTotal = stats.kpis.totalActive;
    final girlsPercent = _safePercent(stats.kpis.activeGirls, activeTotal);
    final boysPercent = _safePercent(stats.kpis.activeBoys, activeTotal);

    return Semantics(
      container: true,
      label: l10n.classesStatsKpiBandA11yLabel,
      child: EteeloKpiBand(
        cards: [
          EteeloKpiCardData(
            label: l10n.classesStatsKpiTotalStudents,
            value: totalStudents,
            accent: AppColors.bleuProfond,
            accentSoft: AppColors.bleuProfond.withValues(alpha: 0.12),
            icon: Icons.groups_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.classesStatsKpiActiveGirls,
            value: stats.kpis.activeGirls,
            percent: girlsPercent,
            accent: AppColors.terreCuite,
            accentSoft: AppColors.terreCuite.withValues(alpha: 0.12),
            icon: Icons.girl_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.classesStatsKpiActiveBoys,
            value: stats.kpis.activeBoys,
            percent: boysPercent,
            accent: AppColors.bleuArdoise,
            accentSoft: AppColors.bleuArdoise.withValues(alpha: 0.12),
            icon: Icons.boy_rounded,
          ),
          EteeloKpiCardData(
            label: l10n.classesStatsKpiInactiveStudents,
            value: stats.kpis.inactive,
            accent: AppColors.warning,
            accentSoft: AppColors.warning.withValues(alpha: 0.12),
            icon: Icons.person_off_rounded,
          ),
        ],
      ),
    );
  }

  int _safePercent(int value, int total) {
    if (total <= 0) return 0;
    return ((value * 100) / total).round();
  }
}
