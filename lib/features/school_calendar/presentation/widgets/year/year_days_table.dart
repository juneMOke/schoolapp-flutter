import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/year/year_day_square.dart';

/// Les initiales des jours, puis une case par jour, sept par rangée.
class YearDaysTable extends StatelessWidget {
  final List<String> labels;
  final int leading;
  final List<CalendarDay> days;
  final DateTime today;
  final bool compact;
  final double dayHeight;

  const YearDaysTable({
    super.key,
    required this.labels,
    required this.leading,
    required this.days,
    required this.today,
    required this.compact,
    required this.dayHeight,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget?>[
      for (var i = 0; i < leading; i++) null,
      for (final day in days)
        YearDaySquare(day: day, today: today, compact: compact),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    const gap = AppSpacing.xs / 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: gap),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.calendarCount.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var r = 0; r < cells.length; r += 7)
          Padding(
            padding: const EdgeInsets.only(top: gap),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++) ...[
                  if (c > 0) const SizedBox(width: gap),
                  Expanded(
                    child: SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(dayHeight),
                      child: cells[r + c],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class YearPeriodTag extends StatelessWidget {
  final String label;

  const YearPeriodTag(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xs / 4,
    ),
    decoration: const BoxDecoration(
      color: AppColors.bleuArdoiseSoft,
      borderRadius: BorderRadius.all(
        Radius.circular(AppDimensions.calendarSourceSquareRadius * 2),
      ),
    ),
    child: Text(
      label,
      style: AppTypography.calendarCount.copyWith(
        color: AppColors.bleuArdoise,
        fontSize: AppDimensions.calendarPeriodTagFont,
      ),
    ),
  );
}
