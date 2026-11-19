import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_enums.dart';
import 'package:school_app_flutter/features/school_calendar/domain/services/calendar_days.dart';

/// La phase d'un calendrier, calculée sur l'appareil (arbitrage A3).
///
/// Le serveur la sert aussi, comme témoin ; l'écran ne s'y fie jamais, pour ne
/// pas basculer à minuit entre deux sources. [today] est le jour **de l'école**
/// (`SchoolTime.today`), jamais celui du poste.
///
/// - Brouillon : DRAFT, quelles que soient les dates.
/// - UPCOMING : publié, avant [startDate].
/// - IN_FORCE : de [startDate] à [endDate] inclus.
/// - ARCHIVED : à partir du début du cadre de l'année suivante
///   ([nextFrameworkStartDate]), sinon du premier lundi de septembre qui suit
///   [endDate].
/// - ENDED : entre la fin et l'archivage.
///
/// Les vecteurs partagés `calendar/phase-vectors.json` (lot V0) tiennent ce
/// calcul identique à `CalendarPhase` côté serveur.
class CalendarPhaseRule {
  const CalendarPhaseRule._();

  static CalendarPhase compute({
    required CalendarStatus status,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime today,
    DateTime? nextFrameworkStartDate,
  }) {
    if (status == CalendarStatus.draft) return CalendarPhase.draft;
    final day = CalendarDays.of(today);
    if (day.isBefore(CalendarDays.of(startDate))) return CalendarPhase.upcoming;
    if (!day.isAfter(CalendarDays.of(endDate))) return CalendarPhase.inForce;
    final archivedFrom = archiveDate(
      endDate: endDate,
      nextFrameworkStartDate: nextFrameworkStartDate,
    );
    return day.isBefore(archivedFrom)
        ? CalendarPhase.ended
        : CalendarPhase.archived;
  }

  static DateTime archiveDate({
    required DateTime endDate,
    DateTime? nextFrameworkStartDate,
  }) => nextFrameworkStartDate == null
      ? CalendarDays.firstMondayOfSeptemberAfter(endDate)
      : CalendarDays.of(nextFrameworkStartDate);
}
