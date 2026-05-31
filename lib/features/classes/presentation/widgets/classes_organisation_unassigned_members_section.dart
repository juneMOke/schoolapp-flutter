import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_common_widgets.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_member_tile.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationUnassignedMembersSection extends StatelessWidget {
  final int count;
  final List<ClassroomMember> members;
  final bool isReassigning;
  final String reassigningMemberId;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationUnassignedMembersSection({
    required this.count,
    required this.members,
    required this.isReassigning,
    required this.reassigningMemberId,
    required this.onTransferTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ClassesOrganisationDashedContainer(
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.warning.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: AppDimensions.detailMiniIconSize,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Expanded(
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.classesOrganisationUnassignedTitle,
                        style: AppTextStyles.sectionTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.bleuArdoise,
                        ),
                      ),
                      TextSpan(
                        text: l10n.classesOrganisationUnassignedTitleSuffix,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.classesOrganisationUnassignedSummary(count),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ...members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
              child: ClassesOrganisationMemberTile(
                member: member,
                classroomId: null,
                isReassigning: isReassigning,
                isCurrentReassigningMember: member.id == reassigningMemberId,
                transferTooltip: l10n.classesOrganisationAssignAction,
                transferInProgressTooltip:
                    l10n.classesOrganisationTransferInProgress,
                onTransferTap: onTransferTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
