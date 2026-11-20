import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/theme/course_domain_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/presentation/helpers/schedule_weekday_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// O1 — une séance en consultation (I4) : le cours, l'horaire, l'enseignant,
/// la salle, le volume, la classe, puis toutes les séances du cours dans la
/// semaine — toucher une puce ouvre cette séance sans fermer.
class SessionDetailSheet extends StatefulWidget {
  final ClassTimetableView view;
  final ClassTimetableCell cell;

  /// La date de chaque jour dans la semaine affichée, s'il y en a une.
  final Map<Weekday, DateTime> dates;

  /// La séance du créneau actuel (R11), pour « En cours ».
  final String? currentId;

  const SessionDetailSheet({
    super.key,
    required this.view,
    required this.cell,
    this.dates = const {},
    this.currentId,
  });

  @override
  State<SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends State<SessionDetailSheet> {
  late ClassTimetableCell _cell = widget.cell;

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = widget.view;
    final cell = _cell;
    final course = [
      for (final c in view.programme)
        if (c.coursId == cell.coursId) c,
    ].firstOrNull;
    final tone = CourseDomainTones.forDomain(
      course?.domainId,
      view.domainOrder,
    );
    final siblings =
        [
          for (final c in view.published)
            if (c.coursId == cell.coursId) c,
        ]..sort(
          (a, b) => a.day.index != b.day.index
              ? a.day.index.compareTo(b.day.index)
              : a.range.startMinute.compareTo(b.range.startMinute),
        );
    final date = widget.dates[cell.day];
    final dayLabel = ScheduleWeekdayLabels.long(l10n, cell.day);
    final planned = course?.weeklyHours;
    Widget fact(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [
                view.classroom.name,
                date == null
                    ? dayLabel
                    : '$dayLabel ${MaterialLocalizations.of(context).formatShortMonthDay(date)}',
              ].join(' · '),
              style: AppTypography.eyebrow.copyWith(color: tone.ink),
            ),
            Text(
              cell.subjectLabel ?? course?.branchLabel ?? '',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: tone.soft,
                borderRadius: AppRadius.brSm,
                border: Border(
                  left: BorderSide(color: tone.ink, width: AppSpacing.xs),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_clock(cell.range.startMinute)} – '
                    '${_clock(cell.range.endMinute)}',
                    style: AppTypography.titleSmall,
                  ),
                  Text(
                    [
                      l10n.classTimetableSessionLength(
                        cell.range.endMinute - cell.range.startMinute,
                      ),
                      ?course?.domainLabel,
                    ].join(' · '),
                    style: AppTypography.bodySmall,
                  ),
                  if (cell.id == widget.currentId)
                    Text(
                      l10n.classTimetableNow,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.terreCuite,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // R3 : un cours sans enseignant n'affiche aucun nom.
            if (cell.teacherLabel case final teacher?)
              fact(l10n.classTimetableSessionTeacher, teacher),
            fact(l10n.classTimetableSessionRoom, view.classroom.room ?? '—'),
            fact(
              l10n.classTimetableSessionVolume,
              planned == null
                  ? l10n.classTimetableHoursPlaced(siblings.length)
                  : l10n.classTimetableHoursOf(siblings.length, planned),
            ),
            fact(l10n.classTimetableSessionClass, view.classroom.name),
            Text(
              l10n.classTimetableSessionWeek,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final s in siblings)
                  EteeloActivatable(
                    onActivate: () => setState(() => _cell = s),
                    semanticLabel:
                        '${ScheduleWeekdayLabels.long(l10n, s.day)} '
                        '${_clock(s.range.startMinute)}',
                    builder: (context, highlight) => TouchTarget(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: s.id == cell.id
                              ? tone.ink
                              : highlight.any
                              ? tone.soft
                              : AppColors.surfaceRaised,
                          borderRadius: AppRadius.brSm,
                          border: Border.all(color: tone.ink),
                        ),
                        child: Text(
                          '${ScheduleWeekdayLabels.short(l10n, s.day)} '
                          '${_clock(s.range.startMinute)}',
                          style: AppTypography.labelMedium.copyWith(
                            color: s.id == cell.id
                                ? AppColors.textOnDark
                                : tone.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: SecondaryButton(
                label: l10n.classTimetableSessionClose,
                fullWidth: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
