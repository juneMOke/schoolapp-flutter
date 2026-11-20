import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_grid_marks.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_time_format.dart';

/// Rangée chronologique de la vue Jour : heure (mono), liséré classe, branche +
/// classe · salle et chevron. Cliquable → ouvre le détail du cours (spec §5).
class ScheduleDayRow extends StatelessWidget {
  final TimeSlot slot;
  final TimetableCell cell;
  final AcademicsClassVisual visual;
  final VoidCallback? onTap;

  /// Un jour sans cours : la séance est barrée (EDT-R17).
  final bool struck;

  /// « En cours » (R11).
  final String? badge;

  /// Estompée (filtre de domaine) ou normale.
  final SessionEmphasis emphasis;

  /// Brouillon : conflit, hors programme, refus.
  final String? alert;

  const ScheduleDayRow({
    super.key,
    required this.slot,
    required this.cell,
    required this.visual,
    this.onTap,
    this.struck = false,
    this.badge,
    this.emphasis = SessionEmphasis.normal,
    this.alert,
  });

  @override
  Widget build(BuildContext context) {
    // Une séance sans enseignant ni salle n'a pas de sous-titre ; jamais de
    // séparateur en tête (« · Salle 12 »).
    final subtitle = [
      cell.classroomLabel.trim(),
      ?cell.room?.trim(),
    ].where((part) => part.isNotEmpty).join(' · ');
    final start = ScheduleTimeFormat.hourMinute(slot.startTime);
    final end = ScheduleTimeFormat.hourMinute(slot.endTime);

    final strike = struck
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : const TextStyle();
    final badge = this.badge;
    return Opacity(
      opacity: struck || emphasis == SessionEmphasis.dimmed
          ? AppDimensions.timetableDimmedOpacity
          : 1,
      child: Semantics(
        button: onTap != null,
        onTap: onTap,
        // Un seul nœud sémantique : exclut les Text descendants (heure/branche/
        // classe/chevron) au profit d'un libellé composé — patron partagé
        // (cf. SegmentedTabFilter). onTap est reporté ici pour rester activable.
        excludeSemantics: true,
        label: [
          '$start – $end · ${cell.subjectLabel}',
          if (subtitle.isNotEmpty) subtitle,
          ?badge,
          ?alert,
        ].join(' · '),
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.stateHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  ScheduleDayTimeColumn(slot: slot),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: visual.accent,
                      borderRadius: AppRadius.brPill,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cell.subjectLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium
                              .copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              )
                              .merge(strike),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)
                                .merge(strike),
                          ),
                        ],
                        if (alert case final alert?)
                          Text(
                            alert,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (badge != null)
                          Text(
                            badge,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.terreCuite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Un chevron promet une destination : il ne s'affiche que si
                  // la rangée est réellement ouvrable (même règle que
                  // `CoursEvalRow`).
                  if (onTap != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleDayTimeColumn extends StatelessWidget {
  final TimeSlot slot;

  const ScheduleDayTimeColumn({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final mono = AppTextStyles.codeMuted;
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ScheduleTimeFormat.hourMinute(slot.startTime),
            style: mono.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            ScheduleTimeFormat.hourMinute(slot.endTime),
            style: mono.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
