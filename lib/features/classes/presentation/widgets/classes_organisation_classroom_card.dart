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

/// PARCOURS 6 — Carte d'une classe constituée.
///
/// En-tête : pastille-lettre + « Classe {code} » + effectif/capacité + pastilles
/// G/F + barre de capacité teintée. Corps : les élèves (en colonnes lorsque la
/// carte est large), chacun avec son action de transfert.
class ClassesOrganisationClassroomCard extends StatelessWidget {
  final Classroom classroom;
  final List<ClassroomMember> members;
  final bool isReassigning;
  final String reassigningMemberId;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationClassroomCard({
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LetterMedallion(code: classroom.name),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.classesDistributionClassLabel(classroom.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.classesDistributionClassCapacity(
                        members.length,
                        classroom.capacity,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Wrap(
                spacing: AppDimensions.spacingXS,
                runSpacing: AppDimensions.spacingXS,
                children: [
                  ClassesOrganisationGenderPill(
                    label: l10n.classesOrganisationGenderBoysPill(maleCount),
                    color: AppColors.bleuArdoise,
                  ),
                  ClassesOrganisationGenderPill(
                    label: l10n.classesOrganisationGenderGirlsPill(femaleCount),
                    color: AppColors.terreCuite,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _CapacityBar(count: members.length, capacity: classroom.capacity),
          const SizedBox(height: AppDimensions.spacingM),
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingM,
              ),
              child: Text(
                l10n.classesOrganisationNoMembers,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            _MembersGrid(
              members: members,
              classroomId: classroom.id,
              isReassigning: isReassigning,
              reassigningMemberId: reassigningMemberId,
              onTransferTap: onTransferTap,
            ),
        ],
      ),
    );
  }
}

/// Pastille-lettre 44 px, gradient bleu profond → bleu ardoise.
class _LetterMedallion extends StatelessWidget {
  final String code;

  const _LetterMedallion({required this.code});

  @override
  Widget build(BuildContext context) {
    final letter = code.trim().isEmpty
        ? '?'
        : code.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Text(
        letter,
        style: AppTextStyles.sectionTitle.copyWith(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Barre de capacité teintée : bleu < 85 %, ambre ≥ 85 %, rouge si complet.
class _CapacityBar extends StatelessWidget {
  final int count;
  final int capacity;

  const _CapacityBar({required this.count, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = capacity <= 0 ? 0.0 : (count / capacity).clamp(0.0, 1.0);
    final isFull = capacity > 0 && count >= capacity;
    final Color color = isFull
        ? AppColors.danger
        : (ratio >= 0.85 ? AppColors.warning : AppColors.bleuArdoise);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.spacingXS),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: AppColors.surfaceAlt,
            color: color,
          ),
        ),
        if (isFull) ...[
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.classesDistributionCapacityFull,
            style: AppTextStyles.badge.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

/// Liste des élèves : en colonnes lorsque la carte est large (mode Liste),
/// en colonne unique lorsqu'elle est étroite (mode Grille).
class _MembersGrid extends StatelessWidget {
  final List<ClassroomMember> members;
  final String classroomId;
  final bool isReassigning;
  final String reassigningMemberId;
  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const _MembersGrid({
    required this.members,
    required this.classroomId,
    required this.isReassigning,
    required this.reassigningMemberId,
    required this.onTransferTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const tileMinWidth = AppDimensions.classesMemberTileMinWidth;
        const gap = AppDimensions.spacingS;
        final columns = (constraints.maxWidth / tileMinWidth).floor().clamp(
          1,
          4,
        );
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
                    classroomId: classroomId,
                    isReassigning: isReassigning,
                    isCurrentReassigningMember:
                        member.id == reassigningMemberId,
                    action: ClassesOrganisationMemberAction.transfer,
                    onTransferTap: onTransferTap,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
