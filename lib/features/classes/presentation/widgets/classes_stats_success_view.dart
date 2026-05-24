import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_stats.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_cycle_section.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_detail_section.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_kpi_band.dart';

class ClassesStatsSuccessView extends StatelessWidget {
  final ClassroomStats stats;

  const ClassesStatsSuccessView({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassesStatsKpiBand(stats: stats),
        const SizedBox(height: AppDimensions.spacingL),
        ClassesStatsCycleSection(stats: stats),
        const SizedBox(height: AppDimensions.spacingL),
        ClassesStatsDetailSection(stats: stats),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }
}
