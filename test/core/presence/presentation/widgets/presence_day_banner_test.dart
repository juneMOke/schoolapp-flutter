import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_banner.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

import '../../../../test_helpers/reference_formats.dart';

/// Le bandeau du jour, partagé par le registre du personnel et l'appel de
/// classe : un jour passé ajoute « Aujourd'hui » aux deux flèches, et la date
/// longue doit encore tenir sur un téléphone, texte ×1,3 compris.
void main() {
  Future<void> pumpBanner(WidgetTester tester, {required bool isToday}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            // La gouttière de page d'un téléphone.
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: PresenceDayBanner(
              eyebrow: 'Registre du jour',
              // Un mercredi de septembre : la date longue la plus large.
              day: '2026-09-30',
              isToday: isToday,
              schedule: PresenceSchedule.defaults,
              marked: 12,
              total: 40,
              detail: '28 à pointer · 3 sur la tablette',
              showActions: true,
              validateLabel: 'Valider la journée',
              onPrevious: () {},
              onNext: isToday ? null : () {},
              onToday: () {},
              onPickDay: () {},
              onSettings: () {},
              onValidate: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testAtReferenceFormats('un jour passé tient, « Aujourd\'hui » compris', (
    tester,
    format,
  ) async {
    await pumpBanner(tester, isToday: false);
    expect(find.text('Aujourd\'hui'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testAtReferenceFormats('le jour même tient', (tester, format) async {
    await pumpBanner(tester, isToday: true);
    expect(find.text('Aujourd\'hui'), findsNothing);
  });

  testWidgets('téléphone : les flèches passent sous la date', (tester) async {
    applyReferenceFormat(tester, kReferenceFormats.first);
    await pumpBanner(tester, isToday: false);
    final dateBottom = tester
        .getBottomLeft(find.textContaining('septembre'))
        .dy;
    expect(
      tester.getTopLeft(find.byIcon(Icons.chevron_left)).dy,
      greaterThan(dateBottom),
    );
  });
}
