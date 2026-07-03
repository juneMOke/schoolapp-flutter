import 'package:flutter/material.dart';
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

  const ScheduleDayRow({
    super.key,
    required this.slot,
    required this.cell,
    required this.visual,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final room = cell.room?.trim();
    final subtitle = room != null && room.isNotEmpty
        ? '${cell.classroomLabel} · $room'
        : cell.classroomLabel;
    final start = ScheduleTimeFormat.hourMinute(slot.startTime);
    final end = ScheduleTimeFormat.hourMinute(slot.endTime);

    return Semantics(
      button: onTap != null,
      onTap: onTap,
      // Un seul nœud sémantique : exclut les Text descendants (heure/branche/
      // classe/chevron) au profit d'un libellé composé — patron partagé
      // (cf. SegmentedTabFilter). onTap est reporté ici pour rester activable.
      excludeSemantics: true,
      label: '$start – $end · ${cell.subjectLabel} · $subtitle',
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
                _TimeColumn(slot: slot),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final TimeSlot slot;

  const _TimeColumn({required this.slot});

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
