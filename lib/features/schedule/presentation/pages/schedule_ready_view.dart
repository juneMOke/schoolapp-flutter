import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable_cell.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekly_timetable.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_class_palette.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_time_format.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_day_view.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_legend.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_view_mode.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_grid.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_week_header.dart';

/// Contenu de l'état `ready` (spec §2/§3/§5/§6) : compteur de charge, puis la
/// grille hebdomadaire ou la vue Jour selon la bascule, puis la légende des
/// classes. N'est monté que lorsqu'il y a au moins une séance.
class ScheduleReadyView extends StatelessWidget {
  final WeeklyTimetable timetable;
  final ScheduleClassPalette palette;
  final Weekday? today;
  final ScheduleViewMode mode;
  final Weekday selectedDay;
  final ValueChanged<Weekday> onDaySelected;
  final void Function(TimetableCell cell)? onOpenCell;

  const ScheduleReadyView({
    super.key,
    required this.timetable,
    required this.palette,
    required this.today,
    required this.mode,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onOpenCell,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScheduleWeekHeader(
          sessionCount: ScheduleTimeFormat.sessionCount(timetable),
          hours: ScheduleTimeFormat.totalCourseHours(timetable),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (mode == ScheduleViewMode.week)
          ScheduleWeekGrid(
            timetable: timetable,
            palette: palette,
            today: today,
            onOpenCell: onOpenCell,
          )
        else
          ScheduleDayView(
            timetable: timetable,
            palette: palette,
            today: today,
            selectedDay: selectedDay,
            onDaySelected: onDaySelected,
            onOpenCell: onOpenCell,
          ),
        const SizedBox(height: AppSpacing.lg),
        ScheduleLegend(entries: palette.legendEntries),
      ],
    );
  }
}
