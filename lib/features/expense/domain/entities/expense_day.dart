/// Une date de dépense : un **jour**, sans heure ni fuseau.
///
/// La date d'une dépense est un `DATE` côté serveur — « un décaissement de
/// mardi saisi jeudi appartient à mardi ». La manipuler en `DateTime` local à
/// minuit, et la ranger en `YYYY-MM-DD`, épargne tout le piège des bornes
/// horodatées : deux chaînes de ce format se comparent comme les jours
/// qu'elles nomment.
abstract final class ExpenseDay {
  /// Retire l'heure.
  static DateTime of(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// `2026-09-05` — le format du contrat et de la colonne locale.
  static String format(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-$month-$day';
  }

  /// Lecture tolérante : `null` sur une chaîne absente ou illisible, jamais
  /// d'exception — un jour mal formé ne doit pas faire tomber tout un pull.
  static DateTime? tryParse(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    if (value.length < 10) return null;
    final parsed = DateTime.tryParse(value.substring(0, 10));
    return parsed == null ? null : of(parsed);
  }

  /// Ajoute [days] jours **calendaires** (le passage à l'heure d'été ne
  /// décale jamais la date, contrairement à `add(Duration(days: n))`).
  static DateTime addDays(DateTime value, int days) =>
      DateTime(value.year, value.month, value.day + days);

  /// Lundi de la semaine ISO qui contient [value] — le dimanche ferme la
  /// semaine, il ne l'ouvre pas.
  static DateTime startOfIsoWeek(DateTime value) {
    final day = of(value);
    return addDays(day, -(day.weekday - DateTime.monday));
  }

  /// Nombre de jours entre deux dates, bornes **incluses**.
  static int spanInclusive(DateTime from, DateTime to) =>
      DateTime.utc(
        to.year,
        to.month,
        to.day,
      ).difference(DateTime.utc(from.year, from.month, from.day)).inDays +
      1;
}
