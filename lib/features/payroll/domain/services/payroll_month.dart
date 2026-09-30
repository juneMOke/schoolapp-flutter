import 'package:school_app_flutter/features/staff/domain/services/staff_work_calendar.dart';

/// Les mois de paie, `YYYY-MM` : s'ordonnent comme des chaînes.
abstract final class PayrollMonth {
  static String of(DateTime date) =>
      StaffWorkCalendar.monthOf(StaffWorkCalendar.dayOf(date));

  static String previous(String month) =>
      StaffWorkCalendar.addMonths(month, -1);

  static String next(String month) => StaffWorkCalendar.addMonths(month, 1);

  static String add(String month, int delta) =>
      StaffWorkCalendar.addMonths(month, delta);

  static String firstDay(String month) => StaffWorkCalendar.firstOf(month);

  static String lastDay(String month) => StaffWorkCalendar.daysOf(month).last;

  /// La période `[from, to]` (jours, `to` facultatif) recoupe-t-elle [month] ?
  static bool overlaps(String month, String from, String? to) =>
      from.compareTo(lastDay(month)) <= 0 &&
      (to == null || to.compareTo(firstDay(month)) >= 0);
}
