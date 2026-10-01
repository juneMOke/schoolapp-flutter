import 'package:flutter/material.dart' show MaterialLocalizations;
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les libellés communs du pointage et de l'appel, en un seul endroit.
///
/// Les dates passent par [MaterialLocalizations], comme partout ailleurs dans
/// l'application : aucune donnée de locale à initialiser.
abstract final class PresenceLabels {
  /// Le statut (« En retard »).
  static String status(AppLocalizations l10n, PresenceStatus status) =>
      switch (status) {
        PresenceStatus.none => l10n.presenceMarkStatusNone,
        PresenceStatus.present => l10n.presenceMarkStatusPresent,
        PresenceStatus.late => l10n.presenceMarkStatusLate,
        PresenceStatus.absent => l10n.presenceMarkStatusAbsent,
      };

  /// Le même statut comme filtre (« Retards »).
  static String filter(AppLocalizations l10n, PresenceStatus status) =>
      switch (status) {
        PresenceStatus.none => l10n.presenceMarkStatusNone,
        PresenceStatus.present => l10n.presenceMarkFilterPresent,
        PresenceStatus.late => l10n.presenceMarkFilterLate,
        PresenceStatus.absent => l10n.presenceMarkFilterAbsent,
      };

  /// « mardi 29 septembre 2026 ».
  static String longDay(MaterialLocalizations dates, String day) =>
      dates.formatFullDate(DateTime.parse(day));

  /// « septembre 2026 ».
  static String month(MaterialLocalizations dates, String month) =>
      dates.formatMonthYear(DateTime.parse('$month-01'));

  /// « 29 sept. 2026 · 16:02 » depuis un instant ISO-8601.
  static String? moment(MaterialLocalizations dates, String? iso) {
    final instant = DateTime.tryParse(iso ?? '')?.toLocal();
    if (instant == null) return null;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${dates.formatMediumDate(instant)} · '
        '${two(instant.hour)}:${two(instant.minute)}';
  }

  /// « 3 h » ou « 3 h 30 » depuis des minutes.
  static String hours(AppLocalizations l10n, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0
        ? l10n.presenceMarkHours(h)
        : l10n.presenceMarkHoursMinutes(h, m.toString().padLeft(2, '0'));
  }
}
