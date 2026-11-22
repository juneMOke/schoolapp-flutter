part of 'schedule_week_grid.dart';

/// En-tête sombre d'une grille de classe : horloge dans la gouttière, puis
/// par jour le libellé (court sous 760) et « 8 juin · 5 h » — « Aujourd'hui ·
/// 5 h » teinté d'or et souligné pour le jour courant, la période pour un jour
/// fermé.
class _ClassHeader extends StatelessWidget {
  final List<Weekday> days;
  final double columnWidth;
  final double gutter;
  final Weekday? today;
  final bool short;
  final Map<Weekday, DateTime>? dates;
  final Map<Weekday, int> hours;
  final Map<Weekday, ScheduleClosedDay> closedDays;
  final ScrollController frozen;
  final AppLocalizations l10n;

  const _ClassHeader({
    required this.days,
    required this.columnWidth,
    required this.gutter,
    required this.today,
    required this.short,
    required this.dates,
    required this.hours,
    required this.closedDays,
    required this.frozen,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final background = DashboardTones.entete(AppColors.terreCuite);
    final ml = MaterialLocalizations.of(context);
    String caption(Weekday day) {
      final closed = closedDays[day];
      if (closed != null) return closed.header;
      final date = dates?[day];
      return [
        if (day == today)
          l10n.scheduleTodaySemantics
        else if (date != null)
          ml.formatShortMonthDay(date),
        l10n.classTimetableDayHours(hours[day] ?? 0),
      ].join(' · ');
    }

    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: gutter),
          for (final day in days)
            SizedBox(
              width: columnWidth,
              child: Semantics(
                header: true,
                child: _ClassDayHead(
                  label: short
                      ? ScheduleWeekdayLabels.short(l10n, day)
                      : ScheduleWeekdayLabels.long(l10n, day),
                  caption: caption(day),
                  today: day == today,
                  closed: closedDays.containsKey(day),
                ),
              ),
            ),
        ],
      ),
    );
    return ColoredBox(
      color: background,
      child: Stack(
        children: [
          row,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: gutter,
            child: _Frozen(
              controller: frozen,
              child: ColoredBox(
                color: background,
                child: const Center(
                  child: Icon(
                    Icons.schedule_outlined,
                    size: AppSpacing.lg,
                    color: AppColors.timetableHeaderInk,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassDayHead extends StatelessWidget {
  final String label;
  final String caption;
  final bool today;
  final bool closed;

  const _ClassDayHead({
    required this.label,
    required this.caption,
    required this.today,
    required this.closed,
  });

  @override
  Widget build(BuildContext context) {
    final veil = closed
        ? AppColors.textOnDark.withValues(
            alpha: AppDimensions.timetableHeaderClosedVeil,
          )
        : today
        ? AppColors.orDoux.withValues(
            alpha: AppDimensions.timetableHeaderTodayVeil,
          )
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: veil,
        border: Border(
          left: BorderSide(
            color: AppColors.textOnDark.withValues(
              alpha: AppDimensions.timetableHeaderClosedVeil,
            ),
          ),
          bottom: today
              ? const BorderSide(
                  color: AppColors.orDoux,
                  width: AppDimensions.timetableGridTodayBar,
                )
              : BorderSide.none,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: today
                  ? AppColors.timetableHeaderInk
                  : AppColors.textOnDark.withValues(
                      alpha: AppDimensions.timetableHeaderCaptionOpacity,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gouttière d'une grille de classe : début en gras, fin atténuée.
class _ClassGutter extends StatelessWidget {
  final String start;
  final String end;

  const _ClassGutter({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final mono = AppTextStyles.codeMuted;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Les heures ne passent jamais à la ligne (texte ×1,3) : elles se
          // resserrent dans la gouttière.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              start,
              maxLines: 1,
              style: mono.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              end,
              maxLines: 1,
              style: mono.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
