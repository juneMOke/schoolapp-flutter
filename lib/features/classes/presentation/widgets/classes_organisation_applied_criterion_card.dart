import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class ClassesOrganisationAppliedCriterionCard extends StatelessWidget {
  final String label;
  final String value;

  const ClassesOrganisationAppliedCriterionCard({
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: AppColors.bleuArdoise.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.bleuArdoise,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              '$label: $value',
              style: AppTextStyles.body.copyWith(
                color: AppColors.bleuArdoise,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
