import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_row.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_weekday_labels.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_day_row.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/states/schedule_results_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Vue Jour (spec §5) : sélecteur de jour (LUN→SAM, jour courant marqué d'un
/// point) puis liste chronologique des séances du jour sélectionné. Un jour sans
/// cours affiche l'état vide dédié.
class ScheduleDayView extends StatelessWidget {
  final WeeklyTimetable timetable;
  final ScheduleClassPalette palette;
  final Weekday? today;
  final Weekday selectedDay;
  final ValueChanged<Weekday> onDaySelected;
  final void Function(TimetableCell cell)? onOpenCell;

  const ScheduleDayView({
    super.key,
    required this.timetable,
    required this.palette,
    required this.today,
    required this.selectedDay,
    required this.onDaySelected,
    this.onOpenCell,
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
          selectedDay: selectedDay,
          today: today,
          onDaySelected: onDaySelected,
          l10n: l10n,
        ),
        const SizedBox(height: AppSpacing.gridGap),
        if (rows.isEmpty)
          ScheduleResultsEmptyState(day: selectedDay)
        else
          _DayList(
            rows: rows,
            day: selectedDay,
            palette: palette,
            onOpenCell: onOpenCell,
          ),
      ],
    );
  }

  List<TimetableRow> _sessionsFor(Weekday day) {
    final rows = timetable.rows
        .where((row) => row.cellFor(day) != null)
        .toList();
    rows.sort((a, b) => a.timeSlot.order.compareTo(b.timeSlot.order));
    return rows;
  }
}

class _DayList extends StatelessWidget {
  final List<TimetableRow> rows;
  final Weekday day;
  final ScheduleClassPalette palette;
  final void Function(TimetableCell cell)? onOpenCell;

  const _DayList({
    required this.rows,
    required this.day,
    required this.palette,
    required this.onOpenCell,
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
            _buildRow(rows[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(TimetableRow row) {
    final cell = row.cellFor(day)!;
    return ScheduleDayRow(
      slot: row.timeSlot,
      cell: cell,
      visual: palette.visualForClassroom(cell.classroomId),
      onTap: onOpenCell == null ? null : () => onOpenCell!(cell),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<Weekday> days;
  final Weekday selectedDay;
  final Weekday? today;
  final ValueChanged<Weekday> onDaySelected;
  final AppLocalizations l10n;

  const _DaySelector({
    required this.days,
    required this.selectedDay,
    required this.today,
    required this.onDaySelected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.sm;
        final count = days.length;
        final raw = (constraints.maxWidth - spacing * (count - 1)) / count;
        final buttonWidth = raw >= 72 ? raw : 72.0;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final day in days)
              SizedBox(
                width: buttonWidth,
                child: _DayButton(
                  day: day,
                  selected: day == selectedDay,
                  isToday: day == today,
                  label: ScheduleWeekdayLabels.short(l10n, day),
                  todayLabel: l10n.scheduleTodaySemantics,
                  onTap: () => onDaySelected(day),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DayButton extends StatelessWidget {
  final Weekday day;
  final bool selected;
  final bool isToday;
  final String label;
  final String todayLabel;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.label,
    required this.todayLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.textOnDark : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      onTap: onTap,
      excludeSemantics: true,
      label: isToday ? '$label · $todayLabel' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.bleuArdoise : AppColors.surfaceRaised,
              borderRadius: AppRadius.brMd,
              border: Border.all(
                color: selected ? AppColors.bleuArdoise : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isToday ? '●' : '',
                  style: AppTypography.labelSmall.copyWith(
                    color: selected
                        ? AppColors.textOnDark.withValues(alpha: 0.75)
                        : AppColors.bleuArdoise,
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
