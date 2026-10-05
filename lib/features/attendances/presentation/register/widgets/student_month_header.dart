import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/services/student_presence_month.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'en-tête de la fiche mensuelle : l'élève, « classe · niveau · Fille »,
/// et le badge « À surveiller » quand il l'est.
class StudentMonthHeader extends StatelessWidget {
  final StudentPresenceMonth sheet;
  final ClassPresenceClassroom classroom;

  const StudentMonthHeader({
    super.key,
    required this.sheet,
    required this.classroom,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = sheet.student;
    final level = classroom.levelName;
    final gender = switch (student.gender) {
      StudentGender.female => l10n.classPresenceGirl,
      StudentGender.male => l10n.classPresenceBoy,
      _ => null,
    };
    final watch = PresenceTone.of(PresenceStatus.absent);
    return Row(
      children: [
        PersonAvatar(
          firstName: student.firstName,
          lastName: student.lastName,
          personId: student.id,
          studentPhotoOf: student.id,
          size: AvatarSize.lg,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.classPresenceStudentSheetTitle.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
              Text(
                student.fullName,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                [classroom.name, ?level, ?gender].join(' · '),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (sheet.stats.toWatch)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: watch.soft,
              borderRadius: AppRadius.brPill,
              border: Border.all(color: watch.border),
            ),
            child: Text(
              l10n.classPresenceToWatch,
              style: AppTypography.labelMedium.copyWith(color: watch.ink),
            ),
          ),
      ],
    );
  }
}
