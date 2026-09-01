import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/motion/eteelo_entrance.dart';
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
    // Les blocs se posent en cascade, du haut vers le bas. Chaque rang est
    // republié à son contenu : les graphiques attendent que leur carte soit là
    // avant de se tracer.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EteeloEntrance(
          index: 0,
          child: EnrollmentStatsKpiBand(kpis: stats.kpis),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        EteeloEntrance(
          index: 1,
          child: EnrollmentStatsEvolutionSection(evolution: stats.evolution),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        EteeloEntrance(
          index: 2,
          child: EnrollmentStatsCycleSection(
            distribution: stats.distributionByCycle,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        EteeloEntrance(
          index: 3,
          child: EnrollmentStatsGenderSection(
            distribution: stats.distributionByGender,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }
}
