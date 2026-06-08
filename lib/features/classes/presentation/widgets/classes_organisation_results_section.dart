import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/search/search_invitation_card.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_organisation_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_pending_distribution_card.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_split_results.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationResultsSection extends StatelessWidget {
  final ClassesOrganisationCycleOption? selectedCycle;
  final ClassesOrganisationLevelOption? selectedLevel;
  final bool isDistributing;
  final VoidCallback onDistributionRequested;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationResultsSection({
    super.key,
    required this.selectedCycle,
    required this.selectedLevel,
    required this.isDistributing,
    required this.onDistributionRequested,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (selectedCycle == null) {
      return SearchInvitationCard(
        icon: Icons.account_tree_outlined,
        title: l10n.classesOrganisationSelectCycleAndLevelTitle,
        message: l10n.classesOrganisationSelectCycleAndLevelSubtitle,
      );
    }

    if (selectedLevel == null) {
      return SearchInvitationCard(
        icon: Icons.school_outlined,
        title: l10n.classesOrganisationSelectLevelTitle,
        message: l10n.classesOrganisationSelectLevelSubtitle(
          selectedCycle!.label,
        ),
      );
    }

    return BlocBuilder<ClassroomBloc, ClassroomState>(
      buildWhen: (previous, current) =>
          previous.distributionOverviewStatus !=
              current.distributionOverviewStatus ||
          previous.distributionOverview != current.distributionOverview ||
          previous.distributionOverviewErrorType !=
              current.distributionOverviewErrorType ||
          previous.reassignStatus != current.reassignStatus ||
          previous.reassigningMemberId != current.reassigningMemberId,
      builder: (context, classroomState) {
        if (!selectedLevel!.splitIntoClassrooms) {
          final List<EnrollmentSummary> unassigned =
              classroomState.distributionOverview?.unassignedEnrollments ??
              const [];
          final maleCount = unassigned
              .where((enrollment) => enrollment.student.gender == Gender.male)
              .length;
          final femaleCount = unassigned
              .where((enrollment) => enrollment.student.gender == Gender.female)
              .length;

          return ClassesOrganisationPendingDistributionCard(
            isDistributing: isDistributing,
            overviewStatus: classroomState.distributionOverviewStatus,
            levelName: selectedLevel!.schoolLevelName,
            studentsToDistribute: unassigned.length,
            maleCount: maleCount,
            femaleCount: femaleCount,
            onDistributionRequested: onDistributionRequested,
          );
        }

        return ClassesOrganisationSplitResults(
          overviewStatus: classroomState.distributionOverviewStatus,
          overviewErrorType: classroomState.distributionOverviewErrorType,
          overview: classroomState.distributionOverview,
          isReassigning:
              classroomState.reassignStatus == ClassroomStatus.loading,
          reassigningMemberId: classroomState.reassigningMemberId,
          errorMessage:
              ClassesOrganisationPageHelpers.mapClassroomErrorToMessage(
                l10n,
                classroomState.distributionOverviewErrorType,
              ),
          onTransferTap: onTransferTap,
          onRetry: () => _retryOverview(context, selectedLevel!),
        );
      },
    );
  }

  void _retryOverview(
    BuildContext context,
    ClassesOrganisationLevelOption level,
  ) {
    final bootstrap = context.read<BootstrapCurrentYearBloc>().state.bootstrap;
    final academicYearId = bootstrap?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }
    context.read<ClassroomBloc>().add(
      ClassroomDistributionOverviewRequested(
        academicYearId: academicYearId,
        schoolLevelId: level.schoolLevelId,
      ),
    );
  }
}
