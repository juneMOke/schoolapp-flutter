import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart'
    as enrollment;
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_field_grid.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_section_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_step_constants.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_utils.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryPreviousAcademicSection extends StatelessWidget {
  final enrollment.EnrollmentDetail enrollmentDetail;
  final ValueChanged<int> onEditRequested;

  const SummaryPreviousAcademicSection({
    super.key,
    required this.enrollmentDetail,
    required this.onEditRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enrollmentData = enrollmentDetail.enrollmentDetail;
    final yearBadge = enrollmentData.validatedPreviousYear
        ? StatusBadge.enrollmentValidated(label: l10n.summaryYes)
        : StatusBadge(
            icon: Icons.remove_circle_outline,
            label: l10n.summaryNo,
            color: AppColors.textMuted,
          );

    return SummarySectionCard(
      title: l10n.previousYear,
      icon: Icons.school_outlined,
      onEdit: () => onEditRequested(EnrollmentSummarySteps.previousAcademic),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SummaryFieldGrid(
            items: [
              SummaryField(
                label: l10n.schoolLabel,
                value: EnrollmentSummaryUtils.fallbackValue(
                  l10n,
                  enrollmentData.previousSchoolName,
                ),
              ),
              SummaryField(
                label: l10n.schoolCycle,
                value: EnrollmentSummaryUtils.fallbackValue(
                  l10n,
                  enrollmentData.previousSchoolLevelGroup,
                ),
              ),
              SummaryField(
                label: l10n.schoolLevelLabel,
                value: EnrollmentSummaryUtils.fallbackValue(
                  l10n,
                  enrollmentData.previousSchoolLevel,
                ),
              ),
              SummaryField(
                label: l10n.averageLabel,
                value: EnrollmentSummaryUtils.fallbackValue(
                  l10n,
                  '${enrollmentData.previousRate}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              Text(
                l10n.yearValidated,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              yearBadge,
            ],
          ),
        ],
      ),
    );
  }
}
