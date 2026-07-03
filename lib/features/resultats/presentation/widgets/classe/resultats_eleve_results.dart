import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Résultats de la recherche « Par élève » quand plusieurs élèves correspondent
/// (spec machine à états : un seul résultat ouvre directement le focus). Chaque
/// ligne mène à la vue focus.
class ResultatsEleveResults extends StatelessWidget {
  final List<ClassroomMember> eleves;
  final String classroomLabel;
  final ValueChanged<ClassroomMember> onOpenMember;

  const ResultatsEleveResults({
    super.key,
    required this.eleves,
    required this.classroomLabel,
    required this.onOpenMember,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surfaceAlt,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              l10n.resultatsEleveResultsCount(eleves.length),
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final eleve in eleves)
            _MemberRow(
              eleve: eleve,
              classroomLabel: classroomLabel,
              onTap: () => onOpenMember(eleve),
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ClassroomMember eleve;
  final String classroomLabel;
  final VoidCallback onTap;

  const _MemberRow({
    required this.eleve,
    required this.classroomLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = [
      resultatsGenderLabel(l10n, eleve.studentGender),
      classroomLabel,
    ].where((p) => p.trim().isNotEmpty).join(' · ');

    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                StudentAvatar(
                  firstName: eleve.studentFirstName,
                  lastName: eleve.studentLastName,
                  studentId: eleve.studentId,
                  size: AvatarSize.md,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        resultatsShortName(
                          eleve.studentFirstName,
                          eleve.studentLastName,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.borderStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
