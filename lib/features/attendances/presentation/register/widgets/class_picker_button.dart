import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bouton de classe de l'en-tête : médaillon, nom de la classe, « niveau ·
/// N élèves », et le chevron qui ouvre le sélecteur. Sans classe : « Choisir
/// la classe ».
class ClassPickerButton extends StatelessWidget {
  final ClassPresenceClassroom? classroom;
  final VoidCallback? onTap;

  const ClassPickerButton({super.key, required this.classroom, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final classroom = this.classroom;
    final level = classroom?.levelName;
    return Material(
      color: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.classPickerButtonHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppDimensions.classPickerMedallionSize,
                  height: AppDimensions.classPickerMedallionSize,
                  decoration: const BoxDecoration(
                    color: AppColors.bleuArdoise,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.groups_outlined,
                    color: AppColors.textOnDark,
                    size: AppSpacing.xl,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      classroom?.name ?? l10n.classPresencePickClass,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (classroom != null)
                      Text(
                        level == null
                            ? l10n.classPresenceStudentsShort(
                                classroom.studentCount,
                              )
                            : l10n.classPresenceClassMeta(
                                level,
                                classroom.studentCount,
                              ),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.expand_more, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
