import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_cycle_section.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_evolution_section.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_gender_section.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_kpi_band.dart';

class EnrollmentStatsSuccessView extends StatelessWidget {
  final EnrollmentStats stats;

  const EnrollmentStatsSuccessView({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EnrollmentStatsKpiBand(kpis: stats.kpis),
        const SizedBox(height: AppDimensions.spacingL),
        EnrollmentStatsEvolutionSection(evolution: stats.evolution),
        const SizedBox(height: AppDimensions.spacingL),
        EnrollmentStatsCycleSection(distribution: stats.distributionByCycle),
        const SizedBox(height: AppDimensions.spacingL),
        EnrollmentStatsGenderSection(distribution: stats.distributionByGender),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }
}
