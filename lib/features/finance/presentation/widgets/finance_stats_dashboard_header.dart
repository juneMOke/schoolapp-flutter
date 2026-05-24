import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_stats_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FinanceStatsDashboardHeader extends StatelessWidget {
  final FinanceStatsState state;
  final AppLocalizations l10n;

  const FinanceStatsDashboardHeader({
    super.key,
    required this.state,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final schoolYear = state.stats?.context.schoolYear;
    final effectiveSchoolYear = schoolYear ?? l10n.financeStatsSchoolYearUnavailable;

    return Semantics(
      container: true,
      header: true,
      label: l10n.financeStatsHeaderA11yLabel(effectiveSchoolYear),
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
                    l10n.financeStatsDashboardTitle,
                    style: AppTextStyles.totalAmountLora.copyWith(
                      color: AppColors.bleuArdoise,
                      fontSize: AppDimensions.financeStatsHeaderTitleFontSize,
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
