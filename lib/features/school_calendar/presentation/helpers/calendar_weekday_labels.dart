import 'package:flutter/material.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les jours de la semaine, **lundi en premier**, dans la langue de l'écran :
/// abrégés (« lun. ») ou en initiales (« L ») pour le mois compact.
class CalendarWeekdayLabels {
  const CalendarWeekdayLabels._();

  static List<String> of(BuildContext context, {required bool compact}) {
    if (compact) {
      // `narrowWeekdays` part du dimanche.
      final narrow = MaterialLocalizations.of(context).narrowWeekdays;
      return [...narrow.sublist(1), narrow.first];
    }
    final l10n = AppLocalizations.of(context)!;
    return [
      for (var weekday = 1; weekday <= 7; weekday++)
        l10n.calendarWeekdayShort(weekday.toString()),
    ];
  }

  /// Le bandeau du mois (maquette `CalMonthView`) : « Lundi » en grand,
  /// « Lun. » sous 900 dp ([narrow]), « Lu » sous 600 ([compact]).
  static List<String> header(
    BuildContext context, {
    required bool compact,
    required bool narrow,
  }) {
    final l10n = AppLocalizations.of(context)!;
    String upper(String s) =>
        s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
    return [
      for (var weekday = 1; weekday <= 7; weekday++)
        compact
            ? l10n.calendarWeekdayTwo('$weekday')
            : narrow
            ? upper(l10n.calendarWeekdayShort('$weekday'))
            : upper(l10n.calendarWeekdayName('$weekday')),
    ];
  }
}
