import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Pastille de type d'une ligne de la liste nominative — fond doux, texte
/// accentué, bord léger.
///
/// Le type est **écrit** (« Réinscription »), l'icône et la teinte ne font que
/// l'appuyer : aucune information n'est portée par la seule couleur.
class EnrollmentEntryTypePill extends StatelessWidget {
  final String label;
  final bool isReturning;

  const EnrollmentEntryTypePill({
    super.key,
    required this.label,
    required this.isReturning,
  });

  @override
  Widget build(BuildContext context) {
    final color = isReturning
        ? AppColors.enrollmentStatsRe
        : AppColors.enrollmentStatsFirst;
    final soft = isReturning
        ? AppColors.enrollmentStatsReSoft
        : AppColors.enrollmentStatsFirstSoft;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.chipPaddingH,
        vertical: AppDimensions.chipPaddingV,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(
          AppDimensions.enrollmentDashboardPillRadius,
        ),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReturning ? Icons.refresh_rounded : Icons.person_add_rounded,
            size: AppDimensions.enrollmentDashboardTypePillIconSize,
            color: color,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.badge.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
