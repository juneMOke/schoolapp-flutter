/// Jour ouvre de la semaine, pour la repartition des absences par jour.
///
/// `unknown` est un repli resilient : le backend ne renvoie que lundi ->
/// vendredi, mais on ne casse pas le parsing sur une valeur inattendue.
enum AttendanceWeekday { monday, tuesday, wednesday, thursday, friday, unknown }

extension AttendanceWeekdayX on AttendanceWeekday {
  static AttendanceWeekday fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'MONDAY' => AttendanceWeekday.monday,
        'TUESDAY' => AttendanceWeekday.tuesday,
        'WEDNESDAY' => AttendanceWeekday.wednesday,
        'THURSDAY' => AttendanceWeekday.thursday,
        'FRIDAY' => AttendanceWeekday.friday,
        _ => AttendanceWeekday.unknown,
      };

  String toApiValue() => switch (this) {
    AttendanceWeekday.monday => 'MONDAY',
    AttendanceWeekday.tuesday => 'TUESDAY',
    AttendanceWeekday.wednesday => 'WEDNESDAY',
    AttendanceWeekday.thursday => 'THURSDAY',
    AttendanceWeekday.friday => 'FRIDAY',
    AttendanceWeekday.unknown => 'UNKNOWN',
  };
}
