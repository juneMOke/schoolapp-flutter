import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Groupe encadré d'un mode de recherche (« Par nom » / « Par cycle/niveau »).
///
/// Quand le groupe est complet ([isComplete]), il passe en vert doux pour
/// signaler que ce mode est armé.
class SearchGroupBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isComplete;
  final Widget child;

  const SearchGroupBox({
    super.key,
    required this.icon,
    required this.title,
    required this.isComplete,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isComplete
        ? AppColors.feeStatusPaidBorder
        : AppColors.border;
    final fillColor = isComplete
        ? AppColors.feeStatusPaidSoft
        : Colors.transparent;
    final accentColor = isComplete
        ? AppColors.feeStatusPaid
        : AppColors.bleuArdoise;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isComplete)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: AppColors.feeStatusPaid,
                ),
            ],
          ),
          const SizedBox(
            height: AppDimensions.spacingS + AppDimensions.spacingXS,
          ),
          child,
        ],
      ),
    );
  }
}
