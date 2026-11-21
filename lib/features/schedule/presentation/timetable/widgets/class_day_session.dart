import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La séance d'un créneau de la journée : pavé du domaine (sauf sous 600),
/// cours, enseignant · domaine, « En cours » et l'œil qui ouvre O1.
class ClassDaySession extends StatelessWidget {
  final String start;
  final TimetableCell cell;
  final AcademicsClassVisual tone;
  final String? domain;
  final bool compact;
  final bool now;
  final VoidCallback? onOpen;

  const ClassDaySession({
    super.key,
    required this.start,
    required this.cell,
    required this.tone,
    required this.domain,
    required this.compact,
    required this.now,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final teacher = cell.classroomLabel.trim();
    final subtitle = [
      if (teacher.isNotEmpty) teacher,
      if (!compact) ?domain,
    ].join(' · ');
    final nowPill = now ? _NowPill(label: l10n.classTimetableNow) : null;
    return Semantics(
      button: onOpen != null,
      label: [
        start,
        cell.subjectLabel,
        if (subtitle.isNotEmpty) subtitle,
        if (now) l10n.classTimetableNow,
      ].join(' · '),
      excludeSemantics: true,
      onTap: onOpen,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: AppRadius.brMd,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(
                color: tone.accent.withValues(
                  alpha: AppDimensions.timetableToneBorderShare,
                ),
              ),
              gradient: LinearGradient(
                colors: [
                  ColorMix.mix(
                    AppColors.surfaceRaised,
                    tone.accent,
                    AppDimensions.timetableToneSurfaceShare,
                  ),
                  AppColors.surfaceRaised,
                ],
              ),
            ),
            child: Row(
              children: [
                if (!compact) ...[
                  Container(
                    width: AppDimensions.timetableDayIconTile,
                    height: AppDimensions.timetableDayIconTile,
                    decoration: BoxDecoration(
                      color: tone.accent,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: AppColors.textOnDark,
                      size: AppSpacing.lg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cell.subjectLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.bleuProfond,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (compact && nowPill != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        nowPill,
                      ],
                    ],
                  ),
                ),
                if (!compact && nowPill != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  nowPill,
                ],
                if (onOpen != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Tooltip(
                    message: l10n.classTimetableViewSession,
                    excludeFromSemantics: true,
                    child: Container(
                      width: AppDimensions.timetableTileIconLarge,
                      height: AppDimensions.timetableTileIconLarge,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: tone.accent.withValues(
                            alpha: AppDimensions.timetableToneBorderShare,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.visibility_outlined,
                        size: AppSpacing.lg,
                        color: tone.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NowPill extends StatelessWidget {
  final String label;

  const _NowPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppDimensions.timetablePillPaddingV,
    ),
    decoration: const BoxDecoration(
      color: AppColors.terreCuite,
      borderRadius: AppRadius.brPill,
    ),
    child: Text(
      label,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textOnDark,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
