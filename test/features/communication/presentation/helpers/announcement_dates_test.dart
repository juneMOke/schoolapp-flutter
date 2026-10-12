import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/presentation/helpers/announcement_dates.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

import '../../communication_fixtures.dart';

void main() {
  final l10n = AppLocalizationsFr();

  // Les formats de date du français, chargés comme l'application les charge.
  setUpAll(() => GlobalMaterialLocalizations.delegate.load(const Locale('fr')));
  // 23:30 UTC = 00:30 le 13 à Kinshasa : « aujourd'hui » se juge là-bas.
  final now = DateTime.utc(2026, 10, 12, 23, 30);

  test('le jour se lit à l\'heure de l\'école', () {
    expect(
      AnnouncementDates.moment(l10n, DateTime.utc(2026, 10, 13, 6, 30), now),
      "aujourd'hui · 07:30",
    );
    expect(
      AnnouncementDates.moment(l10n, DateTime.utc(2026, 10, 14, 6), now),
      'demain · 07:00',
    );
    expect(
      AnnouncementDates.moment(l10n, DateTime.utc(2026, 10, 12, 10), now),
      'hier · 11:00',
    );
  });

  test('la date d\'une ligne dit ce qu\'elle date', () {
    final planned = AnnouncementDates.rowDate(
      l10n,
      announcement(
        status: AnnouncementStatus.scheduled,
        scheduledAt: DateTime.utc(2026, 10, 14, 6),
      ),
      now,
    );
    expect(planned, 'Prévu demain · 07:00');
    final edited = AnnouncementDates.rowDate(
      l10n,
      announcement(updatedAt: DateTime.utc(2026, 10, 13, 8)),
      now,
    );
    expect(edited, "Modifié aujourd'hui · 09:00");
  });
}
