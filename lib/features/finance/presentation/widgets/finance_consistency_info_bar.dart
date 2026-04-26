import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Barre d'information de cohérence — indique si la somme des allocations
/// correspond au montant global attendu.
///
/// - [isConsistent] : `true` → fond vert success, `false` → fond ambre warning.
/// - [message] : texte explicatif localisé passé par le parent.
class FinanceConsistencyInfoBar extends StatelessWidget {
  final String message;
  final bool isConsistent;

  const FinanceConsistencyInfoBar({
    super.key,
    required this.message,
    required this.isConsistent,
  });

  @override
  Widget build(BuildContext context) {
    final background = isConsistent
        ? AppColors.financeDetailSuccessSoft
        : AppColors.financeDetailWarningSoft;
    final foreground = isConsistent
        ? AppColors.financeDetailChargesAccent
        : AppColors.financeDetailAmber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: foreground.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isConsistent
                ? Icons.check_circle_outline
                : Icons.warning_amber_rounded,
            size: AppDimensions.detailMiniIconSize,
            color: foreground,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
