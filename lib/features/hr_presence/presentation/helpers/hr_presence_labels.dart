import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dashboard/dashboard_period_tabs.dart';
import 'package:school_app_flutter/core/entities/dashboard_period.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_rate_bars.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les mots de RH · Présences qui dépendent de la donnée : l'en-tête, le
/// graphique, la liste et le PDF nomment la même fenêtre.
abstract final class HrPresenceLabels {
  /// « 23 oct. 2026 ».
  static String longDate(DateTime day, MaterialLocalizations dates) =>
      dates.formatMediumDate(day);

  /// « vendredi 23 octobre 2026 ».
  static String fullDate(DateTime day, MaterialLocalizations dates) =>
      dates.formatFullDate(day);

  /// Le détail de la fenêtre, selon la période (spec §1) : la date longue du
  /// jour, « du … au … », le mois, ou l'année scolaire jusqu'à aujourd'hui.
  static String windowDetail(
    DashboardWindow window,
    DashboardPeriod period,
    AppLocalizations l10n,
    MaterialLocalizations dates, {
    String? schoolYear,
  }) {
    if (window.isSingleDay) return fullDate(window.to, dates);
    final to = longDate(window.to, dates);
    return switch (period) {
      DashboardPeriod.month => dates.formatMonthYear(window.to),
      DashboardPeriod.year when schoolYear != null => l10n.hrPresenceWindowYear(
        schoolYear,
        to,
      ),
      _ => l10n.hrPresenceWindowRange(longDate(window.from, dates), to),
    };
  }

  /// « Ce mois · octobre 2026 » : la période et son détail.
  static String period(
    DashboardWindow window,
    DashboardPeriod period,
    AppLocalizations l10n,
    MaterialLocalizations dates, {
    String? schoolYear,
  }) => l10n.hrJoin(
    DashboardPeriodTabs.labelOf(period, l10n),
    windowDetail(window, period, l10n, dates, schoolYear: schoolYear),
  );

  /// Le nom affiché d'un agent, dans l'ordre du Personnel : nom, post-nom,
  /// prénom.
  static String fullName(HrAttendanceAgent agent) => [
    agent.lastName,
    agent.middleName ?? '',
    agent.firstName ?? '',
  ].map((part) => part.trim()).where((part) => part.isNotEmpty).join(' ');

  /// Les barres du graphique, prêtes à dessiner.
  static List<PresenceRateBarData> bars(
    HrAttendanceDashboard dashboard,
    AppLocalizations l10n,
    MaterialLocalizations dates,
  ) {
    final byMonth = dashboard.granularity == HrAttendanceGranularity.month;
    final short = dashboard.series.length <= 5;
    return [
      for (final bar in dashboard.series)
        _bar(bar, l10n, dates, byMonth: byMonth, short: short),
    ];
  }

  static PresenceRateBarData _bar(
    HrAttendanceBar bar,
    AppLocalizations l10n,
    MaterialLocalizations dates, {
    required bool byMonth,
    required bool short,
  }) {
    final date = DateTime.tryParse(byMonth ? '${bar.key}-01' : bar.key);
    final String label;
    final String when;
    if (date == null) {
      label = bar.key;
      when = bar.key;
    } else if (byMonth) {
      label = l10n.hrPresenceMonthShort('${date.month}');
      when = dates.formatMonthYear(date);
    } else {
      // Une semaine se lit « lun. 19 » ; un mois, « 19 ».
      label = short
          ? l10n.hrPresenceWeekdayDay('${date.weekday}', date.day)
          : '${date.day}';
      when = fullDate(date, dates);
    }
    final pct = bar.presenceRatePct;
    return PresenceRateBarData(
      label: label,
      presencePct: bar.isEmpty ? null : pct,
      description: bar.isEmpty || pct == null
          ? l10n.hrPresenceBarEmpty(when)
          : l10n.hrPresenceBarDescription(
              when,
              pct,
              bar.presences,
              bar.scored,
              bar.absenceRatePct ?? 100 - pct,
            ),
    );
  }
}
