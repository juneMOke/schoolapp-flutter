import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/course_domain_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_metrics.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'identité et la synthèse d'une classe (EDT §4.6 B) : le nom et la salle,
/// le statut et la traçabilité, puis les pavés. Sous 600 reçus, « Séances » et
/// « Enseignants » passent en une ligne de texte. « Placé / prévu » n'apparaît
/// pas tant que les volumes sont inconnus (B2).
class ClassTimetableSummary extends StatelessWidget {
  final ClassTimetableView view;
  final List<ClassTimetableCell> cells;

  const ClassTimetableSummary({
    super.key,
    required this.view,
    required this.cells,
  });

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

/// La répartition hebdomadaire (EDT §4.6 F) : une ligne par cours, à la
/// teinte de son domaine, avec ses heures placées (et prévues, si connues).
class ClassTimetableDistribution extends StatelessWidget {
  final ClassTimetableView view;
  final List<ClassTimetableCell> cells;

  const ClassTimetableDistribution({
    super.key,
    required this.view,
    required this.cells,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final order = view.domainOrder;
    final counts = <String, int>{};
    for (final c in cells) {
      final id = c.coursId;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    return EteeloPanelCard(
      title: l10n.classTimetableDistribution,
      child: Column(
        children: [
          for (final course in view.programme)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: AppSpacing.xs,
                    height: AppSpacing.xl,
                    decoration: BoxDecoration(
                      color: CourseDomainTones.forDomain(
                        course.domainId,
                        order,
                      ).ink,
                      borderRadius: AppRadius.brSm,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.branchLabel,
                          style: AppTypography.bodyMedium,
                        ),
                        if (course.teacherLabel != null)
                          Text(
                            course.teacherLabel!,
                            style: AppTypography.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    course.weeklyHours == null
                        ? l10n.classTimetableHoursPlaced(
                            counts[course.coursId] ?? 0,
                          )
                        : l10n.classTimetableHoursOf(
                            counts[course.coursId] ?? 0,
                            course.weeklyHours!,
                          ),
                    maxLines: 1,
                    softWrap: false,
                    style: AppTypography.labelMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
