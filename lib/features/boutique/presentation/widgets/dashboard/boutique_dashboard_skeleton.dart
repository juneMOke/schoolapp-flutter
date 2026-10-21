import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_dashboard_skeletons.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Le squelette reprend la **même grille** que l'écran prêt : quatre tuiles,
/// un graphique, deux cartes. Jamais de spinner centré.
class BoutiqueDashboardSkeleton extends StatelessWidget {
  static const int _kpiCount = 4;
  static const int _barRows = 4;

  const BoutiqueDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EteeloKpiBandSkeleton(count: _kpiCount),
      SizedBox(height: AppDimensions.spacingM),
      EteeloChartSkeleton(),
      SizedBox(height: AppDimensions.spacingM),
      EteeloBarRowsSkeleton(rows: _barRows),
      SizedBox(height: AppDimensions.spacingM),
      EteeloBarRowsSkeleton(rows: _barRows),
    ],
  );
}
