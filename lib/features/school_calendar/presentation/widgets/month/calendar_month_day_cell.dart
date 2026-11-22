import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/month/calendar_month_painters.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le fond d'un jour du mois (maquette `CalMonthView`) : cases jointives
/// séparées d'un filet, le week-end teinté, un jour hors du mois hachuré,
/// aujourd'hui en pastille terre cuite avec « Aujourd'hui », le 1er avec son
/// mois, le jour touché encadré d'ardoise, et « +n autres » quand des
/// éléments ne tiennent pas.
///
/// Les bandes se posent par-dessus (`CalendarMonthBand`) ; la case reste la
/// cible d'un jour libre (CAL-I6) ou de sa sélection en compact (I7).
class CalendarMonthDayCell extends StatelessWidget {
  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final bool compact;
  final bool narrow;
  final bool first;
  final double headerHeight;

  /// La marge au-dessus du numéro.
  final double top;
  final int hidden;
  final VoidCallback? onTap;

  const CalendarMonthDayCell({
    super.key,
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.compact,
    required this.narrow,
    required this.first,
    required this.headerHeight,
    required this.top,
    required this.hidden,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = MaterialLocalizations.of(context).formatFullDate(day);
    final weekend = day.weekday >= DateTime.saturday;
    final background = isSelected
        ? AppColors.calendarSelectedSurface
        : !inMonth
        ? null
        : isToday
        ? AppColors.calendarTodaySurface
        : weekend
        ? AppColors.calendarWeekendSurface
        : AppColors.surfaceRaised;
    final shortMonth = MaterialLocalizations.of(
      context,
    ).formatShortMonthDay(day).replaceAll(RegExp(r'\d'), '').trim();
    return EteeloActivatable(
      onActivate: onTap,
      semanticLabel: label,
      builder: (context, highlight) => DecoratedBox(
        decoration: BoxDecoration(
          color: highlight.any && !isSelected
              ? AppColors.calendarHover
              : background,
          border: first
              ? null
              : const Border(
                  left: BorderSide(color: AppColors.calendarMonthGridLine),
                ),
        ),
        child: CustomPaint(
          painter: inMonth || isSelected ? null : const CalendarHatchPainter(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? AppSpacing.xs / 2 : AppSpacing.sm,
              top,
              compact ? AppSpacing.xs / 2 : AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Row(
                    mainAxisAlignment: compact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      _DayNumber(
                        day: day.day,
                        isToday: isToday,
                        dim: !inMonth,
                        weekend: weekend,
                      ),
                      if (isToday && !narrow) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            l10n.schoolCalendarToday,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: AppTypography.calendarCount.copyWith(
                              color: AppColors.terreCuite,
                            ),
                          ),
                        ),
                      ] else if (day.day == 1 && !narrow) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            shortMonth,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                if (hidden > 0)
                  Text(
                    compact
                        ? l10n.calendarMonthMoreCompact(hidden)
                        : l10n.calendarMonthMore(hidden),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.bleuArdoise,
                      fontWeight: FontWeight.w600,
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

class _DayNumber extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool dim;
  final bool weekend;

  const _DayNumber({
    required this.day,
    required this.isToday,
    required this.dim,
    required this.weekend,
  });

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(
      minWidth: AppDimensions.calendarTodayDot,
      minHeight: AppDimensions.calendarTodayDot,
    ),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    alignment: Alignment.center,
    decoration: isToday
        ? const BoxDecoration(
            color: AppColors.terreCuite,
            borderRadius: AppRadius.brPill,
          )
        : null,
    child: Text(
      '$day',
      maxLines: 1,
      softWrap: false,
      style: AppTypography.labelMedium.copyWith(
        fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
        color: isToday
            ? AppColors.textOnDark
            : dim
            ? AppColors.textMutedAa
            : weekend
            ? AppColors.textSecondary
            : AppColors.textPrimary,
      ),
    ),
  );
}
