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
    // Trois états, pas deux. « Non validée » est un redoublement ; « non
    // renseignée » n'est rien du tout, et l'afficher comme un « Non » ferait
    // lire un redoublement là où personne n'a rien dit.
    final validated = enrollmentData.validatedPreviousYear;
    final yearBadge = switch (validated) {
      true => StatusBadge.enrollmentValidated(label: l10n.summaryYes),
      false => StatusBadge(
        icon: Icons.remove_circle_outline,
        label: l10n.summaryNo,
        color: AppColors.textMuted,
      ),
      null => StatusBadge(
        icon: Icons.help_outline_rounded,
        label: l10n.yearValidationUnknown,
        color: AppColors.textMuted,
      ),
    };

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
                // Une moyenne absente se dit « — », jamais « 0% » : zéro pour
                // cent est une note, et le dossier n'en porte aucune.
                value: EnrollmentSummaryUtils.fallbackValue(
                  l10n,
                  enrollmentData.previousRate == null
                      ? ''
                      : '${enrollmentData.previousRate}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              Text(
                l10n.formerStudentLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                enrollmentData.formerStudent ? l10n.summaryYes : l10n.summaryNo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
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
