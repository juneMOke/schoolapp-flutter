import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Chrome de section du tableau de bord des présences : carte surélevée avec
/// un titre, un indice optionnel ([hint]) et un contenu. [hintTrailing] pousse
/// l'indice à droite (ex. « somme = 100 % »), sinon il suit le titre.
class AttendanceOverviewCard extends StatelessWidget {
  final String title;
  final String? hint;
  final bool hintTrailing;
  final Widget child;

  const AttendanceOverviewCard({
    super.key,
    required this.title,
    this.hint,
    this.hintTrailing = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hintWidget = hint == null
        ? null
        : Text(
            hint!,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        // Élévation douce (cohérente avec EteeloKpiCard) : les panneaux ne
        // paraissent plus plats face aux cartes KPI ombrées de la même grille.
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (hintWidget != null) ...[
                if (hintTrailing) const Spacer() else const SizedBox(width: 8),
                hintWidget,
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          child,
        ],
      ),
    );
  }
}
