import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

class ClassesListStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const ClassesListStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.classesSectionSurface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.classesOrganisationShadowBlur,
            offset: Offset(0, AppDimensions.spacingS),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDimensions.detailHeroAvatarSize,
            height: AppDimensions.detailHeroAvatarSize,
            decoration: BoxDecoration(
              color: AppColors.financeDetailAccentSoft,
              borderRadius: BorderRadius.circular(AppDimensions.detailHeroAvatarSize),
            ),
            child: Icon(icon, color: AppColors.financeDetailAccent),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
