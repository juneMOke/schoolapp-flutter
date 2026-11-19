/// Arithmétique de **jours civils** pour le calendrier scolaire.
///
/// Un jour civil est un `DateTime` UTC à minuit : l'heure d'été du poste ne
/// peut donc jamais faire glisser un jour (un `DateTime` local à minuit
/// + 24 h peut retomber sur le même jour un dimanche de changement d'heure).
/// Les dates du contrat sont des `yyyy-MM-dd` sans fuseau ; on les lit et les
/// compare toujours sous cette forme.
class CalendarDays {
  const CalendarDays._();

  /// Le jour civil de [value], lu par ses seuls champs année/mois/jour.
  static DateTime of(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  /// `yyyy-MM-dd` → jour civil ; `null` si la chaîne est absente ou illisible.
  static DateTime? tryParse(String? raw) {
    if (raw == null || raw.length < 10) return null;
    final parsed = DateTime.tryParse(raw.substring(0, 10));
    return parsed == null ? null : of(parsed);
  }

  static String format(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static DateTime addDays(DateTime day, int days) =>
      DateTime.utc(day.year, day.month, day.day + days);

  /// Nombre de jours de [from] à [to] (négatif si [to] est avant).
  static int between(DateTime from, DateTime to) =>
      of(to).difference(of(from)).inDays;

  /// Le lundi de la semaine de [day].
  static DateTime mondayOf(DateTime day) =>
      addDays(of(day), -(day.weekday - DateTime.monday));

  static bool isWeekend(DateTime day) =>
      day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

  /// [day] est entre [start] et [end], bornes incluses.
  static bool within(DateTime day, DateTime start, DateTime end) {
    final d = of(day);
    return !d.isBefore(of(start)) && !d.isAfter(of(end));
  }

  /// Le premier lundi de septembre qui suit [day] (strictement après).
  ///
  /// Sert deux fois : rentrée par défaut d'un calendrier sans cadre (CAL-D1)
  /// et date d'archivage sans cadre suivant (A3).
  static DateTime firstMondayOfSeptemberAfter(DateTime day) {
    var year = day.year;
    while (true) {
      final candidate = _firstMondayOfSeptember(year);
      if (candidate.isAfter(of(day))) return candidate;
      year++;
    }
  }

  static DateTime _firstMondayOfSeptember(int year) {
    final first = DateTime.utc(year, 9, 1);
    final shift = (DateTime.monday - first.weekday + 7) % 7;
    return addDays(first, shift);
  }
}
