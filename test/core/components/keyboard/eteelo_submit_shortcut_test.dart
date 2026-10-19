import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/keyboard/eteelo_submit_shortcut.dart';

void main() {
  Future<void> pump(WidgetTester tester, VoidCallback? onSubmit) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EteeloSubmitShortcut(
            onSubmit: onSubmit,
            child: const TextField(maxLines: 3),
          ),
        ),
      ),
    );
  }

  Future<void> ctrlEnter(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  testWidgets('Ctrl+Entrée valide sans qu’aucun champ ait le focus', (
    tester,
  ) async {
    var submits = 0;
    await pump(tester, () => submits++);
    await tester.pump();
    await ctrlEnter(tester);
    expect(submits, 1);
  });

  testWidgets('Ctrl+Entrée valide depuis un champ multiligne', (tester) async {
    var submits = 0;
    await pump(tester, () => submits++);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await ctrlEnter(tester);
    expect(submits, 1);
  });

  testWidgets('Entrée seule ne valide pas', (tester) async {
    var submits = 0;
    await pump(tester, () => submits++);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(submits, 0);
  });

  testWidgets('action désactivée : le raccourci ne fait rien', (tester) async {
    await pump(tester, null);
    await tester.pump();
    await ctrlEnter(tester);
    expect(tester.takeException(), isNull);
  });

  group('Échap', () {
    Future<void> openDialog(
      WidgetTester tester, {
      required bool cancels,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) => Dialog(
                  child: EteeloSubmitShortcut(
                    onSubmit: null,
                    onCancel: cancels
                        ? () => Navigator.of(dialogContext).pop()
                        : null,
                    child: const TextField(),
                  ),
                ),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('ferme une modale dont le scrim ne ferme pas', (tester) async {
      await openDialog(tester, cancels: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('ferme aussi depuis un champ', (tester) async {
      await openDialog(tester, cancels: true);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('sans onCancel, la modale reste ouverte', (tester) async {
      await openDialog(tester, cancels: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
