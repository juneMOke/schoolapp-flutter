import 'dart:math' as math;

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

  /// Hauteur totale du bloc (défaut :
  /// [AppDimensions.enrollmentStatsChartSectionHeight]).
  final double? height;

  /// Colonnes de la légende en disposition large (défaut : 1). Au-delà d'une
  /// poignée d'entrées, une colonne unique déborde la hauteur et n'est plus
  /// atteignable qu'au défilement.
  final int legendColumns;

  /// Quand vrai, l'anneau prend toute la place qu'on lui laisse au lieu des
  /// rayons fixes — [centerSpaceRadius] et [sectionRadius] sont alors ignorés.
  /// Les proportions sont conservées : le trou central garde
  /// [_centerSpaceRatio] du rayon, de quoi loger le total.
  final bool expandToFit;

  const GenderDonutChart({
    super.key,
    required this.sections,
    required this.total,
    required this.centerLabel,
    this.centerSpaceRadius,
    this.sectionRadius,
    this.compactBelow,
    this.centerValueStyle,
    this.height,
    this.legendColumns = 1,
    this.expandToFit = false,
  });

  /// Part du rayon laissée au trou central quand [expandToFit] est demandé.
  static const _centerSpaceRatio = 0.5;

  /// Épaisseur d'anneau historique, hors [expandToFit].
  static const _defaultSectionRadius = 38.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth <
            (compactBelow ?? AppBreakpoints.detailCompactMax);
        return SizedBox(
          height: height ?? AppDimensions.enrollmentStatsChartSectionHeight,
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
                    Expanded(flex: 2, child: _buildLegendColumns()),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDonut() => LayoutBuilder(
    builder: (context, constraints) {
      var center =
          centerSpaceRadius ?? AppDimensions.enrollmentStatsDonutCenterRadius;
      var ring = sectionRadius ?? _defaultSectionRadius;

      // Le disque est borné par le plus petit côté : à hauteur donnée, c'est
      // elle qui décide, sinon l'anneau déborderait de sa carte.
      final available = math.min(constraints.maxWidth, constraints.maxHeight);
      if (expandToFit && available.isFinite) {
        final outer = available / 2 - AppDimensions.spacingS;
        if (outer > 0) {
          center = outer * _centerSpaceRatio;
          ring = outer - center;
        }
      }
      return _donutStack(center, ring);
    },
  );

  Widget _donutStack(double centerRadius, double ringThickness) => Stack(
    alignment: Alignment.center,
    children: [
      PieChart(
        PieChartData(
          sections: [
            for (final section in sections) _toSection(section, ringThickness),
          ],
          centerSpaceRadius: centerRadius,
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

  /// Légende large : une ou plusieurs colonnes, chacune défilable — la légende
  /// peut compter plus de lignes que la hauteur du bloc n'en tient.
  Widget _buildLegendColumns() {
    final columns = legendColumns < 1 ? 1 : legendColumns;
    final perColumn = (sections.length / columns).ceil();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < columns; c++)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sections
                    .skip(c * perColumn)
                    .take(perColumn)
                    .map(_toLegendItem)
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }

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

  PieChartSectionData _toSection(DonutChartSection s, double ringThickness) =>
      PieChartSectionData(
        value: s.percent,
        color: s.color,
        title: '',
        radius: ringThickness,
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
