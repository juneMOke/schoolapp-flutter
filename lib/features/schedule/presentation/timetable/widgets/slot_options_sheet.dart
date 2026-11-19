import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_time_format.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_weekday_labels.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/draft_conflicts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le choix fait dans O2 : un cours à poser, ou libérer (`course == null`).
class SlotChoice {
  final TimetableCourse? course;

  const SlotChoice(this.course);
}

/// O2 — le créneau d'un brouillon (feuille du bas sous 760, modale au-delà) :
/// une option par cours du programme. Un cours en conflit est désactivé avec
/// sa raison (A5) ; sinon il dit ce qu'il reste à placer. « Libérer le
/// créneau » si le créneau est occupé.
class SlotOptionsSheet extends StatelessWidget {
  final ClassTimetableView view;
  final Weekday day;
  final TimeSlot slot;
  final String? currentCoursId;

  const SlotOptionsSheet({
    super.key,
    required this.view,
    required this.day,
    required this.slot,
    required this.currentCoursId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final placed = <String, int>{};
    for (final c in view.draft) {
      final id = c.coursId;
      if (id != null) placed[id] = (placed[id] ?? 0) + 1;
    }
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${view.classroom.name} · ${ScheduleWeekdayLabels.long(l10n, day)}',
              style: AppTypography.eyebrow.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              l10n.classTimetableSlotTitle(
                ScheduleTimeFormat.hourMinute(slot.startTime),
                ScheduleTimeFormat.hourMinute(slot.endTime),
              ),
              style: AppTypography.titleMedium,
            ),
            Text(l10n.classTimetableSlotHelp, style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.md),
            for (final course in view.programme)
              _Option(
                course: course,
                current: course.coursId == currentCoursId,
                blocking: course.coursId == currentCoursId
                    ? null
                    : DraftConflicts.blocking(
                        view,
                        course,
                        day,
                        slot,
                      )?.classroomLabel,
                placed: placed[course.coursId] ?? 0,
              ),
            if (currentCoursId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: l10n.classTimetableSlotFree,
                icon: Icons.remove_circle_outline,
                onPressed: () =>
                    Navigator.of(context).pop(const SlotChoice(null)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final TimetableCourse course;
  final bool current;
  final String? blocking;
  final int placed;

  const _Option({
    required this.course,
    required this.current,
    required this.blocking,
    required this.placed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planned = course.weeklyHours;
    final teacher = course.teacherLabel;
    final status = blocking != null
        ? l10n.classTimetableConflict
        : planned == null
        ? null
        : planned - placed > 0
        ? l10n.classTimetableRemaining(planned - placed)
        : planned == placed
        ? l10n.classTimetableComplete
        : l10n.classTimetableOver(placed - planned);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Opacity(
        opacity: blocking == null
            ? 1
            : AppDimensions.timetableBlockedOptionOpacity,
        child: EteeloActivatable(
          onActivate: blocking == null
              ? () => Navigator.of(context).pop(SlotChoice(course))
              : null,
          semanticLabel: course.branchLabel,
          builder: (context, highlight) => TouchTarget(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: highlight.any
                    ? AppColors.terreCuiteSoft
                    : AppColors.surfaceRaised,
                borderRadius: AppRadius.brSm,
                border: Border.all(
                  color: current ? AppColors.terreCuite : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: current ? AppColors.terreCuite : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.branchLabel,
                          style: AppTypography.bodyMedium,
                        ),
                        if (blocking != null)
                          Text(
                            l10n.classTimetableBusyIn(teacher ?? '', blocking!),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          )
                        else if (teacher != null)
                          Text(teacher, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  if (status != null)
                    Text(
                      status,
                      maxLines: 1,
                      softWrap: false,
                      style: AppTypography.labelMedium,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
