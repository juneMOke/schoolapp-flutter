import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/keyboard/idle_focus_shortcut.dart';

void main() {
  late int invoked;
  late int pressed;

  Future<void> pump(WidgetTester tester) async {
    invoked = 0;
    pressed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: IdleFocusShortcut(
          activator: const SingleActivator(LogicalKeyboardKey.space),
          onInvoke: () => invoked++,
          autofocus: true,
          child: Scaffold(
            body: TextButton(
              onPressed: () => pressed++,
              child: const Text('bouton'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('focus libre : la touche déclenche l’écran', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(invoked, 1);
    expect(pressed, 0);
  });

  testWidgets('bouton focalisé : la touche lui revient', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(Focus.of(tester.element(find.text('bouton'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(pressed, 1);
    expect(invoked, 0);
  });
}
