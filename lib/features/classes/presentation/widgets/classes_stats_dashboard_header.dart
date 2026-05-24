import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesStatsDashboardHeader extends StatelessWidget {
  final String schoolYear;
  final AppLocalizations l10n;

  const ClassesStatsDashboardHeader({
    super.key,
    required this.schoolYear,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      header: true,
      label: l10n.classesStatsHeaderA11yLabel(schoolYear),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: AppDimensions.spacingXL + AppDimensions.spacingXS,
              height: AppDimensions.spacingXL + AppDimensions.spacingXS,
              decoration: BoxDecoration(
                color: AppColors.bleuArdoise.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDimensions.spacingM),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.bleuArdoise,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.classesStatsDashboardTitle,
                    style: AppTextStyles.totalAmountLora.copyWith(
                      color: AppColors.bleuArdoise,
                      fontSize: AppDimensions.financeStatsHeaderTitleFontSize,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    schoolYear,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
