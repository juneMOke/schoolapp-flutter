import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Un encart de lecture : ce que le chiffre veut dire, et quoi en faire.
class ExpenseInsightCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color accentSoft;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ExpenseInsightCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  static const _radius = BorderRadius.all(
    Radius.circular(AppDimensions.expenseInsetRadius),
  );

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      minWidth: AppDimensions.expenseInsightMinWidth,
    ),
    child: Container(
      // Le filet recouvre le bord gauche du tour : le retrait lui réserve sa
      // largeur.
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingM + AppDimensions.expenseAccentBorderWidth,
        AppDimensions.spacingM,
        AppDimensions.spacingM,
        AppDimensions.spacingM,
      ),
      // Deux couches : Flutter ne peint un rayon que sous une bordure d'UNE
      // seule couleur visible, et lève au `paint()` sinon. Le tour gris
      // dessous, le filet d'accent seul par-dessus.
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.border),
        borderRadius: _radius,
      ),
      foregroundDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: accent,
            width: AppDimensions.expenseAccentBorderWidth,
          ),
        ),
        borderRadius: _radius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppDimensions.expenseInsightMedallionSize,
            height: AppDimensions.expenseInsightMedallionSize,
            decoration: BoxDecoration(
              color: accentSoft,
              borderRadius: BorderRadius.circular(
                AppDimensions.expenseIconBoxRadius,
              ),
            ),
            child: Icon(
              icon,
              size: AppDimensions.expenseMedallionIconSize,
              color: accent,
            ),
          ),
          const SizedBox(
            width: AppDimensions.spacingS + AppDimensions.spacingXS,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  body,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton.icon(
                    onPressed: onAction,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: AppDimensions.detailMiniIconSize,
                    ),
                    label: Text(actionLabel!),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: EdgeInsets.zero,
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
