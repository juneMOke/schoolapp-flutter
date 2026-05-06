import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// CTA de creation de cas disciplinaire, inspire du composant finance.
class DisciplinaryCaseCreateCta extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final String subtitle;

  const DisciplinaryCaseCreateCta({
    super.key,
    required this.onPressed,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.disciplinaryDetailAccent,
                AppColors.disciplinaryDetailTeal,
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
            boxShadow: const [
              BoxShadow(
                color: AppColors.disciplinaryDetailShadow,
                blurRadius: AppDimensions.financeDetailCardShadowBlur,
                offset: Offset(0, AppDimensions.financeDetailCardShadowOffsetY),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingM,
            ),
            child: Row(
              children: [
                Container(
                  width: AppDimensions.spacingXL + AppDimensions.spacingM,
                  height: AppDimensions.spacingXL + AppDimensions.spacingM,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.spacingM),
                  ),
                  child: const Icon(
                    Icons.add_task_outlined,
                    size: AppDimensions.detailHeaderIconSize,
                    color: AppColors.surface,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.sectionTitle.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.surface.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.surface,
                  size: AppDimensions.detailHeaderIconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
