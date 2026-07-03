import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';

/// Tuile d'un cours (branche) dans un accordéon de classe : médaillon + nom de
/// branche. Cliquable (chevron) quand le cours porte un identifiant exploitable
/// ([CourseRef.hasId]) ; sinon non interactive (contrat `mes-cours` legacy sans
/// id — cf. [CourseRef]).
class MyCoursesCourseTile extends StatelessWidget {
  final CourseRef course;
  final AcademicsClassVisual visual;
  final VoidCallback? onTap;

  const MyCoursesCourseTile({
    super.key,
    required this.course,
    required this.visual,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: visual.soft,
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 22,
              color: visual.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              course.label,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (interactive) ...[
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.bleuArdoise,
            ),
          ],
        ],
      ),
    );

    if (!interactive) return content;

    return Semantics(
      button: true,
      label: course.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}
