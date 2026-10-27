import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_pickers.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le calendrier d'un registre : un jour ouvré entre [firstDay] (la rentrée)
/// et [lastDay] (le dernier jour ouvré), les bornes des flèches du bandeau.
/// Samedis et dimanches ne se choisissent pas.
///
/// Rend le jour choisi en `YYYY-MM-DD`, ou `null` si rien n'a été choisi.
Future<String?> pickPresenceDay(
  BuildContext context, {
  required String day,
  required String? firstDay,
  required String lastDay,
}) async {
  final last = SchoolDayCalendar.localDateOf(lastDay);
  // Rentrée inconnue : une année en arrière, comme le registre la lirait.
  final first = firstDay == null
      ? DateTime(last.year - 1, last.month, last.day)
      : SchoolDayCalendar.localDateOf(firstDay);
  if (first.isAfter(last)) return null;
  final current = SchoolDayCalendar.localDateOf(day);
  // Le jour initial doit être choisissable, sans quoi le sélecteur lève :
  // hors bornes, on repart du dernier jour ouvré.
  final inRange = !current.isBefore(first) && !current.isAfter(last);
  final initial = inRange && SchoolDayCalendar.isWeekday(day) ? current : last;
  final picked = await showEteeloDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: last,
    helpText: AppLocalizations.of(context)!.presenceMarkPickDay,
    selectableDayPredicate: (date) =>
        SchoolDayCalendar.isWeekday(SchoolDayCalendar.dayOf(date)),
  );
  return picked == null ? null : SchoolDayCalendar.dayOf(picked);
}
