import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Tuile d'information reutilisable pour les sections Finance detail/create.
class FinanceInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final double width;
  final Color backgroundColor;
  final Color borderColor;
  final Color valueColor;
  final double? valueFontSize;

  const FinanceInfoTile({
    super.key,
    required this.label,
    required this.value,
    required this.width,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.valueColor = AppColors.textPrimary,
    this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.spacingM),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.tableHeader.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              value,
              style: AppTextStyles.bodyStrong.copyWith(
                color: valueColor,
                fontSize: valueFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
