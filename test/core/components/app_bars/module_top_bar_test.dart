import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';

Future<void> _pump(WidgetTester tester, ModuleTopBar bar) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(appBar: bar, body: const SizedBox()),
  ),
);

void main() {
  testWidgets('la page d\'entrée d\'un module n\'a nulle part où revenir : '
      'aucune flèche', (tester) async {
    await _pump(
      tester,
      const ModuleTopBar(eyebrow: 'Boutique', title: 'Caisse'),
    );

    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    expect(find.text('BOUTIQUE'), findsOneWidget);
    expect(find.text('Caisse'), findsOneWidget);
  });

  testWidgets('la flèche dit où elle mène, et rend la main à l\'écran', (
    tester,
  ) async {
    var backs = 0;
    await _pump(
      tester,
      ModuleTopBar(
        eyebrow: 'Recouvrement',
        title: 'Contrôle nominatif',
        backTooltip: 'Retour au tableau de bord',
        onBack: () => backs++,
      ),
    );

    await tester.tap(find.byTooltip('Retour au tableau de bord'));

    expect(backs, 1);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });
}
