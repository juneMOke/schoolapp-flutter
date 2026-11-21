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

/// Une ligne de la réserve : poignée (à côté de la grille), nom et
/// enseignant, puis « placé/prévu » et son statut — « reste n h » (ambre),
/// « complet » (vert, ligne estompée) ou « +n h » (rouge).
class ReserveCourseLine extends StatelessWidget {
  final TimetableCourse course;
  final CourseDomainTone tone;
  final int placed;
  final bool handle;

  const ReserveCourseLine({
    super.key,
    required this.course,
    required this.tone,
    required this.placed,
    required this.handle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planned = course.weeklyHours;
    final (status, color, icon) = switch (planned) {
      null => (
        l10n.classTimetableHoursPlaced(placed),
        AppColors.textSecondary,
        Icons.schedule_outlined,
      ),
      final p when p > placed => (
        l10n.classTimetableRemaining(p - placed),
        AppColors.ambreInk,
        Icons.schedule_outlined,
      ),
      final p when p == placed => (
        l10n.classTimetableComplete,
        AppColors.vertSavane,
        Icons.check_rounded,
      ),
      final p => (
        l10n.classTimetableOver(placed - p),
        AppColors.error,
        Icons.warning_amber_rounded,
      ),
    };
    final pending = planned == null || planned > placed;
    return Opacity(
      opacity: pending ? 1 : AppDimensions.timetableReserveDoneOpacity,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.timetableReserveLineMinHeight,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: pending
                ? ColorMix.tint(
                    AppColors.border,
                    tone.ink,
                    AppDimensions.timetableLegendBorderPercent,
                  )
                : AppColors.border,
          ),
          gradient: pending
              ? LinearGradient(
                  colors: [
                    ColorMix.mix(
                      AppColors.surfaceRaised,
                      tone.ink,
                      AppDimensions.timetableToneSurfaceShare,
                    ),
                    AppColors.surfaceRaised,
                  ],
                )
              : null,
          color: pending ? null : AppColors.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: AppDimensions.timetableCardEdge,
                color: tone.ink,
              ),
              if (handle)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xs),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: AppSpacing.lg,
                    color: AppColors.textMuted,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.branchLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (course.teacherLabel case final teacher?)
                        Text(
                          teacher,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (planned != null)
                      Text(
                        l10n.classTimetableHoursOf(placed, planned),
                        style: AppTextStyles.codeMuted.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: AppSpacing.md, color: color),
                        Text(
                          status,
                          maxLines: 1,
                          softWrap: false,
                          style: AppTypography.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
