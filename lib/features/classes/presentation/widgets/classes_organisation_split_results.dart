import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_with_members.dart';
import 'package:school_app_flutter/features/classes/domain/entities/level_distribution_overview.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_classroom_card.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_split_states.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_unassigned_members_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Disposition des cartes de classe pilotée par le basculeur (PARCOURS 5).
enum _ClassroomLayout { grid, list }

class ClassesOrganisationSplitResults extends StatefulWidget {
  final ClassroomStatus overviewStatus;
  final ClassroomErrorType overviewErrorType;
  final LevelDistributionOverview? overview;
  final bool isReassigning;
  final String reassigningMemberId;
  final String? errorMessage;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;
  final VoidCallback onRetry;

  const ClassesOrganisationSplitResults({
    super.key,
    required this.overviewStatus,
    required this.overviewErrorType,
    required this.overview,
    required this.isReassigning,
    required this.reassigningMemberId,
    required this.errorMessage,
    required this.onTransferTap,
    required this.onRetry,
  });

  @override
  State<ClassesOrganisationSplitResults> createState() =>
      _ClassesOrganisationSplitResultsState();
}

class _ClassesOrganisationSplitResultsState
    extends State<ClassesOrganisationSplitResults> {
  _ClassroomLayout _layout = _ClassroomLayout.grid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.overviewStatus == ClassroomStatus.loading ||
        widget.overviewStatus == ClassroomStatus.initial) {
      return const ClassesOrganisationClassroomsSkeleton();
    }

    if (widget.overviewStatus == ClassroomStatus.failure) {
      return ClassesOrganisationSplitErrorState(
        errorType: widget.overviewErrorType,
        message: widget.errorMessage ?? l10n.classesOrganisationErrorUnknown,
        onRetry: widget.onRetry,
      );
    }

    final data = widget.overview;
    if (data == null || data.classrooms.isEmpty) {
      return const ClassesOrganisationSplitEmptyState();
    }

    final classrooms = data.classrooms;

    final distributedCount = classrooms.fold<int>(
      0,
      (acc, item) => acc + item.members.length,
    );
    final maleTotal = classrooms.fold<int>(
      0,
      (acc, item) => acc + _countGender(item, ClassroomMemberGender.male),
    );
    final femaleTotal = classrooms.fold<int>(
      0,
      (acc, item) => acc + _countGender(item, ClassroomMemberGender.female),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryBand(
          headcount: distributedCount,
          classroomCount: classrooms.length,
          maleCount: maleTotal,
          femaleCount: femaleTotal,
          layout: _layout,
          onLayoutChanged: (value) => setState(() => _layout = value),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        if (data.unassignedEnrollments.isNotEmpty) ...[
          ClassesOrganisationUnassignedMembersSection(
            count: data.unassignedEnrollments.length,
            members: data.unassignedEnrollments
                .map(
                  (item) => ClassroomMember(
                    id: item.enrollmentId,
                    studentId: item.student.id,
                    classroomId: '',
                    academicYearId: '',
                    studentFirstName: item.student.firstName,
                    studentLastName: item.student.lastName,
                    studentMiddleName: item.student.surname,
                    studentGender: item.student.gender.name == 'female'
                        ? ClassroomMemberGender.female
                        : ClassroomMemberGender.male,
                  ),
                )
                .toList(growable: false),
            isReassigning: widget.isReassigning,
            reassigningMemberId: widget.reassigningMemberId,
            onTransferTap: widget.onTransferTap,
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        _ClassroomsView(
          classrooms: classrooms,
          layout: _layout,
          isReassigning: widget.isReassigning,
          reassigningMemberId: widget.reassigningMemberId,
          onTransferTap: widget.onTransferTap,
        ),
      ],
    );
  }

  int _countGender(ClassroomWithMembers bucket, ClassroomMemberGender gender) {
    return bucket.members
        .where((member) => member.studentGender == gender)
        .length;
  }
}

