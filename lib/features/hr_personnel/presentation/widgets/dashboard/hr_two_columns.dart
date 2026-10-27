import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// « Par catégorie » et « Parité » côte à côte au-delà de
/// [AppDimensions.hrDashboardTwoColumnsMinWidth], l'une sous l'autre en deçà.
/// Alignées en haut : leurs hauteurs diffèrent, aucune ne s'étire.
class HrTwoColumns extends StatelessWidget {
  final Widget first;
  final Widget second;

  /// Les parts de largeur des deux colonnes côte à côte (1 : 1 par défaut).
  final int firstFlex;
  final int secondFlex;

  const HrTwoColumns({
    super.key,
    required this.first,
    required this.second,
    this.firstFlex = 1,
    this.secondFlex = 1,
  });

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
          Expanded(flex: firstFlex, child: first),
          const SizedBox(width: AppSpacing.lg),
          Expanded(flex: secondFlex, child: second),
        ],
      );
    },
  );
}
