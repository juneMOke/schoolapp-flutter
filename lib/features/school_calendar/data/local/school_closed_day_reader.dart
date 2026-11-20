import 'package:school_app_flutter/features/school_calendar/data/local/calendar_event_dao.dart';
import 'package:school_app_flutter/features/school_calendar/data/local/calendar_reference_dao.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_replacements.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le jour fermé pour **toute l'école** (E13) : un jour férié ou des
/// vacances du calendrier **publié**, de portée « l'école ». Mon journal le
/// dit (« Pas de cours ») sans rien refuser — un rattrapage reste possible.
/// Un congé d'un seul cycle ne ferme pas la journée d'un enseignant qui a
/// cours ailleurs.
class SchoolClosedDayReader {
  final DatabaseExecutor _db;
  final String? Function() _schoolId;

  const SchoolClosedDayReader(this._db, {required String? Function() schoolId})
    : _schoolId = schoolId;

  static const _closing = [
    CalendarNature.publicHoliday,
    CalendarNature.holidayBreak,
  ];

  /// L'élément qui ferme [day] (jour civil), le férié avant les vacances ;
  /// `null` si l'école a cours, ou sans calendrier publié.
  Future<CalendarElement?> closingOf(DateTime day) async {
    final date = DateTime.utc(day.year, day.month, day.day);
    final schoolId = _schoolId() ?? '';
    final reference = CalendarReferenceDao(_db);
    final calendar = [
      for (final c in await reference.calendars(schoolId))
        if (c.isPublished &&
            !date.isBefore(c.startDate) &&
            !date.isAfter(c.endDate))
          c,
    ].firstOrNull;
    if (calendar == null) return null;
    final framework = (await reference.frameworks(
      schoolId,
    )).where((f) => f.yearLabel == calendar.yearLabel).firstOrNull;
    final elements = CalendarReplacements.resolveForDisplay([
      ...?framework?.items,
      for (final e in await CalendarEventDao(_db).eventsOf(calendar.id))
        if (!e.isRejectedCreation) e.element,
    ]);
    for (final nature in _closing) {
      for (final e in elements) {
        if (e.nature == nature && e.scope is SchoolScope && e.covers(date)) {
          return e;
        }
      }
    }
    return null;
  }
}
