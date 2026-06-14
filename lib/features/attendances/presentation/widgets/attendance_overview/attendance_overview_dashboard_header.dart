import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/attendance_overview/attendance_overview_period_filter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête du tableau de bord : sur-titre + titre à gauche, sélecteur de
/// période à droite (passe dessous en cas de largeur insuffisante).
class AttendanceOverviewDashboardHeader extends StatelessWidget {
  const AttendanceOverviewDashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppDimensions.spacingM,
      spacing: AppDimensions.spacingM,
      children: [
        Semantics(
          header: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppDimensions.spacingXL + AppDimensions.spacingXS,
                height: AppDimensions.spacingXL + AppDimensions.spacingXS,
                decoration: BoxDecoration(
                  color: AppColors.bleuArdoise.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppDimensions.spacingM),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.bleuArdoise,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.attendanceOverviewEyebrow,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    l10n.attendanceOverviewTitle,
                    style: AppTextStyles.totalAmountLora.copyWith(
                      color: AppColors.bleuArdoise,
                      fontSize: AppDimensions.financeStatsHeaderTitleFontSize,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const AttendanceOverviewPeriodFilter(),
      ],
    );
  }
}
