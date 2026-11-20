import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_weekday_labels.dart';

/// La vue Année (🆕, spec Calendrier §4.3 et §4.6 D′) : les mois de l'année
/// scolaire en mini-mois. Une case par jour, à la couleur de l'élément le plus
/// important (CAL-R15) ; le mois en cours est encadré de terre cuite. Toucher
/// un mois ouvre la vue Mois ([onMonthTap]).
///
/// Pourquoi neuf : aucune vue annuelle en jours dans le socle.
class SchoolCalendarYearGrid extends StatelessWidget {
  /// Les mois affichés, chacun par son premier jour.
  final List<DateTime> months;
  final List<CalendarElement> elements;
  final DateTime today;
  final ValueChanged<DateTime>? onMonthTap;

  const SchoolCalendarYearGrid({
    super.key,
    required this.months,
    required this.elements,
    required this.today,
    this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow =
            (constraints.maxWidth /
                    (AppDimensions.calendarYearMonthMinWidth + AppSpacing.md))
                .floor()
                .clamp(2, 4);
        final width =
            (constraints.maxWidth - (perRow - 1) * AppSpacing.md) / perRow;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final month in months)
              SizedBox(
                width: width,
                child: _MiniMonth(
                  month: month,
                  elements: elements,
                  today: today,
                  onTap: onMonthTap == null ? null : () => onMonthTap!(month),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final DateTime month;
  final List<CalendarElement> elements;
  final DateTime today;
  final VoidCallback? onTap;

  const _MiniMonth({
    required this.month,
    required this.elements,
    required this.today,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime.utc(month.year, month.month, 1);
    final last = DateTime.utc(month.year, month.month + 1, 0);
    final days = DaysBetween.compute(from: first, to: last, elements: elements);
    final current = today.year == month.year && today.month == month.month;
    final title = MaterialLocalizations.of(context).formatMonthYear(first);
    final leading = first.weekday - DateTime.monday;
    final labels = CalendarWeekdayLabels.of(context, compact: true);
    return EteeloActivatable(
      onActivate: onTap,
      semanticLabel: title,
      builder: (context, highlight) => Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: current || highlight.any
                ? AppColors.terreCuite
                : AppColors.border,
            width: current ? AppDimensions.calendarTodayRing : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.xs / 2,
              crossAxisSpacing: AppSpacing.xs / 2,
              children: [
                for (final label in labels)
                  Center(
                    child: Text(
                      label,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMutedAa,
                      ),
                    ),
                  ),
                for (var i = 0; i < leading; i++) const SizedBox.shrink(),
                for (final day in days) _DaySquare(day: day, today: today),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySquare extends StatelessWidget {
  final CalendarDay day;
  final DateTime today;

  const _DaySquare({required this.day, required this.today});

  @override
  Widget build(BuildContext context) {
    final nature = day.topNature;
    final tone = nature?.tone;
    final underlined = day.elements.any((e) => e.subPeriodOrder != null);
    final isToday = CalendarDays.of(today) == day.date;
    return Container(
      decoration: BoxDecoration(
        color: tone?.soft ?? Colors.transparent,
        borderRadius: AppRadius.brSm,
        border: isToday
            ? Border.all(
                color: AppColors.terreCuite,
                width: AppDimensions.calendarTodayRing,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.date.day}',
        style: AppTypography.labelSmall.copyWith(
          color: tone?.ink ?? AppColors.textSecondary,
          decoration: underlined ? TextDecoration.underline : null,
          decorationColor: AppColors.bleuArdoise,
        ),
      ),
    );
  }
}
