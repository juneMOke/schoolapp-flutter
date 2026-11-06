import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_flash.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_shoot_viewfinder.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../student_photo_fakes.dart';
import '../photo_layout_harness.dart';
import 'photo_session_layout_test.dart' show openShooting;

const _portrait = Size(360, 740);
const _landscape = Size(740, 360);

final _shutter = find.byType(PhotoShutterButton);
final _viewfinder = find.byType(SessionShootViewfinder);

/// Les gestes de la prise, deux objectifs branchés.
final _gestures = <Finder>[
  _shutter,
  find.text('Passer'),
  find.text('Absent'),
  find.byIcon(Icons.upload_rounded),
  find.byIcon(Icons.cameraswitch_rounded),
];

/// [finder] tient-il tout entier dans la fenêtre ?
void _expectInside(WidgetTester tester, Finder finder, Size window) {
  final rect = tester.getRect(finder);
  expect(
    rect.left >= 0 &&
        rect.top >= 0 &&
        rect.right <= window.width &&
        rect.bottom <= window.height,
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
  setUp(() async {
    await harness.setUp();
    // Un vrai téléphone : deux objectifs, donc « Changer de caméra ».
    harness.cameras.available = [backLens, frontLens];
  });
  tearDown(harness.tearDown);

  testAtReferenceFormats('prise de vue : tous les gestes sans défiler', (
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
    for (final gesture in _gestures) {
      _expectInside(tester, gesture, format.size);
    }
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('740×360, texte ×$scale : viseur et gestes à l’écran', (
      tester,
    ) async {
      await openShooting(tester, harness, size: _landscape, textScale: scale);
      _expectUnscrolled(tester);
      _expectInside(tester, _viewfinder, _landscape);
      for (final gesture in _gestures) {
        _expectInside(tester, gesture, _landscape);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('740×360 à encoches, texte ×$scale : le déclencheur tient', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(top: 24, left: 32, right: 32);
      addTearDown(tester.view.resetPadding);
      await openShooting(tester, harness, size: _landscape, textScale: scale);
      _expectUnscrolled(tester);
      _expectInside(tester, _viewfinder, _landscape);
      for (final gesture in _gestures) {
        _expectInside(tester, gesture, _landscape);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in const [Size(370, 360), Size(400, 400), Size(480, 400)]) {
    testWidgets('$size, basse et étroite : la colonne, cibles de 48 dp', (
      tester,
    ) async {
      await openShooting(tester, harness, size: size);
      expect(tester.takeException(), isNull);
      // Empilés : le déclencheur sous le viseur.
      expect(
        tester.getTopLeft(_shutter).dy,
        greaterThan(tester.getBottomLeft(_viewfinder).dy),
      );
      for (final pill in tester.widgetList(find.byType(PhotoDarkPillButton))) {
        final box = tester.getSize(find.byWidget(pill));
        expect(box.width, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
        expect(box.height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
      }
    });
  }

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

  /// Le flash est là, et sa photo reste lisible.
  void expectReadableFlash(WidgetTester tester) {
    expect(find.byType(SessionFlashOverlay), findsOneWidget);
    final photo = tester.getSize(
      find.descendant(
        of: find.byType(SessionFlashOverlay),
        matching: find.byType(ClipOval),
      ),
    );
    expect(
      photo.shortestSide,
      greaterThanOrEqualTo(AppDimensions.photoSessionFlashPreviewMin),
    );
    _expectInside(tester, find.text('Reprendre'), tester.view.physicalSize);
    expect(tester.takeException(), isNull);
  }

  for (final online in [true, false]) {
    for (final scale in [1.0, 1.3]) {
      final label = '${online ? 'en ligne' : 'hors ligne'}, texte ×$scale';
      testWidgets('740×360, $label : le déclencheur prend la photo', (
        tester,
      ) async {
        harness
          ..acceptSaves()
          ..online = online;
        await openShooting(tester, harness, size: _landscape, textScale: scale);
        await tester.tap(_shutter);
        await settleFrames(tester);
        expect(harness.cameras.opened.single.captures, 1);
        expectReadableFlash(tester);
      });
    }
  }

  testWidgets('740×360 à encoches, hors ligne, ×1,3 : flash lisible', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(top: 24, left: 32, right: 32);
    addTearDown(tester.view.resetPadding);
    harness
      ..acceptSaves()
      ..online = false;
    await openShooting(tester, harness, size: _landscape, textScale: 1.3);
    await tester.tap(_shutter);
    await settleFrames(tester);
    expectReadableFlash(tester);
  });

  testWidgets('360×740 : le flash garde sa photo lisible', (tester) async {
    harness.acceptSaves();
    await openShooting(tester, harness, size: _portrait, textScale: 1.3);
    await tester.tap(_shutter);
    await settleFrames(tester);
    expectReadableFlash(tester);
  });

  testWidgets('740×360 : Espace prend la photo', (tester) async {
    harness.acceptSaves();
    await openShooting(tester, harness, size: _landscape);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleFrames(tester);
    expect(harness.cameras.opened.single.captures, 1);
    expectReadableFlash(tester);
  });
}
