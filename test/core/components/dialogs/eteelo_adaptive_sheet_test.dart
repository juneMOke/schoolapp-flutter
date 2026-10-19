import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_sheet.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    double width, {
    double keyboard = 0,
    double gestureBar = 0,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    tester.view.padding = FakeViewPadding(bottom: gestureBar);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showEteeloAdaptiveSheet<void>(
              context: context,
              builder: (_) => const Text('contenu', key: Key('c')),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('écran étroit : une feuille du bas', (tester) async {
    await open(tester, 500);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('écran large : une modale centrée', (tester) async {
    await open(tester, 1400);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('contenu'), findsOneWidget);
  });

  testWidgets('la feuille monte au-dessus du clavier', (tester) async {
    await open(tester, 500, keyboard: 300);
    expect(
      tester.getRect(find.byKey(const Key('c'))).bottom,
      lessThanOrEqualTo(900 - 300),
    );
  });

  testWidgets('son pied ne passe pas sous la barre gestuelle', (tester) async {
    await open(tester, 500, gestureBar: 24);
    expect(
      tester.getRect(find.byKey(const Key('c'))).bottom,
      lessThanOrEqualTo(900 - 24),
    );
  });
}
