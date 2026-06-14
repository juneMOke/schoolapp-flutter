import 'package:flutter/material.dart';

/// Formatage localisé propre au tableau de bord des présences.
///
/// Sans dépendance `intl` directe (convention du projet) : les dates passent
/// par [MaterialLocalizations] et les séparateurs numériques sont déduits de la
/// locale courante (fr/en).
class AttendanceOverviewFormat {
  const AttendanceOverviewFormat._();

  static bool _isFr(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'fr';

  /// Taux à une décimale, séparateur localisé (fr « 92,4 » · en « 92.4 »).
  static String rate(double value, BuildContext context) =>
      value.toStringAsFixed(1).replaceAll('.', _isFr(context) ? ',' : '.');

  /// Entier avec séparateur de milliers localisé
  /// (fr « 10 000 » avec espace fine insécable · en « 10,000 »).
  static String count(int value, BuildContext context) {
    final sep = _isFr(context) ? ' ' : ',';
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(sep);
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '-' : ''}$buffer';
  }

  /// Fenêtre analysée. Forme compacte « 01 → 30 avril 2026 » quand début et fin
  /// sont dans le même mois ; sinon plage de dates moyennes localisées.
  static String window(DateTime start, DateTime end, BuildContext context) {
    final ml = MaterialLocalizations.of(context);
    String day(DateTime d) => d.day.toString().padLeft(2, '0');
    if (start.year == end.year && start.month == end.month) {
      return '${day(start)} → ${day(end)} ${ml.formatMonthYear(end)}';
    }
    return '${ml.formatMediumDate(start)} → ${ml.formatMediumDate(end)}';
  }

  /// Horodatage de génération, ex. « 12 juin 2026 · 08:14 ».
  static String generatedAt(DateTime dateTime, BuildContext context) {
    final ml = MaterialLocalizations.of(context);
    final time = ml.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
      alwaysUse24HourFormat: true,
    );
    return '${ml.formatMediumDate(dateTime)} · $time';
  }
}
