import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/donut_chart_section.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Graphique en anneau (donut) générique avec légende latérale.
class GenderDonutChart extends StatelessWidget {
  final List<DonutChartSection> sections;
  final int total;
  final String centerLabel;

  /// Rayon du trou central (défaut : [AppDimensions.enrollmentStatsDonutCenterRadius]).
  final double? centerSpaceRadius;

  /// Épaisseur de l'anneau, depuis le trou central (défaut : 38).
  final double? sectionRadius;

  /// Largeur utile sous laquelle on bascule en disposition empilée (donut +
  /// légende en pastilles). Défaut : [AppBreakpoints.detailCompactMax].
  final double? compactBelow;

  /// Style du nombre central (défaut : sectionTitle 20/w700). Toujours rendu en
  /// chiffres tabulaires.
  final TextStyle? centerValueStyle;

  const GenderDonutChart({
    super.key,
    required this.sections,
    required this.total,
    required this.centerLabel,
    this.centerSpaceRadius,
    this.sectionRadius,
    this.compactBelow,
    this.centerValueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth <
            (compactBelow ?? AppBreakpoints.detailCompactMax);
        return SizedBox(
          height: AppDimensions.enrollmentStatsChartSectionHeight,
          child: isCompact
              ? Column(
                  children: [
                    Expanded(child: _buildDonut()),
                    const SizedBox(height: AppDimensions.spacingS),
                    _buildLegendWrap(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: _buildDonut()),
                    const SizedBox(width: AppDimensions.spacingL),
                    Expanded(
                      flex: 2,
                      // Défilable : la légende peut compter de nombreuses lignes
                      // (ex. motifs d'absence) et dépasser la hauteur fixe.
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sections.map(_toLegendItem).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDonut() => Stack(
    alignment: Alignment.center,
    children: [
      PieChart(
        PieChartData(
          sections: sections.map(_toSection).toList(),
          centerSpaceRadius:
              centerSpaceRadius ??
              AppDimensions.enrollmentStatsDonutCenterRadius,
          sectionsSpace: 2,
          startDegreeOffset: -90,
        ),
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$total',
            style:
                (centerValueStyle ??
                        AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ))
                    .copyWith(fontFeatures: AppTextStyles.tabularFigures),
          ),
          Text(
            centerLabel,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildLegendWrap() => Wrap(
    spacing: AppDimensions.spacingS,
    runSpacing: AppDimensions.spacingXS,
    children: sections
        .map(
          (s) => Tooltip(
            message: '${s.label}: ${s.count} (${s.percent.toInt()}%)',
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingS,
                vertical: AppDimensions.spacingXS,
              ),
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${s.label} ${s.count} · ${s.percent.toInt()} %',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: AppTextStyles.tabularFigures,
                ),
              ),
            ),
          ),
        )
        .toList(),
  );

  PieChartSectionData _toSection(DonutChartSection s) => PieChartSectionData(
    value: s.percent,
    color: s.color,
    title: '',
    radius: sectionRadius ?? 38,
  );

  Widget _toLegendItem(DonutChartSection s) => Tooltip(
    message: '${s.label}: ${s.count} (${s.percent.toInt()}%)',
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXS),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${s.count}  ·  ${s.percent.toInt()} %',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
