import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/course_domain_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_metrics.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_course_reserve_parts.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_grid_marks.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// G — « Cours à placer » (EDT §4.6 G) : les cours du programme et ce qu'il
/// reste à placer. Sous 976 dp, un bandeau repliable (48 dp au moins, replié
/// par défaut) « {n} cours à placer · {p}/{v} h », sa barre et « Voir », qui
/// se déplie en grille de cartes (I13) ; au-delà, une colonne à côté de la
/// grille — en-tête, compteur, barre — dont les cours se glissent vers la
/// grille (I9), et où déposer une séance la retire (I11).
class TimetableCourseReserve extends StatefulWidget {
  final ClassTimetableView view;

  /// Le glisser-déposer (≥ 976) ; `null` : la réserve ne fait que lister.
  final ScheduleGridDrag? drag;

  /// Une séance déposée ici (I11).
  final ValueChanged<TimetableDragData>? onDropped;

  const TimetableCourseReserve({
    super.key,
    required this.view,
    this.drag,
    this.onDropped,
  });

  @override
  State<TimetableCourseReserve> createState() => _TimetableCourseReserveState();
}

class _TimetableCourseReserveState extends State<TimetableCourseReserve> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = widget.view;
    final drag = widget.drag;
    final volumes = PlacedHours.volumes(
      plannedByCours: {
        for (final c in view.programme) c.coursId: c.weeklyHours,
      },
      placedCoursIds: [for (final c in view.draft) c.coursId],
    );
    final placedBy = {for (final v in volumes) v.coursId: v.placed};
    final toPlace = volumes.where((v) => (v.remaining ?? 0) > 0).length;
    final (placed, planned) = PlacedHours.totals(volumes);
    final side = drag != null;
    final open = side || _open;
    final courses = [
      // R5 : un cours prévu à 0 h n'est pas à placer.
      for (final c in view.programme)
        if (c.weeklyHours != 0) c,
    ];
    final lines = [
      for (final course in courses)
        _draggable(
          drag,
          course,
          ReserveCourseLine(
            course: course,
            tone: CourseDomainTones.forDomain(
              course.domainId,
              view.domainOrder,
            ),
            placed: placedBy[course.coursId] ?? 0,
            handle: side,
          ),
        ),
    ];
    final hours = planned == null
        ? l10n.classTimetableHoursPlaced(placed)
        : l10n.classTimetableHoursOf(placed, planned);
    final head = ReserveHeader(
      title: side
          ? l10n.classTimetableReserveTitle
          : '${l10n.classTimetableReserveCount(toPlace)} · $hours',
      subtitle: side
          ? l10n.classTimetableReserveDragHint
          : l10n.classTimetableHelpDraft,
      counter: side ? hours : null,
      toggle: side
          ? null
          : (open
                ? l10n.classTimetableReserveHide
                : l10n.classTimetableReserveShow),
      open: open,
      placed: placed,
      planned: planned,
    );
    final panel = Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.timetableWarmBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (side)
            head
          else
            Semantics(
              button: true,
              expanded: open,
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: head,
              ),
            ),
          if (open)
            Padding(
              padding: const EdgeInsets.all(
                AppDimensions.timetableReservePadding,
              ),
              child: side
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final line in lines)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppDimensions.timetableReserveGap,
                            ),
                            child: line,
                          ),
                      ],
                    )
                  : _CardGrid(children: lines),
            ),
        ],
      ),
    );
    final dropped = widget.onDropped;
    if (drag == null || dropped == null) return panel;
    return DragTarget<TimetableDragData>(
      onWillAcceptWithDetails: (d) => d.data is SessionDragData,
      onAcceptWithDetails: (d) => dropped(d.data),
      builder: (context, candidates, _) => candidates.isEmpty
          ? panel
          : Stack(
              children: [
                panel,
                Positioned.fill(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.timetableWarmSurface,
                      borderRadius: AppRadius.brLg,
                      border: Border.all(color: AppColors.terreCuite),
                    ),
                    child: Text(
                      l10n.classTimetableReserveDropToRemove,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.terreCuite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _draggable(
    ScheduleGridDrag? drag,
    TimetableCourse course,
    Widget line,
  ) {
    if (drag == null) return line;
    final data = CourseDragData(course.coursId);
    final feedback = Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.timetableReserveWidth,
        ),
        child: line,
      ),
    );
    final ghost = Opacity(
      opacity: AppDimensions.timetableDragGhostOpacity,
      child: line,
    );
    return drag.longPress
        ? LongPressDraggable<TimetableDragData>(
            data: data,
            feedback: feedback,
            childWhenDragging: ghost,
            child: line,
          )
        : Draggable<TimetableDragData>(
            data: data,
            feedback: feedback,
            childWhenDragging: ghost,
            child: line,
          );
  }
}

/// La réserve dépliée sous 976 : une grille de cartes de 200 dp au moins.
class _CardGrid extends StatelessWidget {
  final List<Widget> children;

  const _CardGrid({required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = AppDimensions.timetableReserveGap;
      final columns =
          ((constraints.maxWidth + gap) /
                  (AppDimensions.timetableReserveCardMinWidth + gap))
              .floor()
              .clamp(1, 99);
      final width = ((constraints.maxWidth - gap * (columns - 1)) / columns)
          .floorToDouble();
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
