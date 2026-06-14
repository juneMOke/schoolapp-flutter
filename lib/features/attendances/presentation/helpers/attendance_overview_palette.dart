import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/donut_chart_section.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/absence_reason_stats.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/attendance_overview/attendance_weekday.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Couleurs et libellés d'affichage du tableau de bord des présences.
class AttendanceOverviewPalette {
  const AttendanceOverviewPalette._();

  /// Couleur de la pastille d'un cycle (Maternelle / Primaire / Secondaire).
  /// Tolérante aux libellés ou codes backend (correspondance par inclusion).
  static Color cycleColor(String cycle) {
    final value = cycle.toLowerCase();
    if (value.contains('matern')) return AppColors.info; // #2E6E8E
    if (value.contains('prim')) return AppColors.bleuArdoise; // #1B4D6B
    if (value.contains('second') || value.contains('eb')) {
      return AppColors.terreCuite; // #B85C2C
    }
    return AppColors.bleuArdoise;
  }

  /// Palette des segments « autres motifs » du donut, assignée par RANG (ordre
  /// décroissant, cf. spec) : bleu · or · info · terre-cuite · gris. Le segment
  /// « Non justifié » est toujours rouge (hors palette).
  static const List<Color> _reasonPalette = <Color>[
    AppColors.bleuArdoise,
    AppColors.absenceReasonGold,
    AppColors.info,
    AppColors.terreCuite,
    AppColors.textMuted,
  ];

  /// Libellé court d'un jour de la semaine.
  static String weekdayLabel(
    AttendanceWeekday weekday,
    AppLocalizations l10n,
  ) => switch (weekday) {
    AttendanceWeekday.monday => l10n.attendanceWeekdayMon,
    AttendanceWeekday.tuesday => l10n.attendanceWeekdayTue,
    AttendanceWeekday.wednesday => l10n.attendanceWeekdayWed,
    AttendanceWeekday.thursday => l10n.attendanceWeekdayThu,
    AttendanceWeekday.friday => l10n.attendanceWeekdayFri,
    AttendanceWeekday.unknown => '—',
  };

  /// Sections du donut des motifs : regroupe UNKNOWN / null / non justifié en
  /// un seul segment rouge « Non justifié », puis les autres motifs triés par
  /// effectif décroissant. Retourne aussi le total d'absences (trou central).
  static ({List<DonutChartSection> sections, int total}) reasonDonut(
    List<AbsenceReasonStats> stats,
    AppLocalizations l10n,
  ) {
    final total = stats.fold<int>(0, (sum, e) => sum + e.absenceDays);
    double pct(int n) => total == 0 ? 0 : (n / total) * 100;

    var unjustified = 0;
    final byReason = <AbsenceReason, int>{};
    for (final e in stats) {
      final reason = e.reason;
      if (reason == null || reason.isUnjustified) {
        unjustified += e.absenceDays;
      } else {
        byReason[reason] = (byReason[reason] ?? 0) + e.absenceDays;
      }
    }

    // Entrées triées par effectif décroissant ; les couleurs sont ensuite
    // assignées par RANG (palette « ordre décroissant »), « Non justifié »
    // restant toujours rouge — évite toute collision de teinte entre segments.
    final entries = <({String label, int count, bool unjustified})>[
      if (unjustified > 0)
        (
          label: l10n.attendanceOverviewReasonUnjustified,
          count: unjustified,
          unjustified: true,
        ),
      for (final entry in byReason.entries)
        (
          label: entry.key.getDisplayName(l10n),
          count: entry.value,
          unjustified: false,
        ),
    ]..sort((a, b) => b.count.compareTo(a.count));

    var paletteIndex = 0;
    final sections = [
      for (final entry in entries)
        DonutChartSection(
          label: entry.label,
          count: entry.count,
          percent: pct(entry.count),
          color: entry.unjustified
              ? AppColors.error
              : _reasonPalette[paletteIndex++ % _reasonPalette.length],
        ),
    ];

    return (sections: sections, total: total);
  }
}
