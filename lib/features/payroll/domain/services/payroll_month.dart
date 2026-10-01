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
}
