import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_controls.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  // Largeur étroite → barre compacte (icônes seules), sous le seuil 600.
  Widget buildCompactHarness({
    int currentStep = 2,
    bool isLast = false,
    bool isSummaryStep = false,
    bool showSaveAction = true,
    bool canSave = true,
    bool canContinue = true,
    bool dirty = true,
    bool valid = true,
    bool savingNow = false,
    VoidCallback? onPrevious,
    VoidCallback? onSave,
    VoidCallback? onContinue,
  }) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: EnrollmentStepperControls(
            currentStep: currentStep,
            isLast: isLast,
            isSummaryStep: isSummaryStep,
            dirty: dirty,
            valid: valid,
            canSave: canSave,
            canContinue: canContinue,
            showSaveAction: showSaveAction,
            savingNow: savingNow,
            saveLabel: 'Enregistrer',
            onPrevious: onPrevious ?? () {},
            onSave: onSave ?? () {},
            onContinue: onContinue ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('Mobile (<600px) : icônes seules, aucun label ni indicateur', (
    tester,
  ) async {
    await tester.pumpWidget(buildCompactHarness());

    // Pas de labels texte.
    expect(find.text('Précédent'), findsNothing);
    expect(find.text('Continuer'), findsNothing);
    expect(find.text('Enregistrer'), findsNothing);
    // Indicateur d'état masqué sur mobile.
    expect(find.text('Modifications non enregistrées'), findsNothing);

    // Les trois icônes sont présentes.
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.save_outlined), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    // Aucun overflow de layout.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile : les icônes déclenchent prev / save / next', (
    tester,
  ) async {
    var prev = 0;
    var save = 0;
    var next = 0;

    await tester.pumpWidget(
      buildCompactHarness(
        onPrevious: () => prev++,
        onSave: () => save++,
        onContinue: () => next++,
      ),
    );

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();

    expect(prev, 1);
    expect(save, 1);
    expect(next, 1);
  });

  testWidgets(
    'Mobile : dernier step → Valider en check PRIMAIRE (proéminent)',
    (tester) async {
      var save = 0;
      // Au dernier step, l'action Valider (portée par save) remplace Suivant et
      // devient un check primaire (icône blanche sur fond terre cuite plein).
      await tester.pumpWidget(
        buildCompactHarness(
          currentStep: 6,
          isLast: true,
          isSummaryStep: true,
          onSave: () => save++,
        ),
      );

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.save_outlined), findsNothing);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);

      // Icône blanche = bouton primaire (plein), pas secondaire bordé.
      final checkIcon = tester.widget<Icon>(
        find.byIcon(Icons.check_circle_outline),
      );
      expect(checkIcon.color, AppColors.blancCasse);

      // C'est bien l'action Valider (save) qui est déclenchée.
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pump();
      expect(save, 1);
    },
  );

  testWidgets('Mobile : dernier step sans save → icône Terminer (check)', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildCompactHarness(
        currentStep: 6,
        isLast: true,
        isSummaryStep: true,
        showSaveAction: false,
      ),
    );

    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.save_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
