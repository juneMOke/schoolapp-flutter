import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/presence_month_views.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_ledger.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_stats.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// La fiche mensuelle d'un agent : sa synthèse, son calendrier et ses
/// incidents (retards et absences). Lecture seule.
class StaffAgentMonth extends Equatable {
  final StaffMember member;
  final StaffMonthStats stats;

  /// Les jours de semaine du mois, en semaines complètes du lundi au
  /// vendredi ; `null` pour une case hors du mois.
  final List<PresenceCalendarDay?> calendar;

  /// Retards et absences, par date.
  final List<StaffAttendanceRecord> incidents;
  final bool isHoliday;

  const StaffAgentMonth({
    required this.member,
    required this.stats,
    required this.calendar,
    required this.incidents,
    required this.isHoliday,
  });

  factory StaffAgentMonth.build(
    StaffAttendanceSnapshot snapshot, {
    required StaffMember member,
    required String month,
    required String today,
  }) {
    final ledger = StaffMonthLedger.of(snapshot, month: month, today: today);
    final records = snapshot.records[member.id] ?? const {};
    final worked = ledger.workDays.toSet();
    final weekdays = [
      for (final day in SchoolDayCalendar.daysOf(month))
        if (SchoolDayCalendar.isWeekday(day)) day,
    ];
    return StaffAgentMonth(
      member: member,
      stats: ledger.statsOf(member),
      calendar: presenceCalendar(
        weekdays: weekdays,
        firstWeekday: weekdays.isEmpty
            ? 1
            : SchoolDayCalendar.weekdayOf(weekdays.first),
        upcoming: (day) => !worked.contains(day),
        statusOf: (day) => records[day]?.status ?? PresenceStatus.none,
      ),
      incidents: [
        for (final day in ledger.workDays)
          if (records[day]?.status.isIncident ?? false) records[day]!,
      ],
      isHoliday: ledger.isHoliday,
    );
  }

  @override
  List<Object?> get props => [member, stats, calendar, incidents, isHoliday];
}
