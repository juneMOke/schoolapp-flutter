import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_agent_month.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le mois d'un agent, lundi → vendredi : une case par jour, dans la teinte
/// de son statut ; jours à venir estompés, non pointés en pointillé.
class StaffMonthCalendar extends StatelessWidget {
  final List<StaffCalendarDay?> days;

  const StaffMonthCalendar({super.key, required this.days});

  static const int _columns = 5;

  @override
  Widget build(BuildContext context) {
    final dates = MaterialLocalizations.of(context);
    // `narrowWeekdays` commence au dimanche ; on garde lundi → vendredi.
    final weekdays = dates.narrowWeekdays.sublist(1, 1 + _columns);
    final cells = [...days];
    while (cells.length % _columns != 0) {
      cells.add(null);
    }
    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var week = 0; week < cells.length; week += _columns)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                for (final cell in cells.sublist(week, week + _columns))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs / 2,
                      ),
                      child: cell == null
                          ? const SizedBox(
                              height: AppDimensions
                                  .staffAttendanceCalendarCellHeight,
                            )
                          : _DayCell(day: cell),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final StaffCalendarDay day;

  const _DayCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = StaffAttendanceTone.of(day.status);
    final marked = day.status != StaffAttendanceStatus.none;
    final date = StaffAttendanceLabels.longDay(
      MaterialLocalizations.of(context),
      day.day,
    );
    return Tooltip(
      message: day.upcoming
          ? date
          : '$date · ${StaffAttendanceLabels.status(l10n, day.status)}',
      child: Opacity(
        opacity: day.upcoming
            ? AppDimensions.staffAttendanceUpcomingOpacity
            : 1,
        child: Container(
          height: AppDimensions.staffAttendanceCalendarCellHeight,
          decoration: BoxDecoration(
            color: marked ? tone.soft : AppColors.surfaceRaised,
            borderRadius: AppRadius.brSm,
            border: Border.all(color: marked ? tone.border : AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${int.parse(day.day.substring(8))}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (!day.upcoming)
                Icon(
                  marked ? tone.icon : Icons.more_horiz,
                  size: AppSpacing.lg,
                  color: tone.ink,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
