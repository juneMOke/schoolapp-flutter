import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/step_page_card.dart';

void main() {
  Widget harness({double? viewportHeight, required Widget body}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(height: viewportHeight, child: body),
      ),
    );
  }

  StepPageCard buildCard({Widget? child}) {
    return StepPageCard(
      eyebrow: 'ÉTAPE 1 SUR 7 · IDENTITÉ',
      title: 'Identité',
      subtitle: 'Informations personnelles',
      accentColor: const Color(0xFF1B4D6B),
      icon: Icons.badge_outlined,
      child: child ?? const SizedBox(height: 200, child: Text('contenu')),
    );
  }

  testWidgets(
    'StepPageCard se rend sans erreur en hauteur non bornée (scroll)',
    (tester) async {
      // Reproduit le contexte réel du stepper : carte dans un
      // SingleChildScrollView qui impose une hauteur non bornée.
      await tester.pumpWidget(
        harness(body: SingleChildScrollView(child: buildCard())),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Identité'), findsOneWidget);
    },
  );

  testWidgets('StepPageCard se rend sans erreur en hauteur bornée', (
    tester,
  ) async {
    await tester.pumpWidget(harness(viewportHeight: 600, body: buildCard()));

    expect(tester.takeException(), isNull);
    expect(find.text('Identité'), findsOneWidget);
  });

  testWidgets('StepPageCard rend le bandeau fourni au-dessus du contenu', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        viewportHeight: 600,
        body: const StepPageCard(
          eyebrow: 'ÉTAPE 1 SUR 7 · IDENTITÉ',
          title: 'Identité',
          subtitle: 'Informations personnelles',
          accentColor: Color(0xFF1B4D6B),
          icon: Icons.badge_outlined,
          banner: Text('BANDEAU'),
          child: SizedBox(height: 200, child: Text('contenu')),
        ),
      ),
    );

    expect(find.text('BANDEAU'), findsOneWidget);
    // Le bandeau est rendu au-dessus du corps de l'étape.
    expect(
      tester.getTopLeft(find.text('BANDEAU')).dy,
      lessThan(tester.getTopLeft(find.text('contenu')).dy),
    );
  });

  testWidgets('StepPageCard sans bandeau : rien rendu', (tester) async {
    await tester.pumpWidget(harness(viewportHeight: 600, body: buildCard()));

    expect(find.text('BANDEAU'), findsNothing);
  });
}
