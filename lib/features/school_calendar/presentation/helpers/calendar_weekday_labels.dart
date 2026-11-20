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
}
