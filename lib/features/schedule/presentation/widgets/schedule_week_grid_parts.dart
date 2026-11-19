part of 'schedule_week_grid.dart';

/// En-tête de la grille : gouttière vide + un en-tête par jour (libellé long,
/// jour courant teinté et marqué « auj. »).
class _GridHeader extends StatelessWidget {
  final List<Weekday> days;
  final double columnWidth;
  final double gutter;
  final Weekday? today;
  final AppLocalizations l10n;

  const _GridHeader({
    required this.days,
    required this.columnWidth,
    required this.gutter,
    required this.today,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(width: gutter),
          for (final day in days)
            SizedBox(
              width: columnWidth,
              child: Semantics(
                header: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: day == today ? AppColors.stateHover : null,
                    border: const Border(
                      left: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        ScheduleWeekdayLabels.long(l10n, day),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelMedium.copyWith(
                          color: day == today
                              ? AppColors.bleuArdoise
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (day == today) ...[
                        const SizedBox(height: 1),
                        Text(
                          l10n.scheduleToday,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.bleuArdoise,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Une ligne de créneau : gouttière heures + une case par jour visible.
class _SlotRow extends StatelessWidget {
  final TimetableRow row;
  final List<Weekday> days;
  final double columnWidth;
  final double gutter;
  final double minHeight;
  final Weekday? today;
  final ScheduleClassPalette palette;
  final AppLocalizations l10n;
  final void Function(TimetableCell cell)? onOpenCell;
  final void Function(Weekday day, TimeSlot slot)? onTapSlot;
  final Set<String> conflictSessionIds;

  const _SlotRow({
    required this.row,
    required this.days,
    required this.columnWidth,
    required this.gutter,
    required this.minHeight,
    required this.today,
    required this.palette,
    required this.l10n,
    required this.onOpenCell,
    required this.onTapSlot,
    required this.conflictSessionIds,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      // IntrinsicHeight borne la hauteur de la ligne (sinon `stretch` force une
      // hauteur infinie dans un parent scrollable verticalement).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: gutter,
              child: _TimeGutter(
                start: ScheduleTimeFormat.hourMinute(row.timeSlot.startTime),
                end: ScheduleTimeFormat.hourMinute(row.timeSlot.endTime),
              ),
            ),
            for (final day in days)
              SizedBox(
                width: columnWidth,
                child: _Cell(
                  cell: row.cellFor(day),
                  day: day,
                  timeSlot: row.timeSlot,
                  isToday: day == today,
                  minHeight: minHeight,
                  palette: palette,
                  l10n: l10n,
                  onOpenCell: onOpenCell,
                  onTapSlot: onTapSlot,
                  conflict: conflictSessionIds.contains(
                    row.cellFor(day)?.sessionId,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Gouttière des heures (début / fin en mono, fin atténuée).
class _TimeGutter extends StatelessWidget {
  final String start;
  final String end;

  const _TimeGutter({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final mono = AppTextStyles.codeMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(start, style: mono.copyWith(color: AppColors.textMuted)),
          Text(
            end,
            style: mono.copyWith(
              color: AppColors.textMuted.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
