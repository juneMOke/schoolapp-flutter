import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_metrics.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_marks.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'identité et la synthèse d'une classe (EDT §4.6 B) : le nom et la salle,
/// le statut et la traçabilité, puis les pavés. Sous 600 reçus, « Séances » et
/// « Enseignants » passent en une ligne de texte. « Placé / prévu » n'apparaît
/// pas tant que les volumes sont inconnus (B2).
class ClassTimetableSummary extends StatelessWidget {
  final ClassTimetableView view;
  final List<ClassTimetableCell> cells;

  /// Consultation, cette semaine, un jour de semaine : le pavé « En cours »
  /// (R11, D9).
  final TimetableNow? now;

  /// Brouillon : les conflits professeur (R4, D8).
  final int? conflicts;

  const ClassTimetableSummary({
    super.key,
    required this.view,
    required this.cells,
    this.now,
    this.conflicts,
  });

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  EteeloKpiCardData _nowCard(AppLocalizations l10n, TimetableNow now) {
    final current = now.current;
    final next = now.next;
    final closedBy = now.closedBy;
    final String value;
    String? subline;
    if (closedBy != null) {
      value = l10n.classTimetableNoClassToday;
      subline = closedBy.title;
    } else if (current != null) {
      value = current.subjectLabel ?? '';
    } else {
      value = next == null
          ? l10n.classTimetableNoMoreToday
          : l10n.classTimetableNoClassNow;
    }
    if (closedBy == null && next != null) {
      subline = l10n.classTimetableNext(
        next.subjectLabel ?? '',
        _clock(next.range.startMinute),
      );
    }
    return EteeloKpiCardData(
      label: current == null
          ? l10n.classTimetableNow
          : l10n.classTimetableNowAt(_clock(current.range.startMinute)),
      valueText: value,
      subline: subline,
      accent: AppColors.terreCuite,
      accentSoft: AppColors.terreCuiteSoft,
      icon: Icons.play_circle_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final header = view.header;
    final placed = [
      for (final c in cells)
        if (!c.isEmpty) c,
    ];
    final teachers = {for (final c in placed) ?c.teacherId}.length;
    final volumes = PlacedHours.volumes(
      plannedByCours: {
        for (final c in view.programme) c.coursId: c.weeklyHours,
      },
      placedCoursIds: [for (final c in placed) c.coursId],
    );
    final (hours, planned) = PlacedHours.totals(volumes);
    final room = view.classroom.room;
    final publishedAt = header?.publishedAt;
    final trace = publishedAt == null
        ? l10n.classTimetableNeverPublished
        : l10n.classTimetablePublishedOn(
            MaterialLocalizations.of(context).formatMediumDate(publishedAt),
            header?.publishedBy?.name ?? '—',
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < AppBreakpoints.dataTableCardsMax;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  room == null
                      ? view.classroom.name
                      : '${view.classroom.name} · $room',
                  style: AppTypography.titleLarge,
                ),
                if (header?.isPublished ?? false)
                  StatusBadge.paid(
                    label: l10n.classTimetablePublished,
                    size: StatusBadgeSize.small,
                  ),
                if (view.hasDraft)
                  StatusBadge.draft(
                    label: l10n.classTimetableDraft,
                    size: StatusBadgeSize.small,
                  ),
              ],
            ),
            Text(trace, style: AppTypography.bodySmall),
            if (view.hasDraft)
              Text(
                l10n.classTimetableDraftOpen,
                style: AppTypography.bodySmall,
              ),
            if (narrow)
              Text(
                l10n.classTimetableTextCounts(placed.length, teachers),
                style: AppTypography.bodySmall,
              ),
            const SizedBox(height: AppSpacing.md),
            EteeloKpiBand(
              cards: [
                EteeloKpiCardData(
                  label: l10n.classTimetableKpiHours,
                  valueText: planned == null ? '$hours' : '$hours / $planned',
                  subline: planned == null
                      ? null
                      : planned - hours > 0
                      ? l10n.classTimetableKpiRemaining(planned - hours)
                      : l10n.classTimetableKpiComplete,
                  accent: AppColors.bleuArdoise,
                  accentSoft: AppColors.bleuArdoiseSoft,
                  icon: Icons.schedule_outlined,
                ),
                if (conflicts case final count?)
                  EteeloKpiCardData(
                    label: l10n.classTimetableConflictsKpi,
                    value: count,
                    subline: count > 0
                        ? l10n.classTimetableKpiConflictsOpen
                        : l10n.classTimetableKpiConflictsNone,
                    accent: count > 0 ? AppColors.error : AppColors.vertSavane,
                    accentSoft: count > 0
                        ? AppColors.feeStatusDueSoft
                        : AppColors.hrTeachersSoft,
                    icon: Icons.warning_amber_rounded,
                  ),
                if (now case final now?) _nowCard(l10n, now),
                if (!narrow) ...[
                  EteeloKpiCardData(
                    label: l10n.classTimetableKpiSessions,
                    value: placed.length,
                    accent: AppColors.terreCuite,
                    accentSoft: AppColors.terreCuiteSoft,
                    icon: Icons.grid_view_outlined,
                  ),
                  EteeloKpiCardData(
                    label: l10n.classTimetableKpiTeachers,
                    value: teachers,
                    accent: AppColors.hrTeachersAccent,
                    accentSoft: AppColors.hrTeachersSoft,
                    icon: Icons.person_outline,
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
