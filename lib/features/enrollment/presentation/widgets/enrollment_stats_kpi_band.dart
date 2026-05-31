import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bande KPI adaptée aux données [EnrollmentKpis].
class EnrollmentStatsKpiBand extends StatelessWidget {
  final EnrollmentKpis kpis;

  const EnrollmentStatsKpiBand({super.key, required this.kpis});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return KpiBand(
      cards: [
        KpiCardData(
          label: l10n.enrollmentStatsKpiTotal,
          value: kpis.totalEnrollments.value,
          accent: AppColors.enrollmentStatsAccent,
          accentSoft: AppColors.enrollmentStatsAccentSoft,
          icon: Icons.people_rounded,
        ),
        KpiCardData(
          label: l10n.enrollmentStatsKpiFirst,
          value: kpis.firstEnrollments.value,
          percent: kpis.firstEnrollments.percentOfTotal,
          accent: AppColors.enrollmentStatsFirst,
          accentSoft: AppColors.enrollmentStatsFirstSoft,
          icon: Icons.person_add_rounded,
        ),
        KpiCardData(
          label: l10n.enrollmentStatsKpiRe,
          value: kpis.reEnrollments.value,
          percent: kpis.reEnrollments.percentOfTotal,
          accent: AppColors.enrollmentStatsRe,
          accentSoft: AppColors.enrollmentStatsReSoft,
          icon: Icons.refresh_rounded,
        ),
        KpiCardData(
          label: l10n.enrollmentStatsKpiPre,
          value: kpis.preEnrollments.value,
          percent: kpis.preEnrollments.percentOfTotal,
          accent: AppColors.enrollmentStatsPre,
          accentSoft: AppColors.enrollmentStatsPreSoft,
          icon: Icons.pending_actions_rounded,
        ),
        KpiCardData(
          label: l10n.enrollmentStatsKpiInProgress,
          value: kpis.inProgress.value,
          percent: kpis.inProgress.percentOfTotal,
          accent: AppColors.enrollmentStatsInProgress,
          accentSoft: AppColors.enrollmentStatsInProgressSoft,
          icon: Icons.hourglass_top_rounded,
        ),
      ],
    );
  }
}
