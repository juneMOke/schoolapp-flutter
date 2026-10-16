import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/keyboard/route_key_shortcut.dart';

void main() {
  late int presses;

  setUp(() => presses = 0);

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => RouteKeyShortcut(
          activators: const [
            SingleActivator(LogicalKeyboardKey.keyB, control: true),
          ],
          onPressed: () => presses++,
          child: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const Dialog(child: TextField()),
            ),
            child: const Text('modale'),
          ),
        ),
      ),
    ),
  );

  Future<void> ctrlB(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  testWidgets('répond sans qu’aucun élément ait le focus', (tester) async {
    await pump(tester);
    await ctrlB(tester);
    expect(presses, 1);
  });

  testWidgets('B seul ne déclenche rien', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    expect(presses, 0);
  });

  testWidgets('une modale ouverte par-dessus garde ses touches', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('modale'));
    await tester.pumpAndSettle();
    await ctrlB(tester);
    expect(presses, 0);
  });
}
