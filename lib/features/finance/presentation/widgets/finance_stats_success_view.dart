import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
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
    final evolution = FinanceStatsEvolutionSection(evolution: stats.evolution);
    final feeType = FinanceStatsFeeTypeSection(
      distribution: stats.distributionByFeeType,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceStatsKpiBand(
          kpis: stats.kpis,
          distribution: stats.distributionByFeeType,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        // Sur grand écran, Évolution et Répartition par frais se juxtaposent
        // pour occuper l'espace (flex 2:3 → la répartition garde ≥2 colonnes) ;
        // en dessous, elles s'empilent verticalement.
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= AppBreakpoints.financeStatsTwoColMin) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: evolution),
                  const SizedBox(width: AppDimensions.spacingL),
                  Expanded(flex: 3, child: feeType),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                evolution,
                const SizedBox(height: AppDimensions.spacingL),
                feeType,
              ],
            );
          },
        ),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }
}
