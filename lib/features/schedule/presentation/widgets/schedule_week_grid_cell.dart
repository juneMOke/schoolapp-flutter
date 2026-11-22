part of 'schedule_week_grid.dart';

/// Case de la grille : vide (créneau libre) ou puce de séance ; en brouillon,
/// une cible (toucher, et déposer à partir de 976 dp) ; un jour fermé est
/// hachuré, sa période nommée au premier créneau, ses séances barrées.
class _Cell extends StatelessWidget {
  final TimetableCell? cell;
  final Weekday day;
  final TimeSlot timeSlot;
  final bool isToday;
  final bool firstRow;
  final double minHeight;
  final double width;
  final ScheduleClassPalette palette;
  final AppLocalizations l10n;
  final void Function(TimetableCell cell)? onOpenCell;
  final void Function(Weekday day, TimeSlot slot)? onTapSlot;
  final ScheduleGridMarks marks;
  final ScheduleGridDrag? drag;

  /// L'habillage d'une classe (EDT §4.6 D) : jour d'or, créneau libre
  /// hachuré en consultation, « + » discret en brouillon.
  final bool classLook;

  const _Cell({
    required this.cell,
    required this.day,
    required this.timeSlot,
    required this.isToday,
    required this.firstRow,
    required this.minHeight,
    required this.width,
    required this.palette,
    required this.l10n,
    required this.onOpenCell,
    required this.onTapSlot,
    required this.marks,
    required this.drag,
    this.classLook = false,
  });

  ScheduleClosedDay? get _closed => marks.closedDays[day];

  String get _range =>
      '${ScheduleTimeFormat.hourMinute(timeSlot.startTime)} – '
      '${ScheduleTimeFormat.hourMinute(timeSlot.endTime)}';

  @override
  Widget build(BuildContext context) {
    final tapSlot = onTapSlot;
    final body = tapSlot != null
        ? _editable(context, tapSlot)
        : _readOnly(context);
    final closed = _closed;
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: closed != null
            ? AppColors.timetableClosedDay
            : isToday
            ? classLook
                  ? AppColors.orDoux.withValues(
                      alpha: AppDimensions.timetableTodayCellVeil,
                    )
                  : AppColors.stateHover
            : null,
        border: const Border(left: BorderSide(color: AppColors.border)),
      ),
      child: closed == null
          ? body
          : CustomPaint(
              painter: const HatchPainter(
                color: AppColors.timetableClosedHatch,
                gap: AppDimensions.timetableHatchGap,
                stroke: AppDimensions.timetableHatchStroke,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (firstRow)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xs,
                        AppSpacing.xs,
                        AppSpacing.xs,
                        0,
                      ),
                      child: Text(
                        closed.period,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  body,
                ],
              ),
            ),
    );
  }

  Widget _chip(TimetableCell current, {VoidCallback? onTap}) {
    final hover = marks.onHoverCours;
    return ScheduleSessionChip(
      cell: current,
      visual: palette.visualForCell(current),
      // Libellé lecteur d'écran : le jour n'est porté que par la colonne
      // (invisible au balayage), on le compose donc explicitement.
      semanticsLabel:
          '${ScheduleWeekdayLabels.long(l10n, day)} · $_range · '
          '${current.subjectLabel} · ${current.classroomLabel}',
      onTap: onTap,
      emphasis: marks.emphasisOf(current),
      struck: _closed != null,
      alert: marks.alerts[current.sessionId],
      badge: current.sessionId == marks.currentSessionId
          ? l10n.classTimetableNow
          : null,
      onHover: hover == null
          ? null
          : (inside) => hover(inside ? current.coursId : null),
      teacherIcon: classLook,
      badgeDot: classLook,
    );
  }

  Widget _readOnly(BuildContext context) {
    final current = cell;
    if (classLook && current == null && _closed == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xs),
        child: ClipRRect(
          borderRadius: AppRadius.brMd,
          child: CustomPaint(
            painter: HatchPainter(
              color: AppColors.timetableEmptyHatch,
              gap: AppDimensions.timetableEmptyHatchGap,
              stroke: AppDimensions.timetableEmptyHatchStroke,
            ),
            child: SizedBox.expand(),
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(classLook ? AppSpacing.xs : 5),
      child: current == null
          ? null
          : _chip(
              current,
              onTap: onOpenCell == null ? null : () => onOpenCell!(current),
            ),
    );
  }

  /// En brouillon : la case entière est une cible (48 dp et plus), libre en
  /// tirets « + », occupée avec sa puce ; à partir de 976 dp, la puce se
  /// glisse et la case reçoit un cours ou une séance (I9, I10).
  Widget _editable(
    BuildContext context,
    void Function(Weekday day, TimeSlot slot) tapSlot,
  ) {
    final current = cell;
    final drag = this.drag;
    Widget target(bool dropping) => EteeloActivatable(
      onActivate: () => tapSlot(day, timeSlot),
      semanticLabel:
          '${ScheduleWeekdayLabels.long(l10n, day)} · $_range'
          '${current == null ? '' : ' · ${current.subjectLabel}'}',
      builder: (context, highlight) => current == null || dropping
          ? classLook
                ? _QuietFreeSlot(
                    lit: highlight.any || dropping,
                    dropping: dropping,
                    label: l10n.classTimetableDrop,
                  )
                : EteeloDashedContainer(
                    backgroundColor: highlight.any || dropping
                        ? AppColors.terreCuiteSoft
                        : AppColors.surfaceRaised,
                    borderColor: AppColors.terreCuite,
                    borderRadius: AppRadius.brSm,
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Center(
                      child: dropping
                          ? Text(
                              l10n.classTimetableDrop,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.terreCuite,
                              ),
                            )
                          : const Icon(Icons.add, color: AppColors.terreCuite),
                    ),
                  )
          : IgnorePointer(child: _chip(current)),
    );
    final padded = Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: drag == null
          ? target(false)
          : DragTarget<TimetableDragData>(
              onWillAcceptWithDetails: (d) =>
                  drag.canDrop(d.data, day, timeSlot),
              onAcceptWithDetails: (d) => drag.onDrop(d.data, day, timeSlot),
              builder: (context, candidates, _) =>
                  target(candidates.isNotEmpty),
            ),
    );
    if (drag == null || current == null) return padded;
    return _draggable(drag, SessionDragData(current, day, timeSlot), padded);
  }

  Widget _draggable(
    ScheduleGridDrag drag,
    TimetableDragData data,
    Widget child,
  ) {
    final current = cell!;
    final feedback = SizedBox(
      width: width,
      child: Material(color: Colors.transparent, child: _chip(current)),
    );
    final ghost = Opacity(
      opacity: AppDimensions.timetableDragGhostOpacity,
      child: child,
    );
    return drag.longPress
        ? LongPressDraggable<TimetableDragData>(
            data: data,
            feedback: feedback,
            childWhenDragging: ghost,
            child: child,
          )
        : Draggable<TimetableDragData>(
            data: data,
            feedback: feedback,
            childWhenDragging: ghost,
            child: child,
          );
  }
}
