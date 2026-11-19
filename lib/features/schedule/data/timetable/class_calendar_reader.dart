import 'package:school_app_flutter/features/schedule/domain/entities/timetable/class_timetable_view.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_event_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_reference_dao.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/days_between.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Une semaine datée vue d'une classe : ses jours (A15, la même fonction
/// `DaysBetween` que le serveur), et l'année publiée qui la couvre.
class ClassCalendarWeek {
  final List<CalendarDay> days;

  /// Le calendrier publié qui couvre la semaine, `null` hors année (R20).
  final SchoolCalendar? calendar;

  /// La rentrée la plus proche à venir, pour « Hors année scolaire · rentrée
  /// le … ».
  final DateTime? nextStart;

  const ClassCalendarWeek({required this.days, this.calendar, this.nextStart});
}

/// Lit le calendrier **publié** de l'école pour une classe (R18 du calendrier :
/// un brouillon n'est jamais vu ailleurs).
class ClassCalendarReader {
  final DatabaseExecutor _db;
  final String? Function() _schoolId;

  const ClassCalendarReader(this._db, {required String? Function() schoolId})
    : _schoolId = schoolId;

  Future<ClassCalendarWeek> week(
    TimetableClassOption classroom,
    DateTime monday,
    DateTime sunday,
  ) async {
    final schoolId = _schoolId() ?? '';
    final reference = CalendarReferenceDao(_db);
    final calendars = [
      for (final c in await reference.calendars(schoolId))
        if (c.isPublished) c,
    ];
    SchoolCalendar? covering;
    DateTime? nextStart;
    for (final c in calendars) {
      if (!c.endDate.isBefore(monday) && !c.startDate.isAfter(sunday)) {
        covering = c;
      }
      if (c.startDate.isAfter(sunday) &&
          (nextStart == null || c.startDate.isBefore(nextStart))) {
        nextStart = c.startDate;
      }
    }
    if (covering == null) {
      return ClassCalendarWeek(days: const [], nextStart: nextStart);
    }
    final framework = (await reference.frameworks(
      schoolId,
    )).where((f) => f.yearLabel == covering!.yearLabel).firstOrNull;
    final events = await CalendarEventDao(_db).eventsOf(covering.id);
    final days = DaysBetween.compute(
      from: monday,
      to: sunday,
      classroom: ClassroomScopeKey(
        cycleCode: classroom.cycleCode,
        levelCode: classroom.levelCode,
        rhythm: PeriodRhythm.fromWire(classroom.periodType),
        catalogLevelCode: classroom.catalogLevelCode,
      ),
      // Un événement refusé par le serveur n'a pas cours (il est montré en
      // erreur dans le calendrier, jamais compté dans une semaine de classe).
      elements: [
        ...?framework?.items,
        for (final e in events)
          if (!e.isRejected) e.element,
      ],
    );
    return ClassCalendarWeek(
      days: days,
      calendar: covering,
      nextStart: nextStart,
    );
  }
}
