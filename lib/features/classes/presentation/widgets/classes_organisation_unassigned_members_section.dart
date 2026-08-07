import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_member_tile.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// PARCOURS 8 — Section ambre « Élèves non répartis ».
///
/// Affichée au-dessus de la grille de classes quand des élèves restent sans
/// classe (nouveaux arrivants, transferts annulés…). Chaque élève propose un
/// bouton « Affecter » qui ouvre la popin de choix de classe. La section
/// disparaît dès qu'il n'y a plus de non-répartis (gérée par l'appelant).
///
/// Elle consomme des **inscriptions**, pas des membres de classe : un
/// non-réparti n'a par définition aucune ligne roster. Le [ClassroomMember]
/// construit ici est un véhicule d'AFFICHAGE pour la tuile partagée — jamais
/// une identité serveur ; celle qui compte (`enrollmentId`) voyage à part.
class ClassesOrganisationUnassignedMembersSection extends StatelessWidget {
  final int count;
  final List<EnrollmentSummary> enrollments;
  final bool isReassigning;

  /// Inscription dont l'affectation est en cours (tuile en attente).
  final String assigningEnrollmentId;

  final ValueChanged<ClassroomMemberReassignIntent> onTransferTap;

  const ClassesOrganisationUnassignedMembersSection({
    required this.count,
    required this.enrollments,
    required this.isReassigning,
    required this.assigningEnrollmentId,
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
                children: enrollments
                    .map(
                      (enrollment) => SizedBox(
                        width: tileWidth,
                        child: ClassesOrganisationMemberTile(
                          member: _toDisplayMember(enrollment),
                          classroomId: null,
                          enrollmentId: enrollment.enrollmentId,
                          isReassigning: isReassigning,
                          isCurrentReassigningMember:
                              enrollment.enrollmentId == assigningEnrollmentId,
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

  /// Véhicule d'affichage pour la tuile partagée. `id` porte l'`enrollmentId`
  /// (identité de la ligne à l'écran) ; `classroomId`/`academicYearId` sont
  /// vides **par nature** — l'élève n'est dans aucune classe. Ces champs ne
  /// sont jamais renvoyés au serveur : l'affectation ne transporte que
  /// l'`enrollmentId`, passé explicitement à la tuile.
  ClassroomMember _toDisplayMember(EnrollmentSummary enrollment) =>
      ClassroomMember(
        id: enrollment.enrollmentId,
        studentId: enrollment.student.id,
        classroomId: '',
        academicYearId: '',
        studentFirstName: enrollment.student.firstName,
        studentLastName: enrollment.student.lastName,
        studentMiddleName: enrollment.student.surname,
        studentGender: enrollment.student.gender == Gender.female
            ? ClassroomMemberGender.female
            : ClassroomMemberGender.male,
      );
}
