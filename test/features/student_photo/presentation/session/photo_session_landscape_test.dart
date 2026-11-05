import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_shoot_viewfinder.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../student_photo_fakes.dart';
import '../photo_layout_harness.dart';
import 'photo_session_layout_test.dart' show openShooting;

const _portrait = Size(360, 740);
const _landscape = Size(740, 360);

final _shutter = find.byType(PhotoShutterButton);
final _viewfinder = find.byType(SessionShootViewfinder);

/// [finder] tient-il tout entier dans la fenêtre, page à son origine ?
void _expectInside(WidgetTester tester, Finder finder, Size window) {
  final rect = tester.getRect(finder);
  final screen = Offset.zero & window;
  expect(
    screen.contains(rect.topLeft) &&
        rect.right <= screen.right &&
        rect.bottom <= screen.bottom,
    isTrue,
    reason: '$finder : $rect hors de $window',
  );
}

/// La page n'a pas défilé : ce qui est à l'écran l'est d'emblée.
void _expectUnscrolled(WidgetTester tester) {
  final page = find
      .ancestor(of: _shutter, matching: find.byType(Scrollable))
      .last;
  expect(tester.state<ScrollableState>(page).position.pixels, 0);
}

void main() {
  final harness = PhotoLayoutHarness();

  setUpAll(PhotoLayoutHarness.registerFallbacks);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testAtReferenceFormats('prise de vue : déclencheur et gestes sans défiler', (
    tester,
    format,
  ) async {
    await openShooting(
      tester,
      harness,
      size: format.size,
      textScale: format.textScale,
    );
    _expectUnscrolled(tester);
    _expectInside(tester, _shutter, format.size);
    _expectInside(tester, find.text('Passer'), format.size);
    _expectInside(tester, find.text('Absent'), format.size);
  });

  testWidgets('740×360, texte ×1,3 : rien ne déborde, déclencheur à l’écran', (
    tester,
  ) async {
    await openShooting(tester, harness, size: _landscape, textScale: 1.3);
    _expectUnscrolled(tester);
    _expectInside(tester, _shutter, _landscape);
    expect(tester.takeException(), isNull);
  });

  testWidgets('740×360 : le viseur à gauche, le déclencheur à droite', (
    tester,
  ) async {
    await openShooting(tester, harness, size: _landscape);
    expect(
      tester.getTopLeft(_shutter).dx,
      greaterThan(tester.getTopRight(_viewfinder).dx),
    );
  });

  testWidgets('rotation aller-retour : le viseur et son flux survivent', (
    tester,
  ) async {
    await openShooting(tester, harness, size: _portrait);
    final element = tester.element(_viewfinder);
    final preview = tester.state(find.byType(CountedPreview));
    // Empilés : le déclencheur sous le viseur.
    expect(
      tester.getTopLeft(_shutter).dy,
      greaterThan(tester.getBottomLeft(_viewfinder).dy),
    );

    tester.view.physicalSize = _landscape;
    await settleFrames(tester);
    expect(
      tester.getTopLeft(_shutter).dx,
      greaterThan(tester.getTopRight(_viewfinder).dx),
      reason: 'paysage attendu',
    );
    expect(identical(tester.element(_viewfinder), element), isTrue);
    expect(
      identical(tester.state(find.byType(CountedPreview)), preview),
      isTrue,
    );

    tester.view.physicalSize = _portrait;
    await settleFrames(tester);
    expect(identical(tester.element(_viewfinder), element), isTrue);
    expect(
      identical(tester.state(find.byType(CountedPreview)), preview),
      isTrue,
    );

    expect(harness.cameras.opened, hasLength(1), reason: 'caméra rouverte');
    expect(harness.cameras.opened.single.previewMounts, 1);
  });

  testWidgets('740×360 : le déclencheur prend la photo', (tester) async {
    await openShooting(tester, harness, size: _landscape);
    await tester.tap(_shutter);
    await settleFrames(tester);
    expect(harness.cameras.opened.single.captures, 1);
    // Le flash tient dans le viseur bas.
    expect(tester.takeException(), isNull);
  });

  testWidgets('740×360 : Espace prend la photo', (tester) async {
    await openShooting(tester, harness, size: _landscape);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleFrames(tester);
    expect(harness.cameras.opened.single.captures, 1);
    expect(tester.takeException(), isNull);
  });
}
