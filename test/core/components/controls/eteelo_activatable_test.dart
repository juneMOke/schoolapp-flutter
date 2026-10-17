import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';

const _zone = Key('zone');

void main() {
  late List<ActivatableHighlight> seen;
  late int activations;

  setUp(() {
    seen = [];
    activations = 0;
  });

  Future<void> pump(WidgetTester tester, {bool enabled = true}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: EteeloActivatable(
              onActivate: enabled ? () => activations++ : null,
              builder: (context, highlight) {
                seen.add(highlight);
                return const SizedBox.square(key: _zone, dimension: 40);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> focusByTab(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }

  testWidgets('un tap active la zone', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(_zone));
    expect(activations, 1);
  });

  testWidgets('Tab la rend focalisée, Entrée et Espace l’activent', (
    tester,
  ) async {
    await pump(tester);
    await focusByTab(tester);
    expect(seen.last.focused, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(activations, 2);
  });

  testWidgets('le survol de la souris est rendu au builder', (tester) async {
    await pump(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byKey(_zone)));
    await tester.pumpAndSettle();
    expect(seen.last.hovered, isTrue);
  });

  testWidgets('sans onActivate : ni tap, ni focus, ni survol', (tester) async {
    await pump(tester, enabled: false);
    await tester.tap(find.byKey(_zone), warnIfMissed: false);
    await focusByTab(tester);
    expect(activations, 0);
    expect(seen.every((h) => !h.any), isTrue);
  });

  testWidgets('onHighlightChanged suit le focus clavier, sans décalage', (
    tester,
  ) async {
    final changes = <ActivatableHighlight>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: EteeloActivatable(
              onActivate: () {},
              onHighlightChanged: changes.add,
              builder: (context, highlight) =>
                  const SizedBox.square(dimension: 40),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(changes.single.focused, isTrue);
  });
}
