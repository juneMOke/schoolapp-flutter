import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Carte KPI générique affichant un indicateur chiffré avec accent couleur.
class EteeloKpiCard extends StatelessWidget {
  final EteeloKpiCardData data;

  const EteeloKpiCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${data.label}-${data.displayValue}-${data.percent}'),
      tween: Tween(begin: 0.97, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Opacity(
        opacity: scale,
        child: Transform.scale(scale: scale, child: child),
      ),
      child: Container(
        height: AppDimensions.enrollmentStatsKpiCardHeight,
        constraints: const BoxConstraints(
          minWidth: AppDimensions.enrollmentStatsKpiCardMinWidth,
        ),
        decoration: BoxDecoration(
          color: AppColors.enrollmentStatsCardSurface,
          borderRadius: BorderRadius.circular(
            AppDimensions.enrollmentStatsChartRadius,
          ),
          border: Border(left: BorderSide(color: data.accent, width: 3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingXS),
                  decoration: BoxDecoration(
                    color: data.accentSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(data.icon, size: 14, color: data.accent),
                ),
                const Spacer(),
                if (data.percent != null)
                  Text(
                    '${data.percent} %',
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            // Garde-fou anti-débordement : les valeurs formatées (montants en
            // devise) peuvent être longues. `scaleDown` ne réduit que si besoin,
            // donc les compteurs entiers courts restent inchangés.
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  data.displayValue,
                  maxLines: 1,
                  style: AppTextStyles.pageTitle.copyWith(color: data.accent),
                ),
              ),
            ),
            // `Flexible` (fit loose) : taille naturelle quand la carte est assez
            // haute (rendu inchangé), mais se contraint à l'espace restant et
            // s'ellipse plutôt que de déborder sur les cartes étroites.
            Flexible(
              child: Text(
                data.label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
