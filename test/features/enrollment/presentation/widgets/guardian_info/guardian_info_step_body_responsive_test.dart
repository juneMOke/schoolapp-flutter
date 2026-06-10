import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_info_step_body.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  const title = 'Informations des tuteurs';
  const buttonLabel = 'Ajouter un tuteur/responsable';

  Widget harness(double width) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: GuardianInfoStepBody(
          parentDetails: const [],
          onItemStateChanged: (_, _) {},
          onItemValueChanged: (_, _) {},
          onAddParent: () {},
          onSave: () {},
          showInlineSaveButton: false,
        ),
      ),
    ),
  );

  testWidgets(
    'Téléphone (<520px) : titre et bouton empilés (bouton sous le titre)',
    (tester) async {
      await tester.pumpWidget(harness(360));
      await tester.pumpAndSettle();

      final titleBottom = tester.getBottomLeft(find.text(title)).dy;
      final buttonTop = tester.getTopLeft(find.text(buttonLabel)).dy;
      // Empilé : le bouton est sous le bloc titre.
      expect(buttonTop, greaterThan(titleBottom));
    },
  );

  testWidgets(
    'Large (>=520px) : titre et bouton sur la même ligne (bouton à droite)',
    (tester) async {
      await tester.pumpWidget(harness(800));
      await tester.pumpAndSettle();

      final titleCenterY = tester.getCenter(find.text(title)).dy;
      final buttonCenterY = tester.getCenter(find.text(buttonLabel)).dy;
      final titleX = tester.getTopLeft(find.text(title)).dx;
      final buttonX = tester.getTopLeft(find.text(buttonLabel)).dx;

      // En ligne : même bande verticale (approx.) et bouton à droite du titre.
      expect((buttonCenterY - titleCenterY).abs(), lessThan(60));
      expect(buttonX, greaterThan(titleX));
    },
  );
}
