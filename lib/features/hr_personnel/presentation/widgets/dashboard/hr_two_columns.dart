import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// « Par catégorie » et « Parité » côte à côte au-delà de
/// [AppDimensions.hrDashboardTwoColumnsMinWidth], l'une sous l'autre en deçà.
/// Alignées en haut : leurs hauteurs diffèrent, aucune ne s'étire.
class HrTwoColumns extends StatelessWidget {
  final Widget first;
  final Widget second;

  const HrTwoColumns({super.key, required this.first, required this.second});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < AppDimensions.hrDashboardTwoColumnsMinWidth) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            first,
            const SizedBox(height: AppSpacing.lg),
            second,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: second),
        ],
      );
    },
  );
}
