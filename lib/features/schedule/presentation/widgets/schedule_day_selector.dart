part of 'schedule_day_view.dart';

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
