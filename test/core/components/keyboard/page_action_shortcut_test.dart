import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/keyboard/page_action_shortcut.dart';

void main() {
  Future<List<String>> pump(
    WidgetTester tester, {
    bool allowed = true,
    bool withAction = true,
  }) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PageActionShortcut(
          action: PageAction.refresh,
          onInvoke: withAction ? () => calls.add('refresh') : null,
          isAllowed: () => allowed,
          child: PageActionShortcut(
            action: PageAction.create,
            onInvoke: () => calls.add('create'),
            child: const Scaffold(body: TextField()),
          ),
        ),
      ),
    );
    return calls;
  }

  Future<void> ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  }

  testWidgets('F5 et Ctrl+R relisent, Ctrl+N crée', (tester) async {
    final calls = await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await ctrl(tester, LogicalKeyboardKey.keyR);
    await ctrl(tester, LogicalKeyboardKey.keyN);
    expect(calls, ['refresh', 'refresh', 'create']);
  });

  testWidgets('même depuis un champ texte', (tester) async {
    final calls = await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    expect(calls, ['refresh']);
  });

  testWidgets('geste interdit : la touche passe son chemin', (tester) async {
    final calls = await pump(tester, allowed: false);
    final handled = await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    expect(calls, isEmpty);
    expect(handled, isFalse);
  });

  testWidgets('une modale ouverte garde ses touches', (tester) async {
    final calls = await pump(tester);
    final context = tester.element(find.byType(TextField));
    showDialog<void>(context: context, builder: (_) => const Text('modale'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    expect(calls, isEmpty);
  });
}
