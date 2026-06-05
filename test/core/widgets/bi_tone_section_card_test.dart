import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';

void main() {
  group('BiToneSectionCard', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required double width,
      Widget? header,
      String? title,
      String? subtitle,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: BiToneSectionCard(
                  header: header,
                  title: title,
                  subtitle: subtitle,
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('utilise un header horizontal quand le conteneur est large', (
      tester,
    ) async {
      await pumpCard(
        tester,
        width: 420,
        title: 'Recherche',
        subtitle: 'Sous titre',
      );

      expect(find.byType(Expanded), findsOneWidget);
      expect(find.byType(Row), findsNWidgets(2));
    });

    testWidgets('empile icone et texte quand le conteneur est etroit', (
      tester,
    ) async {
      await pumpCard(
        tester,
        width: 260,
        title: 'Recherche',
        subtitle: 'Sous titre',
      );

      expect(find.byType(Expanded), findsNothing);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('priorise le slot header custom sur le header structure', (
      tester,
    ) async {
      await pumpCard(
        tester,
        width: 420,
        header: const Text('Header custom'),
        title: 'Titre structure',
      );

      expect(find.text('Header custom'), findsOneWidget);
      expect(find.text('Titre structure'), findsNothing);
    });

    testWidgets('expose le titre structure comme heading semantic', (
      tester,
    ) async {
      await pumpCard(
        tester,
        width: 420,
        title: 'Titre a11y',
        subtitle: 'Sous titre',
      );

      expect(find.bySemanticsLabel('Titre a11y').hitTestable(), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Titre a11y')),
        matchesSemantics(isHeader: true),
      );
    });

    testWidgets('exclut le leading decoratif de la semantique', (tester) async {
      await pumpCard(tester, width: 420, title: 'Titre a11y');

      final iconFinder = find.byIcon(Icons.search_rounded);
      expect(iconFinder, findsOneWidget);

      expect(
        find.ancestor(of: iconFinder, matching: find.byType(ExcludeSemantics)),
        findsOneWidget,
      );
    });
  });
}
