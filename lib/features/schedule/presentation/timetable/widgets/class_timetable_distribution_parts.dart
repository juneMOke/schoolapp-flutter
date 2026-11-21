import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/course_domain_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
export 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_domain_legend.dart';

/// L'en-tête d'une carte de l'emploi du temps : médaillon, titre, aide.
class DistributionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;

  const DistributionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.grid_view_rounded,
    this.tone = AppColors.bleuArdoise,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: AppDimensions.timetableTileIconLarge,
        height: AppDimensions.timetableTileIconLarge,
        decoration: BoxDecoration(color: tone, borderRadius: AppRadius.brMd),
        child: Icon(icon, size: AppSpacing.lg, color: AppColors.textOnDark),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.bleuProfond,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// La carte d'un cours : nom et « placé/prévu h », la barre d'un segment par
/// heure (rouge au-delà du prévu, pâle pour ce qui reste), l'enseignant.
class DistributionCard extends StatelessWidget {
  final TimetableCourse course;
  final CourseDomainTone tone;
  final int placed;
  final bool linked;
  final bool dimmed;
  final ValueChanged<bool>? onHover;

  const DistributionCard({
    super.key,
    required this.course,
    required this.tone,
    required this.placed,
    required this.linked,
    required this.dimmed,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planned = course.weeklyHours;
    final conform = planned == null || planned == placed;
    final hover = onHover;
    final segments = planned == null
        ? placed
        : (planned > placed ? planned : placed);
    final teacher = course.teacherLabel;
    return Opacity(
      opacity: dimmed ? AppDimensions.timetableDistributionDimOpacity : 1,
      child: Material(
        color: AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: BorderSide(color: linked ? tone.ink : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onHover: hover,
          onFocusChange: hover,
          // Au doigt, toucher une carte la repère ou la libère.
          onTap: hover == null ? null : () => hover(!linked),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: AppDimensions.timetableCardEdge,
                  color: tone.ink,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                course.branchLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              planned == null
                                  ? l10n.classTimetableHoursPlaced(placed)
                                  : l10n.classTimetableHoursOf(placed, planned),
                              maxLines: 1,
                              softWrap: false,
                              style: AppTextStyles.codeMuted.copyWith(
                                fontWeight: FontWeight.w700,
                                color: conform
                                    ? AppColors.vertSavane
                                    : AppColors.ambreInk,
                              ),
                            ),
                          ],
                        ),
                        if (segments > 0) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _HourBar(
                            segments: segments,
                            placed: placed,
                            planned: planned,
                            tone: tone,
                          ),
                        ],
                        if (teacher != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            teacher,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HourBar extends StatelessWidget {
  final int segments;
  final int placed;
  final int? planned;
  final CourseDomainTone tone;

  const _HourBar({
    required this.segments,
    required this.placed,
    required this.planned,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final rest = ColorMix.tint(
      AppColors.surfaceRaised,
      tone.ink,
      AppDimensions.timetableBarRestPercent,
    );
    final planned = this.planned;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var j = 0; j < segments; j++) ...[
            if (j > 0)
              const SizedBox(width: AppDimensions.timetableBarSegmentGap),
            Expanded(
              child: Container(
                height: AppDimensions.timetableBarHeight,
                decoration: BoxDecoration(
                  borderRadius: AppRadius.brPill,
                  color: j >= placed
                      ? rest
                      : planned != null && j >= planned
                      ? AppColors.error
                      : tone.ink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
