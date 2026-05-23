import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart'
    as enrollment;
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_field_grid.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_section_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_step_constants.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_summary/summary_utils.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SummaryTargetAcademicSection extends StatelessWidget {
  final enrollment.EnrollmentDetail enrollmentDetail;
  final ValueChanged<int> onEditRequested;

  const SummaryTargetAcademicSection({
    super.key,
    required this.enrollmentDetail,
    required this.onEditRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = enrollmentDetail.studentDetail;
    final enrollmentData = enrollmentDetail.enrollmentDetail;
    final targetGroupId = enrollmentData.schoolLevelGroupId.trim().isNotEmpty
        ? enrollmentData.schoolLevelGroupId
        : student.schoolLevelGroup.id;
    final targetLevelId = enrollmentData.schoolLevelId.trim().isNotEmpty
        ? enrollmentData.schoolLevelId
        : student.schoolLevel.id;

    return BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
      buildWhen: (prev, curr) => prev.bootstrap != curr.bootstrap,
      builder: (context, state) {
        final bootstrap = state.bootstrap;
        final resolvedGroupName = EnrollmentSummaryUtils.resolveTargetGroupName(
          bootstrap: bootstrap,
          groupId: targetGroupId,
          fallbackName: student.schoolLevelGroup.name,
        );
        final resolvedLevelName = EnrollmentSummaryUtils.resolveTargetLevelName(
          bootstrap: bootstrap,
          groupId: targetGroupId,
          levelId: targetLevelId,
          fallbackName: student.schoolLevel.name,
        );

        return SummarySectionCard(
          title: l10n.targetYear,
          icon: Icons.flag_outlined,
          onEdit: () => onEditRequested(EnrollmentSummarySteps.targetAcademic),
          child: SummaryFieldGrid(
            items: [
              SummaryField(
                label: l10n.targetCycleLabel,
                value: EnrollmentSummaryUtils.fallbackValue(
                  l10n,
                  resolvedGroupName,
                ),
              ),
              SummaryField(
                label: l10n.targetLevelLabel,
                value: EnrollmentSummaryUtils.fallbackValue(
                  l10n,
                  resolvedLevelName,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
