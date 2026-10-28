/// J, les jours ouvrés d'un mois civil `YYYY-MM` : du lundi au vendredi,
/// vacances scolaires comprises — les agents sont payés pendant les
/// vacances —, sans jour férié tant que l'école n'a pas de calendrier des
/// fériés (V1). Le diviseur de la retenue d'absence (formule 3), le même
/// calcul que le serveur (`WorkingDays`).
///
/// Septembre 2026 = 22, octobre = 22, novembre = 21, décembre = 23,
/// février 2027 = 20.
abstract final class PayrollWorkingDays {
  static int of(String month) {
    final year = int.parse(month.substring(0, 4));
    final monthNumber = int.parse(month.substring(5, 7));
    final length = DateTime.utc(year, monthNumber + 1, 0).day;
    var days = 0;
    for (var day = 1; day <= length; day++) {
      final weekday = DateTime.utc(year, monthNumber, day).weekday;
      if (weekday != DateTime.saturday && weekday != DateTime.sunday) days++;
    }
    return days;
  }
}
