import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/course_domain_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_metrics.dart';
import 'package:school_app_flutter/features/schedule/presentation/widgets/schedule_grid_marks.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// G — « Cours à placer » (EDT §4.6 G) : les cours du programme et ce qu'il
/// reste à placer. Sous 976 dp, un bandeau replié « {n} cours à placer ·
/// {p}/{v} h » qui se déplie (I13) ; au-delà, à côté de la grille, une liste
/// dont les cours se glissent vers la grille (I9), et où déposer une séance
/// la retire (I11).
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
    final count = [
      l10n.classTimetableReserveCount(toPlace),
      if (planned != null) l10n.classTimetableHoursOf(placed, planned),
    ].join(' · ');
    final open = drag != null || _open;
    final courses = [
      // R5 : un cours prévu à 0 h n'est pas à placer.
      for (final c in view.programme)
        if (c.weeklyHours != 0) c,
    ];
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(count, style: AppTypography.bodyMedium)),
            if (drag == null)
              SecondaryButton(
                label: open
                    ? l10n.classTimetableReserveHide
                    : l10n.classTimetableReserveShow,
                fullWidth: false,
                onPressed: () => setState(() => _open = !_open),
              ),
          ],
        ),
        if (open) ...[
          Text(
            drag == null
                ? l10n.classTimetableHelpDraft
                : l10n.classTimetableReserveDragHint,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final course in courses)
            _draggable(
              drag,
              course,
              _CourseLine(
                course: course,
                tone: CourseDomainTones.forDomain(
                  course.domainId,
                  view.domainOrder,
                ),
                placed: placedBy[course.coursId] ?? 0,
              ),
            ),
        ],
      ],
    );
    final panel = EteeloPanelCard(
      title: l10n.classTimetableReserveTitle,
      child: body,
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
                      color: AppColors.terreCuiteSoft,
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

class _CourseLine extends StatelessWidget {
  final TimetableCourse course;
  final CourseDomainTone tone;
  final int placed;

  const _CourseLine({
    required this.course,
    required this.tone,
    required this.placed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final planned = course.weeklyHours;
    final (status, color) = switch (planned) {
      null => (l10n.classTimetableHoursPlaced(placed), AppColors.textSecondary),
      final p when p > placed => (
        l10n.classTimetableRemaining(p - placed),
        AppColors.ambreInk,
      ),
      final p when p == placed => (
        l10n.classTimetableComplete,
        AppColors.vertSavane,
      ),
      final p => (l10n.classTimetableOver(placed - p), AppColors.error),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      constraints: const BoxConstraints(
        minHeight: AppDimensions.timetableReserveLineMinHeight,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brSm,
        border: Border(
          left: BorderSide(color: tone.ink, width: AppSpacing.xs),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.branchLabel, style: AppTypography.bodyMedium),
                if (course.teacherLabel case final teacher?)
                  Text(teacher, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Text(
            status,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
