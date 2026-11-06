import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../photo_layout_harness.dart';
import 'photo_session_layout_test.dart' show openShooting;

const _window = Size(1440, 900);

void main() {
  final harness = PhotoLayoutHarness();

  setUpAll(PhotoLayoutHarness.registerFallbacks);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('aucun contrôle focalisé : Espace déclenche', (tester) async {
    await openShooting(tester, harness, size: _window);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleFrames(tester);
    expect(harness.cameras.opened.last.captures, 1);
  });

  testWidgets('« Importer » focalisé : Espace importe, ne déclenche pas', (
    tester,
  ) async {
    await openShooting(tester, harness, size: _window);
    final import = find.text('Importer un fichier pour cet élève');
    FocusNode node() => Focus.of(tester.element(import));
    for (var i = 0; i < 12 && !node().hasFocus; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(node().hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleFrames(tester);
    verify(() => harness.files.acquire(any())).called(1);
    expect(harness.cameras.opened.last.captures, 0, reason: 'aucune prise');
  });
}
