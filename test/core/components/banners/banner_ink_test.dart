import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner.dart';
import 'package:school_app_flutter/core/components/banners/kuba_banner_month.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_banner_parts.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les zones d'appui des bandeaux sombres (mois, date, horaire) : leurs
/// voiles de focus et de survol sont blanc cassé, et ils se peignent sur un
/// `Material` transparent posé AU-DESSUS du dégradé — pas sur celui de la
/// page, que le dégradé opaque recouvre.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: KubaBanner(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectOnDarkInk(WidgetTester tester, Finder owner) {
    final inkWells = find.descendant(of: owner, matching: find.byType(InkWell));
    expect(inkWells, findsOneWidget);
    final ink = tester.widget<InkWell>(inkWells);
    expect(ink.focusColor, AppColors.stateFocusOnDark);
    expect(ink.hoverColor, AppColors.stateHoverOnDark);
    // Le Material qui reçoit l'encre est sous le bandeau, pas la page.
    final material = tester
        .element(inkWells)
        .findAncestorWidgetOfExactType<Material>();
    expect(material?.type, MaterialType.transparency);
    expect(
      find.ancestor(of: inkWells, matching: find.byType(KubaBanner)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(KubaBanner),
        matching: find.byWidget(material!),
      ),
      findsOneWidget,
    );
  }

  testWidgets('le mois du bandeau', (tester) async {
    await pump(
      tester,
      KubaBannerMonth(
        eyebrow: 'Livre de paie',
        month: '2026-09',
        status: null,
        onPrevious: () {},
        onNext: null,
        onCurrent: null,
        onPick: () {},
      ),
    );
    expectOnDarkInk(tester, find.byTooltip('Choisir un mois'));
  });

  testWidgets('la date du jour', (tester) async {
    await pump(tester, PresenceBannerDay(day: '2026-09-30', onPick: () {}));
    expectOnDarkInk(tester, find.byType(PresenceBannerDay));
  });

  testWidgets('la pastille de l\'horaire', (tester) async {
    await pump(
      tester,
      PresenceSchedulePill(schedule: PresenceSchedule.defaults, onTap: () {}),
    );
    expectOnDarkInk(tester, find.byType(PresenceSchedulePill));
  });
}
