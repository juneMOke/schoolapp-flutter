import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';

class FinanceStatsChartCard extends StatelessWidget {
  /// `null` en chargement : le titre y est un bloc, pas un mot.
  final String? title;
  final Widget child;

  const FinanceStatsChartCard({
    super.key,
    required String this.title,
    required this.child,
  });

  /// Le **même cadre**, avec un bloc à la place du titre.
  ///
  /// Une copie du cadre dans le squelette dériverait du vrai au premier
  /// ajustement de rayon ou d'ombre — et le contenu sauterait en arrivant, ce
  /// que le squelette existe précisément pour éviter. Ici le cadre est le même
  /// objet ; seule sa première ligne change.
  const FinanceStatsChartCard.skeleton({super.key, required this.child})
    : title = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(
          AppDimensions.enrollmentStatsChartRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title case final title?)
            Text(
              title,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            )
          else
            // La hauteur du titre réel, pour que la ligne de séparation et tout
            // ce qui suit ne bouge pas d'un pixel à l'arrivée des données.
            const SizedBox(
              height: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: EteeloSkeletonBox(width: 180, height: 14),
              ),
            ),
          const SizedBox(height: AppDimensions.spacingS),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimensions.spacingM),
          child,
        ],
      ),
    );
  }
}
