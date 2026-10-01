import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_ledger.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_month_stats.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';

/// Une case du calendrier de la fiche mensuelle (lundi → vendredi).
class StaffCalendarDay extends Equatable {
  /// `YYYY-MM-DD`.
  final String day;

  /// Jour à venir (estompé), ou hors de l'année scolaire.
  final bool upcoming;
  final StaffAttendanceRecord? record;

  const StaffCalendarDay({
    required this.day,
    required this.upcoming,
    this.record,
  });

  PresenceStatus get status => record?.status ?? PresenceStatus.none;

  @override
  List<Object?> get props => [day, upcoming, record];
}

/// La fiche mensuelle d'un agent : sa synthèse, son calendrier et ses
/// incidents (retards et absences). Lecture seule.
class StaffAgentMonth extends Equatable {
  final StaffMember member;
  final StaffMonthStats stats;

  /// Les jours de semaine du mois, en semaines complètes du lundi au
  /// vendredi ; `null` pour une case hors du mois.
  final List<StaffCalendarDay?> calendar;

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
    final lead = weekdays.isEmpty
        ? 0
        : SchoolDayCalendar.weekdayOf(weekdays.first) - 1;
    return StaffAgentMonth(
      member: member,
      stats: ledger.statsOf(member),
      calendar: [
        for (var i = 0; i < lead; i++) null,
        for (final day in weekdays)
          StaffCalendarDay(
            day: day,
            upcoming: !worked.contains(day),
            record: records[day],
          ),
      ],
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