/// Bandeau de synthèse : 4 KpiCard + basculeur Grille/Liste (PARCOURS 5).
class _SummaryBand extends StatelessWidget {
  final int headcount;
  final int classroomCount;
  final int maleCount;
  final int femaleCount;
  final _ClassroomLayout layout;
  final ValueChanged<_ClassroomLayout> onLayoutChanged;

  const _SummaryBand({
    required this.headcount,
    required this.classroomCount,
    required this.maleCount,
    required this.femaleCount,
    required this.layout,
    required this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final kpis = EteeloKpiBand(
      cards: [
        EteeloKpiCardData(
          label: l10n.classesDistributionKpiHeadcount,
          value: headcount,
          accent: AppColors.bleuProfond,
          accentSoft: AppColors.bleuProfond.withValues(alpha: 0.12),
          icon: Icons.groups_rounded,
        ),
        EteeloKpiCardData(
          label: l10n.classesDistributionKpiClasses,
          value: classroomCount,
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.bleuArdoise.withValues(alpha: 0.12),
          icon: Icons.meeting_room_rounded,
        ),
        EteeloKpiCardData(
          label: l10n.classesDistributionKpiBoys,
          value: maleCount,
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.bleuArdoise.withValues(alpha: 0.12),
          icon: Icons.boy_rounded,
        ),
        EteeloKpiCardData(
          label: l10n.classesDistributionKpiGirls,
          value: femaleCount,
          accent: AppColors.terreCuite,
          accentSoft: AppColors.terreCuite.withValues(alpha: 0.12),
          icon: Icons.girl_rounded,
        ),
      ],
    );

    final toggle = SegmentedTabFilter<_ClassroomLayout>(
      selected: layout,
      onSelected: onLayoutChanged,
      style: SegmentedTabFilterStyle.kpi,
      semanticsLabel: l10n.classesDistributionViewGrid,
      options: [
        SegmentedTabOption<_ClassroomLayout>(
          value: _ClassroomLayout.grid,
          label: l10n.classesDistributionViewGrid,
          icon: Icons.grid_view_rounded,
        ),
        SegmentedTabOption<_ClassroomLayout>(
          value: _ClassroomLayout.list,
          label: l10n.classesDistributionViewList,
          icon: Icons.view_list_rounded,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.classesSummaryBandRowMin) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: kpis),
              const SizedBox(width: AppDimensions.spacingM),
              toggle,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kpis,
            const SizedBox(height: AppDimensions.spacingM),
            toggle,
          ],
        );
      },
    );
  }
}

/// Disposition des cartes : grille (Wrap) ou liste (1 classe/ligne).
class _ClassroomsView extends StatelessWidget {
  final List<ClassroomWithMembers> classrooms;
  final _ClassroomLayout layout;
  final bool isReassigning;
  final String reassigningMemberId;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const _ClassroomsView({
    required this.classrooms,
    required this.layout,
    required this.isReassigning,
    required this.reassigningMemberId,
    required this.onTransferTap,
  });

  Widget _card(ClassroomWithMembers bucket) {
    return ClassesOrganisationClassroomCard(
      classroom: bucket.classroom,
      members: bucket.members,
      isReassigning: isReassigning,
      reassigningMemberId: reassigningMemberId,
      onTransferTap: onTransferTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (layout == _ClassroomLayout.list) {
      return Column(
        children: [
          for (var index = 0; index < classrooms.length; index++) ...[
            if (index > 0) const SizedBox(height: AppDimensions.spacingM),
            _card(classrooms[index]),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= AppBreakpoints.classesGridThreeColMin
            ? 3
            : width >= AppBreakpoints.classesGridTwoColMin
            ? 2
            : 1;
        const gap = AppDimensions.spacingM;
        final cardWidth = columns <= 1
            ? width
            : (width - (columns - 1) * gap) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: classrooms
              .map((bucket) => SizedBox(width: cardWidth, child: _card(bucket)))
              .toList(growable: false),
        );
      },
    );
  }
}
