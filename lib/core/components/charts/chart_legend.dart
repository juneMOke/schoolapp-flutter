import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/bar_chart_segment.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// La légende d'un graphique empilé : une pastille et un nom par part, dans
/// l'ordre de l'empilement. Elle passe à la ligne quand la largeur manque.
class ChartLegend extends StatelessWidget {
  /// Seuls le nom et la teinte sont lus.
  final List<BarChartSegment> entries;

  const ChartLegend({super.key, required this.entries});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppDimensions.spacingM,
    runSpacing: AppDimensions.spacingXS,
    children: [
      for (final entry in entries)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppDimensions.spacingS,
              height: AppDimensions.spacingS,
              decoration: BoxDecoration(
                color: entry.color,
                borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingXS),
            Text(
              entry.label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
    ],
  );
}
