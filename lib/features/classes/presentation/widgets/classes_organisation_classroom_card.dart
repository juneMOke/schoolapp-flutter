import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_common_widgets.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_member_tile.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationClassroomCard extends StatelessWidget {
  final String levelName;
  final Classroom classroom;
  final List<ClassroomMember> members;
  final bool isReassigning;
  final String reassigningMemberId;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationClassroomCard({
    required this.levelName,
    required this.classroom,
    required this.members,
    required this.isReassigning,
    required this.reassigningMemberId,
    required this.onTransferTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final femaleCount = members
        .where((item) => item.studentGender == ClassroomMemberGender.female)
        .length;
    final maleCount = members
        .where((item) => item.studentGender == ClassroomMemberGender.male)
        .length;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.classesClassroomSurface,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$levelName - ${classroom.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
                ),
              ),
              ClassesOrganisationStatChip(
                icon: Icons.groups_2_outlined,
                label: '${members.length}',
                background: AppColors.classesChipTotalBg,
                foreground: AppColors.bleuProfond,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              _InlineGenderCount(icon: Icons.female_outlined, value: femaleCount),
              const SizedBox(width: AppDimensions.spacingS),
              _InlineGenderCount(icon: Icons.male_outlined, value: maleCount),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    l10n.classesOrganisationClassroomStats(
                      members.length,
                      femaleCount,
                      maleCount,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Expanded(
            child: members.isEmpty
                ? Center(
                    child: Text(
                      l10n.classesOrganisationNoMembers,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppDimensions.spacingXS),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ClassesOrganisationMemberTile(
                        member: member,
                        classroomId: classroom.id,
                        isReassigning: isReassigning,
                        isCurrentReassigningMember: member.id == reassigningMemberId,
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

class _InlineGenderCount extends StatelessWidget {
  final IconData icon;
  final int value;

  const _InlineGenderCount({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.detailMiniIconSize, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(
          '$value',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
