import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/domain/presence_month_views.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_panel_card.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_incident_list.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_rate_bars.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/widgets/dashboard/hr_two_columns.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_month.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le corps d'un mois d'agent, sur deux colonnes quand la place le permet :
/// le calendrier, et à côté la tendance sur six mois ([withTrend]) et les
/// retards et absences du mois.
class HrPresenceMonthBody extends StatelessWidget {
  final HrAttendanceAgentMonth month;
  final bool withTrend;

  /// Les jours corrigés sur la tablette, pas encore relus du serveur : leur
  /// case montre la ligne locale, marquée « à envoyer ».
  final Map<String, StaffAttendanceRecord?> localDays;

  /// `null` : le calendrier se lit seulement.
  final ValueChanged<String>? onTapDay;

  const HrPresenceMonthBody({
    super.key,
    required this.month,
    this.withTrend = true,
    this.localDays = const {},
    this.onTapDay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final days = {for (final day in month.days) day.date: day};
    final weekdays = days.keys.toList()..sort();
    final calendar = EteeloPanelCard(
      title: dates.formatMonthYear(DateTime.parse('${month.month}-01')),
      child: PresenceMonthCalendar(
        onTapDay: onTapDay,
        days: weekdays.isEmpty
            ? const []
            : presenceCalendar(
                weekdays: weekdays,
                firstWeekday: SchoolDayCalendar.weekdayOf(weekdays.first),
                upcoming: (day) => days[day]!.future,
                statusOf: (day) => localDays.containsKey(day)
                    ? localDays[day]?.status ?? PresenceStatus.none
                    : days[day]!.status,
                detailOf: (day) => localDays.containsKey(day)
                    ? _localDetail(localDays[day], l10n)
                    : _detail(days[day]!, l10n),
                pendingOf: localDays.containsKey,
              ),
      ),
    );
    final incidents = EteeloPanelCard(
      title: l10n.presenceMarkIncidentsTitle,
      child: PresenceIncidentList<StaffAbsenceReason>(
        incidents: [
          for (final day in month.incidents)
            PresenceIncident(
              day: day.date,
              status: day.status,
              arrival: ClockTime.tryParse(day.arrival),
              lateMinutes: day.lateMinutes,
              reason: day.reason,
            ),
        ],
        reasonLabel: (reason) => StaffAttendanceLabels.reason(l10n, reason),
      ),
    );
    // Le calendrier prend la plus grande part : c'est lui qu'on lit.
    return HrTwoColumns(
      firstFlex: 3,
      secondFlex: 2,
      first: calendar,
      second: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (withTrend && month.trend.isNotEmpty) ...[
            EteeloPanelCard(
              title: l10n.hrPresenceAgentTrendTitle,
              child: PresenceRateBars(
                bars: [
                  for (final point in month.trend)
                    _trendBar(point, l10n, dates),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          incidents,
        ],
      ),
    );
  }

  static String? _detail(HrAttendanceDay day, AppLocalizations l10n) =>
      _detailOf(
        l10n,
        status: day.status,
        arrival: ClockTime.tryParse(day.arrival),
        lateMinutes: day.lateMinutes,
        reason: day.reason,
      );

  static String? _localDetail(
    StaffAttendanceRecord? record,
    AppLocalizations l10n,
  ) => record == null
      ? null
      : _detailOf(
          l10n,
          status: record.status,
          arrival: record.arrival,
          lateMinutes: record.lateMinutes,
          reason: record.justification?.reason,
        );

  /// Le détail d'une case : l'arrivée d'un présent, le retard, le motif
  /// d'une absence ou « non justifiée » ; rien pour un jour non pointé.
  static String? _detailOf(
    AppLocalizations l10n, {
    required PresenceStatus status,
    required ClockTime? arrival,
    required int lateMinutes,
    required StaffAbsenceReason? reason,
  }) => switch (status) {
    PresenceStatus.present => arrival?.wire,
    PresenceStatus.late =>
      lateMinutes > 0
          ? l10n.hrPresenceCalendarLate(lateMinutes)
          : arrival?.wire,
    PresenceStatus.absent =>
      reason == null
          ? l10n.hrPresenceCalendarUnjustified
          : StaffAttendanceLabels.reason(l10n, reason),
    PresenceStatus.none => null,
  };

  PresenceRateBarData _trendBar(
    HrAttendanceTrendPoint point,
    AppLocalizations l10n,
    MaterialLocalizations dates,
  ) {
    final date = DateTime.tryParse('${point.month}-01');
    final when = date == null ? point.month : dates.formatMonthYear(date);
    final pct = point.presenceRatePct;
    return PresenceRateBarData(
      label: date == null
          ? point.month
          : l10n.hrPresenceMonthShort('${date.month}'),
      presencePct: pct,
      description: pct == null
          ? l10n.hrPresenceBarEmpty(when)
          : l10n.hrPresenceTrendDescription(when, pct),
    );
  }
}
