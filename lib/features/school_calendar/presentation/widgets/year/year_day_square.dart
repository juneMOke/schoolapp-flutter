import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';

/// Un jour de la vue Année (maquette `CalYearView`) : plein de la teinte de
/// l'élément le plus important (CAL-R15), estompé s'il vient de l'école ;
/// sans couleur mais dans une période, un filet ardoise dessous ; aujourd'hui
/// cerclé de terre cuite ; le week-end sans couleur en gris.
class YearDaySquare extends StatelessWidget {
  final CalendarDay day;
  final DateTime today;
  final bool compact;

  const YearDaySquare({
    super.key,
    required this.day,
    required this.today,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final nature = day.topNature;
    final tone = nature?.tone;
    final top = nature == null
        ? null
        : day.elements.firstWhere((e) => e.nature == nature);
    final inPeriod = day.elements.any(
      (e) => e.nature == CalendarNature.period && e.subPeriodOrder != null,
    );
    final isToday = CalendarDays.of(today) == day.date;
    final weekend = CalendarDays.isWeekend(day.date);
    final ink = tone == null
        ? weekend
              ? AppColors.textMuted
              : AppColors.textPrimary
        : nature == CalendarNature.assessment
        ? tone.ink
        : AppColors.textOnDark;
    final underline = tone == null && inPeriod;
    // Un filet sous un seul bord ne se dessine pas avec un rayon.
    final radius = underline
        ? null
        : BorderRadius.circular(
            compact
                ? AppDimensions.calendarYearDayRadiusCompact
                : AppDimensions.calendarYearDayRadius,
          );
    final square = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone?.tone,
        borderRadius: radius,
        border: underline
            ? Border(
                bottom: BorderSide(
                  color: AppColors.bleuArdoise.withValues(
                    alpha: AppDimensions.calendarYearPeriodUnderlineOpacity,
                  ),
                  width: AppDimensions.calendarYearPeriodUnderline,
                ),
              )
            : null,
        boxShadow: isToday
            ? const [
                BoxShadow(
                  color: AppColors.terreCuite,
                  spreadRadius: AppDimensions.calendarSelectedRing,
                ),
              ]
            : null,
      ),
      child: Text(
        '${day.date.day}',
        maxLines: 1,
        softWrap: false,
        style: AppTypography.calendarCount.copyWith(
          color: ink,
          fontSize: compact
              ? AppDimensions.calendarPeriodTagFont
              : AppTypography.calendarCount.fontSize,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
    if (top == null) return square;
    return Tooltip(
      message: top.title,
      child: Opacity(
        opacity: top.isNational ? 1 : AppDimensions.calendarInternalOpacity,
        child: square,
      ),
    );
  }
}
