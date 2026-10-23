import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_dashboard_skeletons.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_two_columns.dart';

/// Le premier chargement, à la géométrie réelle : trois indicateurs, les deux
/// cartes de répartition, puis la liste. Le mouvement réduit est respecté par
/// les squelettes du socle.
class HrDashboardSkeleton extends StatelessWidget {
  const HrDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EteeloKpiBandSkeleton(count: 3),
      SizedBox(height: AppSpacing.lg),
      HrTwoColumns(
        first: EteeloBarRowsSkeleton(
          rows: 3,
          labelWidth: AppDimensions.hrBarLabelWidth,
        ),
        second: EteeloBarRowsSkeleton(
          rows: 4,
          labelWidth: AppDimensions.hrBarLabelWidth,
        ),
      ),
      SizedBox(height: AppSpacing.lg),
      EteeloListSkeleton(rowCount: 6, pillCount: 3),
    ],
  );
}
