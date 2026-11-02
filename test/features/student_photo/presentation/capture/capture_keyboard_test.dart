import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';

import '../photo_layout_harness.dart';
import 'capture_dialog_layout_test.dart' show openCapture;

const _window = Size(1440, 900);

final _shutter = find.byType(PhotoShutterButton);

/// Le nœud de focus du déclencheur.
FocusNode _shutterNode(WidgetTester tester) => Focus.of(
  tester.element(
    find.descendant(of: _shutter, matching: find.byType(AnimatedOpacity)),
  ),
);

/// Le nœud de focus du bouton « Importer » de la barre.
FocusNode _importNode(WidgetTester tester) =>
    Focus.of(tester.element(find.text('Importer')));

/// Tabule jusqu'à [node] ; échoue s'il n'est jamais atteint.
Future<void> _tabTo(WidgetTester tester, FocusNode Function() node) async {
  for (var i = 0; i < 8 && !node().hasFocus; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  expect(node().hasFocus, isTrue, reason: 'jamais atteint par Tab');
}

void main() {
  final harness = PhotoLayoutHarness();

  setUpAll(PhotoLayoutHarness.registerFallbacks);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('Tab atteint le déclencheur, Entrée prend la photo', (
    tester,
  ) async {
    await openCapture(tester, size: _window);
    await _tabTo(tester, () => _shutterNode(tester));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleFrames(tester);
    expect(harness.cameras.opened.last.captures, 1);
  });

  testWidgets('déclencheur focalisé : Espace prend la photo', (tester) async {
    await openCapture(tester, size: _window);
    await _tabTo(tester, () => _shutterNode(tester));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleFrames(tester);
    expect(harness.cameras.opened.last.captures, 1);
  });

  testWidgets('aucun contrôle focalisé : Espace prend la photo', (
    tester,
  ) async {
    await openCapture(tester, size: _window);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleFrames(tester);
    expect(harness.cameras.opened.last.captures, 1);
  });

  testWidgets('« Importer » focalisé : Espace importe, ne photographie pas', (
    tester,
  ) async {
    await openCapture(tester, size: _window);
    await _tabTo(tester, () => _importNode(tester));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleFrames(tester);
    verify(() => harness.files.acquire(any())).called(1);
    expect(harness.cameras.opened.last.captures, 0, reason: 'aucune prise');
  });

  testWidgets('souris : curseur main sur le déclencheur', (tester) async {
    await openCapture(tester, size: _window);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(_shutter));
    await tester.pump();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.click,
    );
  });
}
