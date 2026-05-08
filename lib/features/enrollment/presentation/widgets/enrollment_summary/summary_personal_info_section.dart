import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart'
    as enrollment;
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_field_grid.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_section_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_step_constants.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_utils.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryPersonalInfoSection extends StatelessWidget {
  final enrollment.EnrollmentDetail enrollmentDetail;
  final ValueChanged<int> onEditRequested;

  const SummaryPersonalInfoSection({
    super.key,
    required this.enrollmentDetail,
    required this.onEditRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = enrollmentDetail.studentDetail;

    return SummarySectionCard(
      title: l10n.personalInformation,
      icon: Icons.person_outline,
      onEdit: () => onEditRequested(EnrollmentSummarySteps.personalInfo),
      child: SummaryFieldGrid(
        items: [
          SummaryField(
            label: l10n.dateOfBirth,
            value: EnrollmentSummaryUtils.fallbackValue(
              l10n,
              student.dateOfBirth,
            ),
          ),
          SummaryField(
            label: l10n.birthPlace,
            value: EnrollmentSummaryUtils.fallbackValue(
              l10n,
              student.birthPlace,
            ),
          ),
          SummaryField(
            label: l10n.nationality,
            value: EnrollmentSummaryUtils.fallbackValue(
              l10n,
              student.nationality,
            ),
          ),
          SummaryField(
            label: l10n.gender,
            value: EnrollmentSummaryUtils.genderLabel(
              student.gender.name,
              l10n,
            ),
          ),
        ],
      ),
    );
  }
}
