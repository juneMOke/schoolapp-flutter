import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Libellés localisés des jours de la grille (LUN→SAM), en forme longue
/// (« Lundi ») pour l'en-tête de la grille et courte (« Lun. ») pour le
/// sélecteur de la vue Jour. Zéro string en dur (règle non-négociable #4).
class ScheduleWeekdayLabels {
  const ScheduleWeekdayLabels._();

  static String long(AppLocalizations l10n, Weekday day) => switch (day) {
    Weekday.mon => l10n.scheduleWeekdayLongMon,
    Weekday.tue => l10n.scheduleWeekdayLongTue,
    Weekday.wed => l10n.scheduleWeekdayLongWed,
    Weekday.thu => l10n.scheduleWeekdayLongThu,
    Weekday.fri => l10n.scheduleWeekdayLongFri,
    Weekday.sat => l10n.scheduleWeekdayLongSat,
  };

  static String short(AppLocalizations l10n, Weekday day) => switch (day) {
    Weekday.mon => l10n.scheduleWeekdayShortMon,
    Weekday.tue => l10n.scheduleWeekdayShortTue,
    Weekday.wed => l10n.scheduleWeekdayShortWed,
    Weekday.thu => l10n.scheduleWeekdayShortThu,
    Weekday.fri => l10n.scheduleWeekdayShortFri,
    Weekday.sat => l10n.scheduleWeekdayShortSat,
  };
}
