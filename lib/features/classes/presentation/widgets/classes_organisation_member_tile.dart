import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';

class ClassesOrganisationMemberTile extends StatelessWidget {
  final ClassroomMember member;
  final String? classroomId;
  final bool isReassigning;
  final bool isCurrentReassigningMember;
  final String transferTooltip;
  final String transferInProgressTooltip;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationMemberTile({
    required this.member,
    required this.classroomId,
    required this.isReassigning,
    required this.isCurrentReassigningMember,
    required this.transferTooltip,
    required this.transferInProgressTooltip,
    required this.onTransferTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mainName = [
      member.studentLastName,
      member.studentFirstName,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    final subName = (member.studentMiddleName ?? '').trim();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.classesMemberSurface,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        border: Border.all(color: AppColors.border),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isReassigning && !isCurrentReassigningMember ? 0.65 : 1,
        child: Row(
          children: [
            StudentAvatar(
              firstName: member.studentFirstName,
              lastName: member.studentLastName,
              size: 32,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
                  ),
                  if (subName.isNotEmpty) const SizedBox(height: AppDimensions.spacingXS),
                  if (subName.isNotEmpty)
                    Text(
                      subName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Icon(
              _genderIcon(member.studentGender),
              size: AppDimensions.detailMiniIconSize,
              color: AppColors.textSecondary,
            ),
            Tooltip(
              message: isCurrentReassigningMember
                  ? transferInProgressTooltip
                  : transferTooltip,
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
                              studentDisplayName: [mainName, subName]
                                  .where((part) => part.trim().isNotEmpty)
                                  .join(' '),
                            ),
                          );
                        },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isCurrentReassigningMember
                        ? const SizedBox(
                            key: ValueKey('reassign-loading'),
                            width: AppDimensions.detailMiniIconSize,
                            height: AppDimensions.detailMiniIconSize,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.swap_horiz_rounded,
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

  IconData _genderIcon(ClassroomMemberGender gender) {
    return switch (gender) {
      ClassroomMemberGender.male => Icons.male,
      ClassroomMemberGender.female => Icons.female,
      ClassroomMemberGender.other => Icons.transgender,
    };
  }
}
