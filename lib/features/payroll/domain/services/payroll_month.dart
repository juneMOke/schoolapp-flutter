import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';

/// Les mois de paie, `YYYY-MM` : s'ordonnent comme des chaînes.
abstract final class PayrollMonth {
  static String of(DateTime date) =>
      SchoolDayCalendar.monthOf(SchoolDayCalendar.dayOf(date));

  static String previous(String month) =>
      SchoolDayCalendar.addMonths(month, -1);

  static String next(String month) => SchoolDayCalendar.addMonths(month, 1);

  static String add(String month, int delta) =>
      SchoolDayCalendar.addMonths(month, delta);

  static String firstDay(String month) => SchoolDayCalendar.firstOf(month);

  static String lastDay(String month) => SchoolDayCalendar.daysOf(month).last;

  /// La période `[from, to]` (jours, `to` facultatif) recoupe-t-elle [month] ?
  static bool overlaps(String month, String from, String? to) =>
      from.compareTo(lastDay(month)) <= 0 &&
      (to == null || to.compareTo(firstDay(month)) >= 0);

  /// Le nombre de mois de [from] à [to] (négatif si [to] précède).
  static int between(String from, String to) {
    final a = _index(from);
    final b = _index(to);
    return a == null || b == null ? 0 : b - a;
  }

  /// Un mois `YYYY-MM` bien formé, ou `null` (lien tronqué, saisie).
  static String? parse(String? raw) {
    if (raw == null || !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(raw)) {
      return null;
    }
    return raw;
  }

  static int? _index(String month) {
    final valid = parse(month);
    if (valid == null) return null;
    return int.parse(valid.substring(0, 4)) * 12 +
        int.parse(valid.substring(5)) -
        1;
  }
}
