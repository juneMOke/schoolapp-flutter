import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStatsDashboardHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final EnrollmentStatsState state;

  const EnrollmentStatsDashboardHeader({
    super.key,
    required this.l10n,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final schoolYear = state.stats?.context.schoolYear;
    final effectiveSchoolYear = schoolYear ?? l10n.enrollmentStatsSchoolYearUnavailable;

    return Semantics(
      container: true,
      header: true,
      label: l10n.enrollmentStatsHeaderA11yLabel(effectiveSchoolYear),
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
                Icons.pie_chart_rounded,
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
                    l10n.enrollmentStatsDashboardTitle,
                    style: AppTextStyles.totalAmountLora.copyWith(
                      color: AppColors.bleuArdoise,
                      fontSize: AppDimensions.enrollmentStatsHeaderTitleFontSize,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    effectiveSchoolYear,
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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