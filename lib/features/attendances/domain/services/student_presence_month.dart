import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/presence/domain/presence_month_views.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_month.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_student.dart';
import 'package:school_app_flutter/features/attendances/domain/services/student_month_stats.dart';

/// La fiche mensuelle d'un élève : sa synthèse, son calendrier et ses
/// retards et absences. Lecture seule.
class StudentPresenceMonth extends Equatable {
  final ClassPresenceStudent student;
  final StudentMonthStats stats;

  /// Les jours de semaine du mois, en semaines complètes du lundi au
  /// vendredi ; `null` pour une case hors du mois.
  final List<PresenceCalendarDay?> calendar;
  final List<PresenceIncident<AbsenceReason>> incidents;
  final bool isHoliday;

  const StudentPresenceMonth({
    required this.student,
    required this.stats,
    required this.calendar,
    required this.incidents,
    required this.isHoliday,
  });

  factory StudentPresenceMonth.build(
    ClassPresenceMonth month,
    ClassPresenceStudent student, {
    required String today,
    SchoolYearBounds? year,
  }) {
    final schoolDays = month.schoolDays(today: today, year: year);
    final counted = schoolDays.toSet();
    final weekdays = [
      for (final day in SchoolDayCalendar.daysOf(month.month))
        if (SchoolDayCalendar.isWeekday(day)) day,
    ];
    PresenceStatus statusOf(String day) {
      if (!month.calledDays.contains(day)) {
        return month.closed ? PresenceStatus.present : PresenceStatus.none;
      }
      return month.incidentOf(day, student.id)?.status ??
          PresenceStatus.present;
    }

    return StudentPresenceMonth(
      student: student,
      stats: StudentMonthStats.of(month, student.id, schoolDays: schoolDays),
      calendar: presenceCalendar(
        weekdays: weekdays,
        firstWeekday: weekdays.isEmpty
            ? 1
            : SchoolDayCalendar.weekdayOf(weekdays.first),
        upcoming: (day) => !counted.contains(day),
        statusOf: statusOf,
      ),
      incidents: [
        for (final day in schoolDays)
          if (month.incidentOf(day, student.id) case final line?)
            PresenceIncident(
              day: day,
              status: line.status,
              arrival: line.mark.arrival,
              lateMinutes: line.mark.lateMinutes,
              reason: line.mark.justification?.reason,
            ),
      ],
      isHoliday: schoolDays.isEmpty,
    );
  }

  @override
  List<Object?> get props => [student, stats, calendar, incidents, isHoliday];
}
