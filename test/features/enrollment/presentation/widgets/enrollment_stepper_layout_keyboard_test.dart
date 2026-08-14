import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/breadcrumb/wizard_progress_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/breadcrumb/wizard_step_dot.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le clavier logiciel retire sa hauteur au body (`resizeToAvoidBottomInset`) :
/// la disposition du parcours doit tenir dans ce qui reste, sans jamais
/// déborder — c'est le bug d'origine (`RenderFlex overflowed`, 961,5 × 130,1 sur
/// téléphone en paysage, à chaque saisie).
void main() {
  // Pied d'actions réel ≈ 49 dp (padding + boutons compacts + liseré).
  const controlsHeight = 49.0;

  Widget buildHarness() {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: EnrollmentStepperLayout(
          stepTitles: List.generate(7, (i) => 'Étape ${i + 1}'),
          currentStep: 2,
          progress: 3 / 7,
          onStepTap: (_) {},
          stepTitle: 'Informations personnelles',
          stepSubtitle: 'Identité de l\'élève',
          stepEyebrow: 'Étape 3 sur 7 · Identité',
          stepAccentColor: const Color(0xFF2F4858),
          stepIcon: Icons.badge_outlined,
          // Contenu volumineux : c'est lui qui doit défiler, jamais la colonne.
          stepContent: const SizedBox(height: 600),
          controls: const SizedBox(height: controlsHeight),
        ),
      ),
    );
  }

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();
  }

  testWidgets('paysage clavier ouvert (961,5 × 130,1) : aucun débordement', (
    tester,
  ) async {
    await pumpAt(tester, const Size(961.5, 130.1));

    expect(
      tester.takeException(),
      isNull,
      reason: 'la colonne du stepper ne doit plus déborder sous le clavier',
    );
    // À cette hauteur, la barre d'étapes entière laisserait moins de rien au
    // champ en cours de saisie : elle s'efface, le pied d'actions reste.
    expect(find.byType(WizardStepDot), findsNothing);
    expect(find.byType(SizedBox).evaluate(), isNotEmpty);
  });

  testWidgets('portrait clavier ouvert : barre réduite à sa progression', (
    tester,
  ) async {
    await pumpAt(tester, const Size(411, 380));

    expect(tester.takeException(), isNull);
    // La progression situe encore le parcours ; les chips, eux, ne sont pas
    // actionnables pendant une saisie et cèdent leur place.
    expect(find.byType(WizardProgressBar), findsOneWidget);
    expect(find.byType(WizardStepDot), findsNothing);
  });

  testWidgets('sans clavier : chrome complet, les 7 steps sont là', (
    tester,
  ) async {
    await pumpAt(tester, const Size(961.5, 720));

    expect(tester.takeException(), isNull);
    expect(find.byType(WizardStepDot), findsNWidgets(7));
    expect(find.byType(WizardProgressBar), findsOneWidget);
  });

  testWidgets('hauteur ras du pied d\'actions : toujours aucun débordement', (
    tester,
  ) async {
    // Cas extrême (fenêtre écrasée) : il ne reste que le pied.
    await pumpAt(tester, const Size(961.5, 60));

    expect(tester.takeException(), isNull);
  });
}
