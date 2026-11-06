import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/domain/presence_month_views.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_month_calendar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/ink_visibility.dart';

/// Le calendrier d'un mois : le détail d'un jour dans sa case, la marque
/// « à envoyer », et un jour passé qui s'ouvre quand la fiche le permet.
void main() {
  Future<List<String>> pump(
    WidgetTester tester, {
    required List<PresenceCalendarDay?> days,
    bool tappable = true,
  }) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PresenceMonthCalendar(
            days: days,
            onTapDay: tappable ? tapped.add : null,
          ),
        ),
      ),
    );
    return tapped;
  }

  const past = PresenceCalendarDay(
    day: '2026-10-01',
    upcoming: false,
    status: PresenceStatus.present,
    detail: '07:25',
  );
  const pending = PresenceCalendarDay(
    day: '2026-10-02',
    upcoming: false,
    status: PresenceStatus.absent,
    pending: true,
  );
  const upcoming = PresenceCalendarDay(day: '2026-10-05', upcoming: true);

  testWidgets('un jour passé s\'ouvre ; un jour à venir, jamais', (
    tester,
  ) async {
    final tapped = await pump(
      tester,
      days: [null, null, past, pending, upcoming],
    );

    expect(find.text('07:25'), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.tap(find.text('5'));
    expect(tapped, ['2026-10-01']);
  });

  testWidgets('la marque « à envoyer » et son infobulle', (tester) async {
    await pump(tester, days: [pending]);

    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    expect(find.byTooltip(RegExp('à envoyer')), findsOneWidget);
  });

  testWidgets('le survol et le focus d\'une case se voient', (tester) async {
    await pump(tester, days: [past, pending]);
    // Le fond de la case est un Ink : l'encre de l'InkWell passe dessus.
    expectInkNotCovered(tester, find.byType(InkWell));
  });

  testWidgets('sans onTapDay, rien ne s\'ouvre', (tester) async {
    final tapped = await pump(tester, days: [past], tappable: false);
    await tester.tap(find.text('1'));
    expect(tapped, isEmpty);
  });
}
