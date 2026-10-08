import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';

class ClassesOrganisationStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const ClassesOrganisationStatChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    super.key,
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
          // Flexible + ellipsis : la pastille s'adapte à un conteneur étroit
          // au lieu de déborder horizontalement.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.badge.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille de genre : libellé (lettre + effectif) teinté — bleu = Garçons,
/// terre-cuite = Filles. Partagée par la carte « non réparti » et la carte de
/// classe.
class ClassesOrganisationGenderPill extends StatelessWidget {
  final String label;
  final Color color;

  const ClassesOrganisationGenderPill({
    required this.label,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(label, style: AppTextStyles.badge.copyWith(color: color)),
    );
  }
}

/// Marqueur de genre : carré 22 px teinté — mars (Garçon) / venus (Fille).
class ClassesOrganisationGenderMarker extends StatelessWidget {
  final ClassroomMemberGender gender;

  const ClassesOrganisationGenderMarker({required this.gender, super.key});

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (gender) {
      ClassroomMemberGender.male => (Icons.male, AppColors.bleuArdoise),
      ClassroomMemberGender.female => (Icons.female, AppColors.terreCuite),
      ClassroomMemberGender.other => (
        Icons.transgender,
        AppColors.textSecondary,
      ),
    };

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 14, color: tint),
    );
  }
}

class ClassesOrganisationInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const ClassesOrganisationInfoChip({
    required this.icon,
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
