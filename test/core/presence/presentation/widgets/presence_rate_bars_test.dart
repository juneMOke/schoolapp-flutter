import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_rate_bars.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    List<PresenceRateBarData> bars, {
    double width = 600,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          // L'état final dès la première frame.
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: PresenceRateBars(bars: bars),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  PresenceRateBarData bar(int? pct, [String label = 'lun. 19']) =>
      PresenceRateBarData(
        label: label,
        description: 'jour · $pct',
        presencePct: pct,
      );

  test('largeur de barre : deux tiers du pas, jamais un pas sous 36 dp', () {
    expect(PresenceRateBars.barWidthFor(count: 5, width: 600), 46);
    // Un mois sur téléphone : le tracé s'élargit à 23 × 36 dp et défile.
    expect(PresenceRateBars.contentWidthFor(count: 23, width: 300), 828);
    expect(PresenceRateBars.scrollsFor(count: 23, width: 300), isTrue);
    expect(
      PresenceRateBars.barWidthFor(count: 23, width: 300),
      closeTo(23.76, 0.01),
    );
    expect(PresenceRateBars.scrollsFor(count: 23, width: 900), isFalse);
    expect(PresenceRateBars.isNarrow(21), isTrue);
    expect(PresenceRateBars.isNarrow(22), isFalse);
  });

  testWidgets('large : « 86 % » au-dessus, « 14 % » dans le rouge ; un jour '
      'sans pointage sans chiffre', (tester) async {
    await pump(tester, [bar(86), bar(100), bar(null)]);

    expect(find.text('86 %'), findsOneWidget);
    expect(find.text('14 %'), findsOneWidget);
    expect(find.text('100 %'), findsOneWidget);
    expect(find.text('0 %'), findsNothing);
    expect(find.bySemanticsLabel('jour · null'), findsOneWidget);
  });

  testWidgets('un mois sur téléphone : les barres gardent leur largeur et le '
      'tracé défile, ouvert sur les derniers jours', (tester) async {
    await pump(tester, [
      for (var i = 0; i < 23; i++) bar(80, 'j$i'),
    ], width: 320);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    // Le taux garde son « % » : la barre fait 24 dp.
    expect(find.text('80 %'), findsWidgets);
    expect(find.text('80'), findsNothing);
    // Le dernier jour est à l'écran, le premier hors champ à gauche.
    final view = tester.getRect(find.byType(SingleChildScrollView));
    expect(view.contains(tester.getCenter(find.text('j22'))), isTrue);
    expect(find.text('j0').hitTestable(), findsNothing);
  });

  testWidgets('chaque segment a sa hauteur : vert en bas, rouge au-dessus', (
    tester,
  ) async {
    await pump(tester, [bar(80)]);
    final heights = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(PresenceRateBars),
            matching: find.byType(ColoredBox),
          ),
        )
        .map((box) => tester.getSize(find.byWidget(box)))
        .toList();
    expect(heights, hasLength(2));
    final total = heights.fold<double>(0, (sum, s) => sum + s.height);
    expect(heights.last.height, closeTo(total * 0.8, 0.5));
    for (final size in heights) {
      expect(size.width, greaterThan(0));
    }
  });
}
