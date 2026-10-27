import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_dashboard_skeletons.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Le premier chargement, à la géométrie réelle : quatre chiffres, le
/// graphique des mois, puis la liste des salariés. Le mouvement réduit est
/// respecté par les squelettes du socle.
class PayrollDashboardSkeleton extends StatelessWidget {
  const PayrollDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EteeloKpiBandSkeleton(count: 4),
      SizedBox(height: AppSpacing.lg),
      EteeloChartSkeleton(),
      SizedBox(height: AppSpacing.lg),
      EteeloListSkeleton(rowCount: 6, pillCount: 3),
    ],
  );
}
