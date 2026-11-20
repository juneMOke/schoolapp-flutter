part of 'schedule_day_view.dart';

class _DaySelector extends StatelessWidget {
  final List<Weekday> days;
  final Map<Weekday, DateTime>? dates;
  final Weekday selectedDay;
  final Weekday? today;
  final ValueChanged<Weekday> onDaySelected;
  final AppLocalizations l10n;

  const _DaySelector({
    required this.days,
    required this.dates,
    required this.selectedDay,
    required this.today,
    required this.onDaySelected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Une seule rangée tant que chaque jour garde sa cible de 48 dp : six
        // jours tiennent ainsi sur un téléphone de 360 dp (l'ancien plancher
        // de 72 dp les faisait passer à la ligne, 4 + 2).
        final count = days.length;
        final roomy =
            (constraints.maxWidth - AppSpacing.sm * (count - 1)) / count >=
            AppDimensions.scheduleDayButtonRoomyWidth;
        final spacing = roomy ? AppSpacing.sm : AppSpacing.xs;
        final width = (constraints.maxWidth - spacing * (count - 1)) / count;
        final buttons = [
          for (final day in days)
            _DayButton(
              day: day,
              selected: day == selectedDay,
              isToday: day == today,
              label: ScheduleWeekdayLabels.short(l10n, day),
              date: dates?[day],
              todayLabel: l10n.scheduleTodaySemantics,
              onTap: () => onDaySelected(day),
            ),
        ];
        if (width < AppDimensions.minTouchTarget) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final b in buttons)
                SizedBox(width: AppDimensions.minTouchTarget, child: b),
            ],
          );
        }
        return Row(
          children: [
            for (final (i, b) in buttons.indexed) ...[
              if (i > 0) SizedBox(width: spacing),
              Expanded(child: b),
            ],
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
  final DateTime? date;
  final String todayLabel;
  final VoidCallback onTap;

  const _DayButton({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.label,
    required this.date,
    required this.todayLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.textOnDark : AppColors.textPrimary;
    final date = this.date;
    // La semaine datée (consultation) : le quantième sous le jour, précédé
    // d'un point aujourd'hui ; sans dates, le point seul.
    final second = [
      if (isToday) '●',
      if (date != null) '${date.day}',
    ].join(' ');
    final spoken = [
      label,
      if (date != null)
        MaterialLocalizations.of(context).formatMediumDate(date),
      if (isToday) todayLabel,
    ].join(' · ');
    return Semantics(
      button: true,
      selected: selected,
      onTap: onTap,
      excludeSemantics: true,
      label: spoken,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brMd,
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTypography.labelMedium.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    second,
                    maxLines: 1,
                    style: AppTypography.labelSmall.copyWith(
                      color: selected
                          ? AppColors.textOnDark.withValues(alpha: 0.75)
                          : AppColors.bleuArdoise,
                    ),
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
