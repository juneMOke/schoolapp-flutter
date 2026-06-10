import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_member_tile.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// PARCOURS 8 — Section ambre « Élèves non répartis ».
///
/// Affichée au-dessus de la grille de classes quand des élèves restent sans
/// classe (nouveaux arrivants, transferts annulés…). Chaque élève propose un
/// bouton « Affecter » qui ouvre la popin de choix de classe. La section
/// disparaît dès qu'il n'y a plus de non-répartis (gérée par l'appelant).
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.classesOrganisationUnassignedTitle,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.classesOrganisationUnassignedSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '$count',
                style: AppTextStyles.totalAmountLora.copyWith(
                  fontSize: 28,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          LayoutBuilder(
            builder: (context, constraints) {
              const tileMinWidth = AppDimensions.classesMemberTileMinWidth;
              const gap = AppDimensions.spacingS;
              final columns = (constraints.maxWidth / tileMinWidth)
                  .floor()
                  .clamp(1, 4);
              final tileWidth = columns <= 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - (columns - 1) * gap) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: members
                    .map(
                      (member) => SizedBox(
                        width: tileWidth,
                        child: ClassesOrganisationMemberTile(
                          member: member,
                          classroomId: null,
                          isReassigning: isReassigning,
                          isCurrentReassigningMember:
                              member.id == reassigningMemberId,
                          action: ClassesOrganisationMemberAction.assign,
                          onTransferTap: onTransferTap,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}
