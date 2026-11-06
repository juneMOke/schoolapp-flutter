import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/cotes/presentation/helpers/cote_focus_registry.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/bulletin/cote_bulletin_legend.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La légende nomme chaque état qu'une case peut prendre — y compris la
/// case remplacée par une écriture venue d'ailleurs.
void main() {
  testWidgets('la case « modifiée ailleurs » a son entrée', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CoteBulletinLegend(
            columns: const [],
            enterMove: CoteMove.down,
            showKeyboardHelp: false,
            onToggleEnter: () {},
          ),
        ),
      ),
    );
    expect(find.text('Modifiée ailleurs'), findsOneWidget);
    // « Moins de la moitié » se souligne, comme les notes qu'il décrit.
    expect(
      tester.widget<Text>(find.text('Moins de la moitié')).style?.decoration,
      TextDecoration.underline,
    );
  });

  test('le liseré de la case modifiée tient 3:1 sur son fond', () {
    // warning (#D68910) n'y tenait que 2,6:1.
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    // Contrôle de l'instrument : noir sur blanc = 21.
    expect(ratio(const Color(0xFF000000), const Color(0xFFFFFFFF)), 21);
    expect(ratio(AppColors.warning, AppColors.coteChangedSurface), lessThan(3));
    expect(
      ratio(AppColors.coteChangedBorder, AppColors.coteChangedSurface),
      greaterThanOrEqualTo(3),
    );
  });
}
