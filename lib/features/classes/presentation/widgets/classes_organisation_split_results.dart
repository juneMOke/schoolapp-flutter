import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationSplitResults extends StatelessWidget {
  final List<Classroom> classrooms;
  final List<ClassroomMembersGroup> membersByClassroom;
  final bool isLoading;
  final bool isReassigning;
  final String reassigningMemberId;
  final bool isFailure;
  final String? errorMessage;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationSplitResults({
    super.key,
    required this.classrooms,
    required this.membersByClassroom,
    required this.isLoading,
    required this.isReassigning,
    required this.reassigningMemberId,
    required this.isFailure,
    required this.errorMessage,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isFailure) {
      return _EmptyCard(
        title: l10n.classesOrganisationErrorUnknown,
        subtitle: errorMessage ?? l10n.classesOrganisationErrorUnknown,
      );
    }

    if (classrooms.isEmpty) {
      return _EmptyCard(
        title: l10n.noResultsFound,
        subtitle: l10n.classesOrganisationNoClassrooms,
      );
    }

    final membersMap = {
      for (final bucket in membersByClassroom) bucket.classroomId: bucket.members,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1200 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classrooms.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppDimensions.spacingM,
            mainAxisSpacing: AppDimensions.spacingM,
            childAspectRatio: AppDimensions.classesOrganisationGridRatio,
          ),
          itemBuilder: (context, index) {
            final classroom = classrooms[index];
            final members = membersMap[classroom.id] ?? const <ClassroomMember>[];
            return _ClassroomCard(
              classroom: classroom,
              members: members,
              isReassigning: isReassigning,
              reassigningMemberId: reassigningMemberId,
              onTransferTap: onTransferTap,
            );
          },
        );
      },
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  final Classroom classroom;
  final List<ClassroomMember> members;
  final bool isReassigning;
  final String reassigningMemberId;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const _ClassroomCard({
    required this.classroom,
    required this.members,
    required this.isReassigning,
    required this.reassigningMemberId,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.classesClassroomSurface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.classesOrganisationShadowBlur,
            offset: Offset(0, AppDimensions.spacingS),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  classroom.name,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatChip(
                icon: Icons.groups_2_outlined,
                label: '${classroom.totalCount}',
                background: AppColors.classesChipTotalBg,
                foreground: AppColors.classesChipTotalFg,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.classesOrganisationClassroomStats(
              classroom.totalCount,
              classroom.femaleCount,
              classroom.maleCount,
            ),
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Row(
            children: [
              _StatChip(
                icon: Icons.female_outlined,
                label: '${classroom.femaleCount}',
                background: AppColors.classesChipGirlsBg,
                foreground: AppColors.classesChipGirlsFg,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              _StatChip(
                icon: Icons.male_outlined,
                label: '${classroom.maleCount}',
                background: AppColors.classesChipBoysBg,
                foreground: AppColors.classesChipBoysFg,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Expanded(
            child: members.isEmpty
                ? Center(
                    child: Text(
                      l10n.noResultsFound,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppDimensions.spacingXS),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return _MemberTile(
                        member: member,
                        classroomId: classroom.id,
                        isReassigning: isReassigning,
                        isCurrentReassigningMember:
                            member.id == reassigningMemberId,
                        transferTooltip: l10n.classesOrganisationTransferAction,
                        transferInProgressTooltip:
                            l10n.classesOrganisationTransferInProgress,
                        onTransferTap: onTransferTap,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ClassroomMember member;
  final String classroomId;
  final bool isReassigning;
  final bool isCurrentReassigningMember;
  final String transferTooltip;
  final String transferInProgressTooltip;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const _MemberTile({
    required this.member,
    required this.classroomId,
    required this.isReassigning,
    required this.isCurrentReassigningMember,
    required this.transferTooltip,
    required this.transferInProgressTooltip,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = [
      member.studentLastName,
      member.studentMiddleName,
      member.studentFirstName,
    ].where((part) => (part ?? '').trim().isNotEmpty).join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.classesMemberSurface,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        border: Border.all(color: AppColors.border),
      ),
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: isReassigning && !isCurrentReassigningMember ? 0.65 : 1,
        child: Row(
        children: [
          Expanded(
            child: Text(
              fullName,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            _genderLabel(context, member.studentGender),
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          Tooltip(
            message:
                isCurrentReassigningMember ? transferInProgressTooltip : transferTooltip,
            child: Semantics(
              button: true,
              enabled: !isReassigning,
              child: IconButton(
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    AppDimensions.minTouchTarget,
                    AppDimensions.minTouchTarget,
                  ),
                  foregroundColor: AppColors.indigo,
                  disabledForegroundColor: AppColors.classesDisabledFg,
                  side: const BorderSide(color: AppColors.border),
                ),
                onPressed: isReassigning
                    ? null
                    : () {
                        onTransferTap(
                          ClassroomMemberReassignIntent(
                            classroomId: classroomId,
                            classroomMemberId: member.id,
                            studentDisplayName: fullName,
                          ),
                        );
                      },
                icon: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  switchInCurve: AppMotion.outCurve,
                  switchOutCurve: AppMotion.inCurve,
                  child: isCurrentReassigningMember
                      ? const SizedBox(
                          key: ValueKey('reassign-loading'),
                          width: AppDimensions.detailMiniIconSize,
                          height: AppDimensions.detailMiniIconSize,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.swap_horiz,
                          key: ValueKey('reassign-idle'),
                          color: AppColors.indigo,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _genderLabel(BuildContext context, ClassroomMemberGender gender) {
    final l10n = AppLocalizations.of(context)!;
    return switch (gender) {
      ClassroomMemberGender.male => l10n.genderMale,
      ClassroomMemberGender.female => l10n.genderFemale,
      ClassroomMemberGender.other => l10n.gender,
    };
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.classesSectionSurface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.classesOrganisationShadowBlur,
            offset: Offset(0, AppDimensions.spacingS),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.detailMiniIconSize, color: foreground),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
