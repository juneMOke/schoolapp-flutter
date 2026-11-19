import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le fond d'un jour du mois : son numéro, le jour du jour entouré, un jour
/// hors du mois estompé, et « +n autres » quand des éléments ne tiennent pas.
///
/// Les bandes se posent par-dessus (`CalendarMonthBand`) ; la case reste la
/// cible d'un jour libre (CAL-I6) ou de sa sélection en compact (I7).
class CalendarMonthDayCell extends StatelessWidget {
  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final bool compact;
  final double headerHeight;
  final int hidden;
  final VoidCallback? onTap;

  const CalendarMonthDayCell({
    super.key,
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.compact,
    required this.headerHeight,
    required this.hidden,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = MaterialLocalizations.of(context).formatFullDate(day);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs / 2),
      child: EteeloActivatable(
        onActivate: onTap,
        semanticLabel: label,
        builder: (context, highlight) => Container(
          decoration: BoxDecoration(
            color: inMonth ? AppColors.surfaceRaised : AppColors.surfaceAlt,
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: isSelected || highlight.any
                  ? AppColors.terreCuite
                  : AppColors.border,
              width: isSelected ? AppDimensions.calendarTodayRing : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: headerHeight,
                child: Align(
                  alignment: compact ? Alignment.center : Alignment.centerLeft,
                  child: _DayNumber(
                    day: day.day,
                    isToday: isToday,
                    dim: !inMonth,
                  ),
                ),
              ),
              const Spacer(),
              if (hidden > 0)
                Text(
                  compact ? '+$hidden' : l10n.calendarMonthMore(hidden),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
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

  const _DayNumber({
    required this.day,
    required this.isToday,
    required this.dim,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      '$day',
      maxLines: 1,
      softWrap: false,
      style: AppTypography.labelMedium.copyWith(
        color: dim ? AppColors.textMutedAa : AppColors.textPrimary,
        fontWeight: isToday ? FontWeight.w700 : null,
      ),
    );
    if (!isToday) return text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brSm,
        border: Border.all(
          color: AppColors.terreCuite,
          width: AppDimensions.calendarTodayRing,
        ),
      ),
      child: text,
    );
  }
}
