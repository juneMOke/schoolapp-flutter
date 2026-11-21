import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_weekday_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/year/year_days_table.dart';

/// La vue Année (🆕, spec Calendrier §4.3 et §4.6 D′, maquette
/// `CalYearView`) : les mois de l'année scolaire en mini-mois d'au moins
/// 230 dp (deux par ligne en [compact]). Une case par jour, pleine de la
/// couleur de l'élément le plus important (CAL-R15) ; un jour sans couleur
/// dans une période est souligné. L'en-tête porte le mois, l'année et les
/// périodes du mois ; le mois en cours est encadré de terre cuite. Toucher
/// un mois ouvre la vue Mois ([onMonthTap]).
///
/// Pourquoi neuf : aucune vue annuelle en jours dans le socle.
class SchoolCalendarYearGrid extends StatelessWidget {
  /// Les mois affichés, chacun par son premier jour.
  final List<DateTime> months;
  final List<CalendarElement> elements;
  final DateTime today;
  final bool compact;
  final ValueChanged<DateTime>? onMonthTap;

  const SchoolCalendarYearGrid({
    super.key,
    required this.months,
    required this.elements,
    required this.today,
    this.compact = false,
    this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    final gap = compact ? AppSpacing.sm : AppSpacing.md;
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit =
            ((constraints.maxWidth + gap) /
                    (AppDimensions.calendarYearMonthMinWidth + gap))
                .floor();
        final perRow = compact ? 2 : fit.clamp(1, months.length);
        final width = (constraints.maxWidth - (perRow - 1) * gap) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final month in months)
              SizedBox(
                width: width,
                child: _MiniMonth(
                  month: month,
                  elements: elements,
                  today: today,
                  compact: compact,
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
  final bool compact;
  final VoidCallback? onTap;

  const _MiniMonth({
    required this.month,
    required this.elements,
    required this.today,
    required this.compact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime.utc(month.year, month.month, 1);
    final last = DateTime.utc(month.year, month.month + 1, 0);
    final days = DaysBetween.compute(from: first, to: last, elements: elements);
    final current = today.year == month.year && today.month == month.month;
    final dates = MaterialLocalizations.of(context);
    final name = dates
        .formatMonthYear(first)
        .replaceAll(dates.formatYear(first), '')
        .trim();
    final periods = [
      for (final e in elements)
        if (e.nature == CalendarNature.period &&
            e.subPeriodOrder != null &&
            e.overlaps(first, last))
          e,
    ];
    final leading = first.weekday - DateTime.monday;
    final labels = CalendarWeekdayLabels.of(context, compact: true);
    final radius = compact ? AppRadius.brMd : AppRadius.brLg;
    final dayHeight = compact
        ? AppDimensions.calendarYearDayHeightCompact
        : AppDimensions.calendarYearDayHeight;
    return EteeloActivatable(
      onActivate: onTap,
      semanticLabel: dates.formatMonthYear(first),
      builder: (context, highlight) => Container(
        padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          gradient: current
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.center,
                  colors: [AppColors.calendarNowRow, AppColors.surfaceRaised],
                )
              : null,
          borderRadius: radius,
          border: Border.all(
            color: current || highlight.any
                ? AppColors.terreCuite
                : AppColors.border,
            width: current ? AppDimensions.calendarSelectedRing : 1,
          ),
          boxShadow: AppElevation.shadowKpi,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    '${name[0].toUpperCase()}${name.substring(1)}',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: current
                          ? AppColors.terreCuite
                          : AppColors.bleuProfond,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs + AppSpacing.xs / 2),
                Text(
                  dates.formatYear(first),
                  maxLines: 1,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                if (!compact)
                  for (final p in periods) ...[
                    const SizedBox(width: AppSpacing.xs / 2),
                    YearPeriodTag('P${p.subPeriodRank ?? p.subPeriodOrder}'),
                  ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            YearDaysTable(
              labels: labels,
              leading: leading,
              days: days,
              today: today,
              compact: compact,
              dayHeight: dayHeight,
            ),
          ],
        ),
      ),
    );
  }
}
