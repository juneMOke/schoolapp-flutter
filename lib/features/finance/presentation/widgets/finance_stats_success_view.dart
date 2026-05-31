import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_stats.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_evolution_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_fee_type_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_kpi_band.dart';

class FinanceStatsSuccessView extends StatelessWidget {
  final FinanceStats stats;

  const FinanceStatsSuccessView({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceStatsKpiBand(
          kpis: stats.kpis,
          distribution: stats.distributionByFeeType,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        FinanceStatsEvolutionSection(evolution: stats.evolution),
        const SizedBox(height: AppDimensions.spacingL),
        FinanceStatsFeeTypeSection(distribution: stats.distributionByFeeType),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }
}
