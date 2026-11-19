part of 'schedule_week_grid.dart';

/// Case de la grille : vide (créneau libre) ou puce de séance cliquable.
class _Cell extends StatelessWidget {
  final TimetableCell? cell;
  final Weekday day;
  final TimeSlot timeSlot;
  final bool isToday;
  final double minHeight;
  final ScheduleClassPalette palette;
  final AppLocalizations l10n;
  final void Function(TimetableCell cell)? onOpenCell;
  final void Function(Weekday day, TimeSlot slot)? onTapSlot;
  final bool conflict;

  const _Cell({
    required this.cell,
    required this.day,
    required this.timeSlot,
    required this.isToday,
    required this.minHeight,
    required this.palette,
    required this.l10n,
    required this.onOpenCell,
    required this.onTapSlot,
    required this.conflict,
  });

  @override
  Widget build(BuildContext context) {
    final current = cell;
    final tapSlot = onTapSlot;
    if (tapSlot != null) return _editable(context, current, tapSlot);
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isToday ? AppColors.stateHover : null,
        border: const Border(left: BorderSide(color: AppColors.border)),
      ),
      child: current == null
          ? null
          : ScheduleSessionChip(
              cell: current,
              visual: palette.visualForCell(current),
              // Libellé lecteur d'écran : le jour n'est porté que par la colonne
              // (invisible au balayage), on le compose donc explicitement.
              semanticsLabel:
                  '${ScheduleWeekdayLabels.long(l10n, day)} · '
                  '${ScheduleTimeFormat.hourMinute(timeSlot.startTime)} – '
                  '${ScheduleTimeFormat.hourMinute(timeSlot.endTime)} · '
                  '${current.subjectLabel} · ${current.classroomLabel}',
              onTap: onOpenCell == null ? null : () => onOpenCell!(current),
            ),
    );
  }

  /// En brouillon : la case entière est une cible (48 dp et plus), libre en
  /// tirets « + », occupée avec sa puce — en rouge si elle est en conflit.
  Widget _editable(
    BuildContext context,
    TimetableCell? current,
    void Function(Weekday day, TimeSlot slot) tapSlot,
  ) {
    final range =
        '${ScheduleTimeFormat.hourMinute(timeSlot.startTime)} – '
        '${ScheduleTimeFormat.hourMinute(timeSlot.endTime)}';
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: EteeloActivatable(
        onActivate: () => tapSlot(day, timeSlot),
        semanticLabel:
            '${ScheduleWeekdayLabels.long(l10n, day)} · $range'
            '${current == null ? '' : ' · ${current.subjectLabel}'}',
        builder: (context, highlight) => current == null
            ? EteeloDashedContainer(
                backgroundColor: highlight.any
                    ? AppColors.terreCuiteSoft
                    : AppColors.surfaceRaised,
                borderColor: AppColors.terreCuite,
                borderRadius: AppRadius.brSm,
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: const Center(
                  child: Icon(Icons.add, color: AppColors.terreCuite),
                ),
              )
            : DecoratedBox(
                decoration: conflict
                    ? BoxDecoration(
                        color: AppColors.feeStatusDueSoft,
                        borderRadius: AppRadius.brSm,
                        border: Border.all(color: AppColors.error),
                      )
                    : const BoxDecoration(),
                child: IgnorePointer(
                  child: ScheduleSessionChip(
                    cell: current,
                    visual: palette.visualForCell(current),
                  ),
                ),
              ),
      ),
    );
  }
}
