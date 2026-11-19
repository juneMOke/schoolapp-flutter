import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_records.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/school_calendar.dart';

/// Ce que l'appareil connaît du calendrier de l'école, lu en local.
class CalendarLibrary {
  final List<SchoolCalendar> calendars;
  final List<NationalFramework> frameworks;

  const CalendarLibrary({required this.calendars, required this.frameworks});

  NationalFramework? frameworkOf(String yearLabel) {
    for (final f in frameworks) {
      if (f.yearLabel == yearLabel) return f;
    }
    return null;
  }

  /// Le début du cadre de l'année suivante, pour la phase (A3).
  DateTime? nextFrameworkStartOf(SchoolCalendar calendar) {
    final next = calendar.nextYearLabel;
    return next == null ? null : frameworkOf(next)?.startDate;
  }
}

/// Le calendrier scolaire : lecture 100 % locale, écriture des événements
/// 100 % lot de synchro, web compris (A18). Seuls créer, dupliquer et publier
/// sont des appels en ligne.
abstract class SchoolCalendarRepository {
  Future<CalendarLibrary> library();

  Future<List<SchoolEventRecord>> events(String calendarId);

  /// Ajoute ou modifie un événement de l'école ; « date vérifiée » est une
  /// modification qui pose `toVerify:false`.
  Future<Either<Failure, Unit>> saveEvent({
    required String calendarId,
    required CalendarElement element,
  });

  Future<Either<Failure, Unit>> deleteEvent({
    required String calendarId,
    required CalendarElement element,
  });

  /// Un nouvel identifiant d'événement, fabriqué par l'appareil.
  String newEventId();

  /// Les gestes du calendrier encore sur l'appareil (« Publier » attend).
  Future<int> pendingCount(String calendarId);

  /// Les événements qu'un autre appareil a écrasés, rendus une fois.
  Future<List<SchoolEventRecord>> takeSuperseded(String calendarId);

  /// Tire les trois flux du calendrier.
  Future<void> refresh();

  // ── En ligne ──
  Future<Either<Failure, List<({String yearLabel, FrameworkState framework})>>>
  creatableYears();

  Future<Either<Failure, SchoolCalendar>> create(String yearLabel);

  Future<Either<Failure, SchoolCalendar>> duplicate({
    required SchoolCalendar source,
    required List<CalendarNature> natures,
  });

  Future<Either<Failure, SchoolCalendar>> publish(SchoolCalendar calendar);
}
