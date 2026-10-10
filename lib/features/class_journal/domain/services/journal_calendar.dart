import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';

/// Les jours de cours du professeur, tels que son emploi du temps actuel les
/// répète chaque semaine.
///
/// Limites assumées (décision D2) : un changement d'emploi du temps
/// renumérote les pages passées, et un jour de congé compte comme une page —
/// le serveur n'a pas de calendrier des congés.
class JournalCalendar {
  final Set<Weekday> courseDays;
  final DateTime? yearStart;
  final DateTime? yearEnd;

  const JournalCalendar({
    required this.courseDays,
    this.yearStart,
    this.yearEnd,
  });

  /// `null` le dimanche : l'emploi du temps s'arrête au samedi.
  static Weekday? weekdayOf(DateTime day) =>
      day.weekday == DateTime.sunday ? null : Weekday.values[day.weekday - 1];

  bool hasCourses(DateTime day) => courseDays.contains(weekdayOf(day));

  /// Le N° de page de [day] : son rang parmi les jours de cours depuis le
  /// début de l'année. `null` sans date de début, avant elle, ou un jour sans
  /// cours.
  int? pageNumber(DateTime day) {
    final start = yearStart;
    if (start == null || day.isBefore(start) || !hasCourses(day)) return null;
    var rank = 0;
    for (
      var d = DateTime(start.year, start.month, start.day);
      !d.isAfter(day);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      if (hasCourses(d)) rank++;
    }
    return rank;
  }

  /// Le premier jour de cours après [day], dans l'année ; `null` sans jour de
  /// cours ou au-delà de la fin d'année.
  DateTime? nextCourseDay(DateTime day) {
    if (courseDays.isEmpty) return null;
    for (var i = 1; i <= DateTime.daysPerWeek; i++) {
      final next = DateTime(day.year, day.month, day.day + i);
      if (!hasCourses(next)) continue;
      final end = yearEnd;
      return end != null && next.isAfter(end) ? null : next;
    }
    return null;
  }
}
