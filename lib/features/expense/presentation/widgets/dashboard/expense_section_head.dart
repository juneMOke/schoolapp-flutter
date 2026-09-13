import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// En-tête d'une section du tableau de bord : médaillon, titre, sous-titre.
class ExpenseSectionHead extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const ExpenseSectionHead({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
    child: Row(
      children: [
        Container(
          width: AppDimensions.expenseInsightMedallionSize,
          height: AppDimensions.expenseInsightMedallionSize,
          decoration: BoxDecoration(
            color: AppColors.bleuArdoiseSoft,
            borderRadius: BorderRadius.circular(
              AppDimensions.expenseIconBoxRadius,
            ),
          ),
          child: Icon(
            icon,
            size: AppDimensions.expenseMedallionIconSize,
            color: AppColors.bleuArdoise,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS + AppDimensions.spacingXS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyStrong),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
