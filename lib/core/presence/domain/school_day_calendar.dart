/// Les jours et les mois du Pointage, sur des dates civiles `YYYY-MM-DD` —
/// jamais d'heure ni de fuseau, pour qu'un calcul fait à 23 h ne glisse pas
/// d'un jour.
///
/// Jours ouvrés : lundi → vendredi, bornés par l'année scolaire. Jours fériés
/// et samedis ne sont pas connus (dette commune avec le serveur).
abstract final class SchoolDayCalendar {
  /// `YYYY-MM-DD` d'un instant, dans le fuseau de la tablette.
  static String dayOf(DateTime moment) => _format(moment.toLocal());

  /// `YYYY-MM` d'un jour.
  static String monthOf(String day) => day.substring(0, 7);

  /// Le 1er du mois `YYYY-MM`, en `YYYY-MM-DD`.
  static String firstOf(String month) => '$month-01';

  static String addDays(String day, int delta) =>
      _format(_parse(day).add(Duration(days: delta)));

  static String addMonths(String month, int delta) {
    final first = _parse(firstOf(month));
    return _format(
      DateTime.utc(first.year, first.month + delta),
    ).substring(0, 7);
  }

  /// Lundi = 1 … dimanche = 7.
  static int weekdayOf(String day) => _parse(day).weekday;

  static bool isWeekday(String day) => weekdayOf(day) <= DateTime.friday;

  /// Le jour ouvré précédent ou suivant [day] (pas de week-end).
  static String stepWorkDay(String day, int direction) {
    var next = addDays(day, direction);
    while (!isWeekday(next)) {
      next = addDays(next, direction);
    }
    return next;
  }

  /// Les jours ouvrés du mois `YYYY-MM`, jusqu'à [today] inclus, et dans
  /// l'année scolaire [year] quand elle est connue. Vide = vacances.
  static List<String> workDaysOf(
    String month, {
    required String today,
    SchoolYearBounds? year,
  }) => [
    for (final day in daysOf(month))
      if (isWeekday(day) &&
          day.compareTo(today) <= 0 &&
          (year == null || year.contains(day)))
        day,
  ];

  /// Tous les jours du mois `YYYY-MM`.
  static List<String> daysOf(String month) {
    final first = _parse(firstOf(month));
    final count = DateTime.utc(first.year, first.month + 1, 0).day;
    return [for (var i = 0; i < count; i++) addDays(firstOf(month), i)];
  }

  static DateTime _parse(String day) {
    final parts = day.split('-').map(int.parse).toList(growable: false);
    return DateTime.utc(parts[0], parts[1], parts.length > 2 ? parts[2] : 1);
  }

  static String _format(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-'
        '${two(date.day)}';
  }
}

/// Les bornes de l'année scolaire courante, `YYYY-MM-DD`. Une borne inconnue
/// n'exclut rien.
class SchoolYearBounds {
  final String? start;
  final String? end;

  const SchoolYearBounds({this.start, this.end});

  bool contains(String day) =>
      (start == null || day.compareTo(start!) >= 0) &&
      (end == null || day.compareTo(end!) <= 0);
}
