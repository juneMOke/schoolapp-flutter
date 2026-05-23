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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.enrollmentStatsDashboardTitle,
          style: AppTextStyles.pageTitle.copyWith(color: AppColors.textPrimary),
        ),
        if (state.stats != null) ...[
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            state.stats!.context.schoolYear,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}
