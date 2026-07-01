import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_chip.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/my_courses_course_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Accordéon d'une classe : en-tête (médaillon niveau/section, nom, effectif,
/// chip « N cours », chevron) + corps déplié (grille de tuiles de cours).
/// Le liséré gauche (5 dp) reprend la couleur de la classe.
class MyCoursesClassAccordion extends StatelessWidget {
  final CourseSummary group;
  final AcademicsClassVisual visual;
  final bool expanded;
  final VoidCallback onToggle;

  /// Ouvre le détail d'un cours (`null` → tuiles non interactives).
  final void Function(CoursDetailArgs args)? onOpenCourse;

  const MyCoursesClassAccordion({
    super.key,
    required this.group,
    required this.visual,
    required this.expanded,
    required this.onToggle,
    this.onOpenCourse,
  });

  @override
  Widget build(BuildContext context) {
    // Le liséré gauche est rendu par un fond accent révélé sur 5 dp via un
    // padding (pas de Row `stretch`, qui exigerait une hauteur bornée et
    // planterait dans une vue défilante).
    return ClipRRect(
      borderRadius: AppRadius.brCard,
      child: ColoredBox(
        color: visual.accent,
        child: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceRaised,
              border: Border(
                top: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AccordionHeader(
                  group: group,
                  visual: visual,
                  expanded: expanded,
                  onToggle: onToggle,
                ),
                AnimatedSize(
                  duration: AppMotion.layout,
                  curve: AppMotion.outCurve,
                  alignment: Alignment.topCenter,
                  child: expanded
                      ? _AccordionBody(
                          group: group,
                          visual: visual,
                          onOpenCourse: onOpenCourse,
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccordionHeader extends StatelessWidget {
  final CourseSummary group;
  final AcademicsClassVisual visual;
  final bool expanded;
  final VoidCallback onToggle;

  const _AccordionHeader({
    required this.group,
    required this.visual,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final classroom = group.classroom;
    final identity = ClassroomIdentity.fromName(classroom.name);

    return Semantics(
      button: true,
      expanded: expanded,
      label: classroom.name,
      child: InkWell(
        onTap: onToggle,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [visual.soft, AppColors.surfaceRaised],
              stops: const [0, 0.72],
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              _GradeMedallion(identity: identity, visual: visual),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            l10n.myCoursesStudentCount(classroom.totalCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              EteeloChip(
                icon: Icons.auto_stories_outlined,
                label: l10n.myCoursesClassCourseCount(group.courses.length),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: AppMotion.standard,
                curve: AppMotion.outCurve,
                child: const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.bleuArdoise,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeMedallion extends StatelessWidget {
  final ClassroomIdentity identity;
  final AcademicsClassVisual visual;

  const _GradeMedallion({required this.identity, required this.visual});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: visual.accent,
        borderRadius: AppRadius.brMd,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            identity.level,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textOnDark,
              height: 1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (identity.section != null)
            Text(
              identity.section!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textOnDark.withValues(alpha: 0.85),
                height: 1.3,
                letterSpacing: 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _AccordionBody extends StatelessWidget {
  final CourseSummary group;
  final AcademicsClassVisual visual;
  final void Function(CoursDetailArgs args)? onOpenCourse;

  const _AccordionBody({
    required this.group,
    required this.visual,
    this.onOpenCourse,
  });

  static const double _minTileWidth = 240;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpacing.md;
          final width = constraints.maxWidth;
          final rawColumns = (width + gap) ~/ (_minTileWidth + gap);
          final columns = rawColumns < 1 ? 1 : rawColumns;
          final tileWidth = (width - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final course in group.courses)
                SizedBox(
                  width: tileWidth,
                  child: MyCoursesCourseTile(
                    course: course,
                    visual: visual,
                    onTap: (onOpenCourse != null && course.hasId)
                        ? () => onOpenCourse!(
                            CoursDetailArgs(
                              coursId: course.id,
                              brancheNom: course.label,
                              classroomName: group.classroom.name,
                              visual: visual,
                            ),
                          )
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
