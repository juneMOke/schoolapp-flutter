import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/search/search_invitation_card.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';
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

    // Source LOCALE (CF3/CF4) pour tout ce qu'affiche cette section : classes
    // + rosters composés du niveau (miroir ± transferts pending), non-affectés
    // (remplace l'aperçu online — cf. docstring de
    // `OfflineLevelUnassignedEnrollmentsRequested`), ET affectation d'un
    // non-réparti (`MemberAssignRequested` est exclusivement dispatché sur
    // ce bloc, cf. `classes_organisation_reassign_dialog.dart` — ClassroomBloc
    // online n'a plus aucune raison d'être lu ici).
    return BlocBuilder<ClassroomOfflineBloc, ClassroomOfflineState>(
      buildWhen: (previous, current) =>
          previous.levelUnassignedStatus != current.levelUnassignedStatus ||
          previous.levelUnassignedEnrollments !=
              current.levelUnassignedEnrollments ||
          previous.levelClassroomsStatus != current.levelClassroomsStatus ||
          previous.levelClassrooms != current.levelClassrooms ||
          previous.levelClassroomsErrorType !=
              current.levelClassroomsErrorType ||
          previous.levelRosters != current.levelRosters ||
          previous.assignStatus != current.assignStatus ||
          previous.assigningEnrollmentId != current.assigningEnrollmentId,
      builder: (context, offlineState) {
        if (!selectedLevel!.splitIntoClassrooms) {
          final List<EnrollmentSummary> unassigned =
              offlineState.levelUnassignedEnrollments;
          final maleCount = unassigned
              .where((enrollment) => enrollment.student.gender == Gender.male)
              .length;
          final femaleCount = unassigned
              .where((enrollment) => enrollment.student.gender == Gender.female)
              .length;

          return ClassesOrganisationPendingDistributionCard(
            isDistributing: isDistributing,
            overviewStatus: offlineState.levelUnassignedStatus,
            levelName: selectedLevel!.schoolLevelName,
            studentsToDistribute: unassigned.length,
            maleCount: maleCount,
            femaleCount: femaleCount,
            onDistributionRequested: onDistributionRequested,
          );
        }

        return ClassesOrganisationSplitResults(
          classroomsStatus: offlineState.levelClassroomsStatus,
          classroomsErrorType: offlineState.levelClassroomsErrorType,
          classrooms: offlineState.levelClassrooms,
          composedRosters: offlineState.levelRosters,
          unassignedEnrollments: offlineState.levelUnassignedEnrollments,
          isAssigning: offlineState.assignStatus == ClassroomStatus.loading,
          assigningEnrollmentId: offlineState.assigningEnrollmentId,
          errorMessage:
              ClassesOrganisationPageHelpers.mapClassroomErrorToMessage(
                l10n,
                offlineState.levelClassroomsErrorType,
              ),
          onTransferTap: onTransferTap,
          onRetry: () => _retryLocalClassrooms(context, selectedLevel!),
        );
      },
    );
  }

  void _retryLocalClassrooms(
    BuildContext context,
    ClassesOrganisationLevelOption level,
  ) {
    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;
    final academicYearId = academicYearContext?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }
    context.read<ClassroomOfflineBloc>().add(
      OfflineLevelClassroomsRequested(
        academicYearId: academicYearId,
        schoolLevelId: level.schoolLevelId,
      ),
    );
    context.read<ClassroomOfflineBloc>().add(
      OfflineLevelRostersRequested(
        academicYearId: academicYearId,
        schoolLevelId: level.schoolLevelId,
      ),
    );
    context.read<ClassroomOfflineBloc>().add(
      OfflineLevelUnassignedEnrollmentsRequested(
        academicYearId: academicYearId,
        schoolLevelId: level.schoolLevelId,
      ),
    );
  }
}
