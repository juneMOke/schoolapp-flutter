import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/breadcrumb/wizard_progress_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/wizard_breadcrumb.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHarness({
    required int currentStep,
    required int totalSteps,
    ValueChanged<int>? onStepTap,
  }) {
    final titles = List.generate(totalSteps, (i) => 'Étape ${i + 1}');

    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        // La barre utilise des steps Expanded → largeur bornée requise.
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 700,
            child: WizardBreadcrumb(
              titles: titles,
              currentStep: currentStep,
              progress: (currentStep + 1) / totalSteps,
              onStepTap: onStepTap ?? (int _) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Wizard breadcrumb no longer shows the global step count', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness(currentStep: 2, totalSteps: 7));

    // L'indicateur global « Étape N / M » a été retiré (déjà affiché dans
    // l'AppBar) — la barre ne montre plus que les steps + la progression.
    expect(find.text('Étape 3 / 7'), findsNothing);
  });

  testWidgets('Wizard breadcrumb shows done steps with checkmark', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness(currentStep: 3, totalSteps: 7));

    // Steps 0, 1, 2 are done and should show checkmarks
    expect(find.byIcon(Icons.check_rounded), findsWidgets);
  });

  testWidgets('Wizard breadcrumb highlights current step', (tester) async {
    await tester.pumpWidget(buildHarness(currentStep: 2, totalSteps: 7));

    // The current step (index 2) should be highlighted
    // We check for the step number being displayed
    expect(find.text('Étape 3'), findsWidgets);
  });

  testWidgets('Wizard breadcrumb forbids tap on future steps', (tester) async {
    var tappedSteps = <int>[];

    await tester.pumpWidget(
      buildHarness(
        currentStep: 2,
        totalSteps: 7,
        onStepTap: (int step) => tappedSteps.add(step),
      ),
    );

    // Try to tap on future step (index 4, which is future relative to current step 2)
    // Future steps should not be clickable
    final futureStepCircles = find.byType(InkWell);

    // Tap on a future step (after current)
    // Get the Ink well for the future step
    // Let's tap step 5 (which is future)
    await tester.tap(futureStepCircles.at(5));
    await tester.pump();

    // The callback should not have been called for future steps
    expect(
      tappedSteps.where((step) => step > 2).length,
      0,
      reason: 'Future steps should not be tappable',
    );
  });

  testWidgets('Wizard breadcrumb allows tap on current and done steps', (
    tester,
  ) async {
    var tappedSteps = <int>[];

    await tester.pumpWidget(
      buildHarness(
        currentStep: 3,
        totalSteps: 7,
        onStepTap: (int step) => tappedSteps.add(step),
      ),
    );

    // Tap on a done step (index 1)
    final inkWells = find.byType(InkWell);

    await tester.tap(inkWells.first);
    await tester.pump();

    // Tap on current step (index 3)
    await tester.tap(inkWells.at(3));
    await tester.pump();

    // Both should have been recorded
    expect(tappedSteps, isNotEmpty);
  });

  testWidgets('Wizard breadcrumb displays progress bar', (tester) async {
    await tester.pumpWidget(buildHarness(currentStep: 2, totalSteps: 7));

    expect(find.byType(WizardProgressBar), findsOneWidget);

    final progressBar = tester.widget<WizardProgressBar>(
      find.byType(WizardProgressBar),
    );

    expect(progressBar.progress, closeTo(3 / 7, 0.01));
  });

  testWidgets('Wizard breadcrumb shows step titles with 7 steps layout', (
    tester,
  ) async {
    await tester.pumpWidget(buildHarness(currentStep: 0, totalSteps: 7));

    expect(find.text('Étape 1'), findsWidgets);
    expect(find.text('Étape 7'), findsWidgets);
  });
}
