import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Durées proposées en pilules (spec §4 bis) ; « Autre » ouvre un champ en
/// minutes, « Non définie » vaut `null`.
const List<int> kDureePresets = [30, 45, 60, 90, 120];

/// « 45 min » sous l'heure, sinon « 1 h » ou « 1 h 30 ».
String formatDuree(AppLocalizations l10n, int minutes) {
  if (minutes < 60) return l10n.dureeMinutes(minutes);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0
      ? l10n.dureeHours(hours)
      : l10n.dureeHoursMinutes(hours, rest.toString().padLeft(2, '0'));
}
