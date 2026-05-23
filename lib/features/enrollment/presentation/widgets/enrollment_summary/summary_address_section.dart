import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart'
    as enrollment;
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_field_grid.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_section_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_step_constants.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_utils.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryAddressSection extends StatelessWidget {
  final enrollment.EnrollmentDetail enrollmentDetail;
  final ValueChanged<int> onEditRequested;

  const SummaryAddressSection({
    super.key,
    required this.enrollmentDetail,
    required this.onEditRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = enrollmentDetail.studentDetail;

    return SummarySectionCard(
      title: l10n.address,
      icon: Icons.location_on_outlined,
      onEdit: () => onEditRequested(EnrollmentSummarySteps.address),
      child: SummaryFieldGrid(
        items: [
          SummaryField(
            label: l10n.city,
            value: EnrollmentSummaryUtils.fallbackValue(l10n, student.city),
          ),
          SummaryField(
            label: l10n.district,
            value: EnrollmentSummaryUtils.fallbackValue(l10n, student.district),
          ),
          SummaryField(
            label: l10n.municipality,
            value: EnrollmentSummaryUtils.fallbackValue(
              l10n,
              student.municipality,
            ),
          ),
          SummaryField(
            label: l10n.fullAddress,
            value: EnrollmentSummaryUtils.fallbackValue(l10n, student.address),
          ),
        ],
      ),
    );
  }
}
