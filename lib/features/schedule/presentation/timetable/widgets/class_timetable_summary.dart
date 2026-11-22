import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/schedule/domain/services/timetable_metrics.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_marks.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/class_timetable_identity.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/timetable_kpi_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'identité et la synthèse d'une classe (EDT §4.6 B) : l'identité, puis
/// les pavés pleins — Heures placées, Séances, Enseignants, Conflits et, en
/// consultation un jour de semaine, « En cours » sur deux colonnes. Sous 600
/// reçus, « Séances » et « Enseignants » passent en une ligne de texte et
/// « En cours » prend toute la ligne.
class ClassTimetableSummary extends StatelessWidget {
  final ClassTimetableView view;
  final List<ClassTimetableCell> cells;

  /// Le brouillon est à l'écran (statut « Brouillon », traçabilité du
  /// brouillon) ; sinon la version publiée.
  final bool draft;

  /// Consultation, cette semaine, un jour de semaine : le pavé « En cours »
  /// (R11, D9).
  final TimetableNow? now;

  /// Les conflits professeur des cases montrées (R4, D8).
  final int conflicts;

  const ClassTimetableSummary({
    super.key,
    required this.view,
    required this.cells,
    this.draft = false,
    this.now,
    this.conflicts = 0,
  });

  static String _clock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  static Color _pave(Color sense) =>
      DashboardTones.pave(DashboardTones.paveAccentSur(sense));

  static EteeloKpiCardData _card({
    required String label,
    required String value,
    required Color sense,
    required IconData icon,
    String? subline,
  }) => EteeloKpiCardData(
    label: label,
    valueText: value,
    subline: subline,
    accent: sense,
    accentSoft: DashboardTones.teinte(sense, DashboardTones.forceDe(sense)),
    icon: icon,
    filledBackground: _pave(sense),
  );

  Widget _nowPave(AppLocalizations l10n, TimetableNow now) {
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
    if (closedBy == null) {
      subline = next == null
          ? (current == null ? null : l10n.classTimetableNoMoreToday)
          : l10n.classTimetableNext(
              next.subjectLabel ?? '',
              _clock(next.range.startMinute),
            );
    }
    return TimetableNowPave(
      label: current == null
          ? l10n.classTimetableNow
          : l10n.classTimetableNowAt(_clock(current.range.startMinute)),
      value: value,
      subline: subline,
      live: current != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    final complete = planned == null || hours == planned;
    final now = this.now;
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < AppBreakpoints.dataTableCardsMax;
        final cards = [
          _card(
            label: l10n.classTimetableKpiHours,
            value: planned == null ? '$hours' : '$hours / $planned',
            sense: complete ? DashboardSense.encaisse : DashboardSense.attente,
            icon: Icons.schedule_outlined,
            subline: planned == null
                ? null
                : planned > hours
                ? l10n.classTimetableKpiRemaining(planned - hours)
                : planned == hours
                ? l10n.classTimetableKpiComplete
                : l10n.classTimetableOver(hours - planned),
          ),
          if (!narrow) ...[
            _card(
              label: l10n.classTimetableKpiSessions,
              value: '${placed.length}',
              sense: DashboardSense.attendu,
              icon: Icons.calendar_today_outlined,
            ),
            _card(
              label: l10n.classTimetableKpiTeachers,
              value: '$teachers',
              sense: DashboardSense.attendu,
              icon: Icons.groups_outlined,
            ),
          ],
          _card(
            label: l10n.classTimetableConflictsKpi,
            value: '$conflicts',
            sense: conflicts > 0
                ? DashboardSense.manquant
                : DashboardSense.encaisse,
            icon: Icons.warning_amber_rounded,
            subline: conflicts > 0
                ? l10n.classTimetableKpiConflictsOpen
                : l10n.classTimetableKpiConflictsNone,
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClassTimetableIdentity(
              view: view,
              draft: draft,
              counts: narrow
                  ? l10n.classTimetableTextCounts(placed.length, teachers)
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TimetableKpiBand(
              cards: cards,
              wide: now == null ? null : _nowPave(l10n, now),
              wideFullRow: narrow,
            ),
          ],
        );
      },
    );
  }
}
