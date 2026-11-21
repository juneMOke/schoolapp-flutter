import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_weekday_labels.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_day_row.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/states/schedule_results_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

part 'schedule_day_selector.dart';

/// Vue Jour (spec §5) : sélecteur de jour (LUN→SAM, jour courant marqué d'un
/// point, et daté s'il reçoit [dates]) puis liste chronologique des séances du
/// jour sélectionné. Un jour sans cours affiche l'état vide dédié.
class ScheduleDayView extends StatelessWidget {
  final WeeklyTimetable timetable;
  final ScheduleClassPalette palette;
  final Weekday? today;
  final Weekday selectedDay;
  final ValueChanged<Weekday> onDaySelected;
  final void Function(TimetableCell cell)? onOpenCell;

  /// Le quantième de chaque jour (semaine datée) ; `null` : semaine type.
  final Map<Weekday, DateTime>? dates;

  /// Jour fermé, séance en cours, filtre de domaine (EDT §4.6 E).
  final ScheduleGridMarks marks;

  const ScheduleDayView({
    super.key,
    required this.timetable,
    required this.palette,
    required this.today,
    required this.selectedDay,
    required this.onDaySelected,
    this.onOpenCell,
    this.dates,
    this.marks = ScheduleGridMarks.none,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = _sessionsFor(selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DaySelector(
          days: timetable.days,
          dates: dates,
          selectedDay: selectedDay,
          today: today,
          onDaySelected: onDaySelected,
          l10n: l10n,
        ),
        const SizedBox(height: AppSpacing.gridGap),
        if (marks.closedDays[selectedDay] case final closed?) ...[
          Text(
            '${closed.header} · ${closed.period}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (rows.isEmpty)
          ScheduleResultsEmptyState(day: selectedDay)
        else
          _DayList(
            rows: rows,
            day: selectedDay,
            palette: palette,
            onOpenCell: onOpenCell,
            marks: marks,
          ),
      ],
    );
  }

  List<TimetableRow> _sessionsFor(Weekday day) {
    final rows = timetable.rows
        .where((row) => row.cellFor(day) != null)
        .toList();
    rows.sort((a, b) => TimeSlot.compareByTime(a.timeSlot, b.timeSlot));
    return rows;
  }
}

class _DayList extends StatelessWidget {
  final List<TimetableRow> rows;
  final Weekday day;
  final ScheduleClassPalette palette;
  final void Function(TimetableCell cell)? onOpenCell;
  final ScheduleGridMarks marks;

  const _DayList({
    required this.rows,
    required this.day,
    required this.palette,
    required this.onOpenCell,
    required this.marks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.border),
            _buildRow(context, rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, TimetableRow row) {
    final cell = row.cellFor(day)!;
    final open = onOpenCell;
    return ScheduleDayRow(
      slot: row.timeSlot,
      cell: cell,
      visual: palette.visualForCell(cell),
      onTap: open == null ? null : () => open(cell),
      alert: marks.alerts[cell.sessionId],
      struck: marks.closedDays.containsKey(day),
      emphasis: marks.emphasisOf(cell),
      badge: cell.sessionId == marks.currentSessionId
          ? AppLocalizations.of(context)!.classTimetableNow
          : null,
    );
  }
}
