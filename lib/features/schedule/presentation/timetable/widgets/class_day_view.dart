import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_time_format.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_day_parts.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La journée d'une classe (EDT §4.6 E) : le sélecteur « Lun. / 8 juin /
/// 5 h » (terre cuite pour le jour choisi), puis **tous** les créneaux du
/// jour — la séance (liseré et pavé du domaine, cours, enseignant · domaine,
/// « En cours », l'œil qui ouvre O1), « Pas de cours » pour un créneau vide,
/// la récréation intercalée. Un jour fermé remplace la liste par sa période.
/// Sous 600 reçus, la rangée se compacte (ni pavé d'icône, ni domaine).
class ClassDayView extends StatelessWidget {
  final WeeklyTimetable timetable;
  final ScheduleClassPalette palette;
  final Weekday? today;
  final Weekday selectedDay;
  final ValueChanged<Weekday> onDaySelected;
  final void Function(TimetableCell cell)? onOpenCell;
  final Map<Weekday, DateTime>? dates;

  /// coursId → nom du domaine (« Sciences »).
  final Map<String, String> domains;
  final ScheduleGridMarks marks;

  const ClassDayView({
    super.key,
    required this.timetable,
    required this.palette,
    required this.today,
    required this.selectedDay,
    required this.onDaySelected,
    required this.domains,
    this.onOpenCell,
    this.dates,
    this.marks = ScheduleGridMarks.none,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [...timetable.rows]
      ..sort((a, b) => TimeSlot.compareByTime(a.timeSlot, b.timeSlot));
    final hours = {
      for (final day in timetable.days)
        day: rows
            .where(
              (r) => !ScheduleWeekGrid.isBreakRow(r) && r.cellFor(day) != null,
            )
            .length,
    };
    final closed = marks.closedDays[selectedDay];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.dataTableCardsMax;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClassDaySelector(
              days: timetable.days,
              selectedDay: selectedDay,
              today: today,
              dates: dates,
              hours: hours,
              closedDays: marks.closedDays,
              onDaySelected: onDaySelected,
            ),
            const SizedBox(height: AppSpacing.md),
            if (closed != null)
              ClassClosedDayCard(closed: closed)
            else
              _DayList(
                rows: [
                  for (final r in rows)
                    (
                      r.timeSlot,
                      r.cellFor(selectedDay),
                      ScheduleWeekGrid.isBreakRow(r),
                    ),
                ],
                compact: compact,
                palette: palette,
                domains: domains,
                marks: marks,
                onOpenCell: onOpenCell,
              ),
          ],
        );
      },
    );
  }
}

class _DayList extends StatelessWidget {
  final List<(TimeSlot, TimetableCell?, bool)> rows;
  final bool compact;
  final ScheduleClassPalette palette;
  final Map<String, String> domains;
  final ScheduleGridMarks marks;
  final void Function(TimetableCell cell)? onOpenCell;

  const _DayList({
    required this.rows,
    required this.compact,
    required this.palette,
    required this.domains,
    required this.marks,
    required this.onOpenCell,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[];
    for (final (slot, cell, isBreak) in rows) {
      if (children.isNotEmpty && !isBreak) {
        children.add(const Divider(height: 1, color: AppColors.border));
      }
      if (isBreak) {
        children.add(
          ClassDayBreak(
            label:
                '${ScheduleTimeFormat.hourMinute(slot.startTime)} – '
                '${ScheduleTimeFormat.hourMinute(slot.endTime)} · '
                '${slot.label ?? l10n.scheduleBreak}',
          ),
        );
        continue;
      }
      final open = onOpenCell;
      children.add(
        ClassDayRow(
          slot: slot,
          cell: cell,
          compact: compact,
          tone: cell == null ? null : palette.visualForCell(cell),
          domain: cell == null ? null : domains[cell.coursId],
          now: cell != null && cell.sessionId == marks.currentSessionId,
          dimmed:
              cell != null && marks.emphasisOf(cell) == SessionEmphasis.dimmed,
          onOpen: cell == null || open == null ? null : () => open(cell),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.timetableWarmBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Un jour fermé (férié, vacances) : la liste laisse place à sa période,
/// hachurée aux couleurs du jour fermé.
class ClassClosedDayCard extends StatelessWidget {
  final ScheduleClosedDay closed;

  const ClassClosedDayCard({super.key, required this.closed});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(
      minHeight: AppDimensions.timetableGridRowMinHeight,
    ),
    decoration: BoxDecoration(
      color: AppColors.timetableClosedDay,
      borderRadius: AppRadius.brLg,
      border: Border.all(color: AppColors.timetableClosedHatch),
    ),
    clipBehavior: Clip.antiAlias,
    child: CustomPaint(
      painter: const HatchPainter(
        color: AppColors.timetableClosedHatch,
        gap: AppDimensions.timetableHatchGap,
        stroke: AppDimensions.timetableHatchStroke,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '${closed.header} · ${closed.period}',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}
