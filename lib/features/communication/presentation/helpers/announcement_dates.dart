import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les dates du module, lues **à l'heure de l'école** (Kinshasa), jamais à
/// celle de la tablette.
abstract final class AnnouncementDates {
  /// « aujourd'hui · 07:30 », « demain · 07:30 », « mer. 14 oct. · 07:00 » :
  /// une forme qui se glisse dans une phrase (« Prévu demain · 07:30 »).
  static String moment(AppLocalizations l10n, DateTime instant, DateTime now) {
    final wall = SchoolTime.wallClock(instant);
    final today = SchoolTime.today(now);
    final day = DateTime(wall.year, wall.month, wall.day);
    final delta = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    final dayLabel = switch (delta) {
      0 => l10n.communicationToday,
      1 => l10n.communicationTomorrow,
      -1 => l10n.communicationYesterday,
      _ => l10n.communicationDateShort(day),
    };
    return l10n.communicationDayAtTime(dayLabel, l10n.communicationClock(wall));
  }

  /// La date d'une ligne, précédée de ce qu'elle date.
  static String? rowDate(
    AppLocalizations l10n,
    Announcement announcement,
    DateTime now,
  ) {
    final date = announcement.referenceDate;
    if (date == null) return null;
    final when = moment(l10n, date, now);
    return switch (announcement.status) {
      AnnouncementStatus.scheduled => l10n.communicationDatePlanned(when),
      AnnouncementStatus.sent => l10n.communicationDateSent(when),
      _ => l10n.communicationDateEdited(when),
    };
  }
}
