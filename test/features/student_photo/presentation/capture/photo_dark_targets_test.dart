import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';

import '../photo_layout_harness.dart';
import '../session/photo_session_layout_test.dart' show openShooting;
import 'capture_dialog_layout_test.dart' show openCapture;

const _window = Size(1440, 900);

/// La zone qui répond et s'éclaire : l'`InkWell` du bouton, pas la marge
/// d'appui invisible que Material ajoute autour au doigt.
List<Size> _inkSizes(WidgetTester tester, Finder buttons) => [
  for (final element in buttons.evaluate())
    tester.getSize(
      find.descendant(
        of: find.byWidget(element.widget),
        matching: find.byType(InkWell),
      ),
    ),
];

void main() {
  final harness = PhotoLayoutHarness();

  setUpAll(PhotoLayoutHarness.registerFallbacks);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets(
    'au doigt : croix et pilules de 48 dp, visibles comme telles',
    (tester) async {
      await openCapture(tester, size: _window);
      expect(
        _inkSizes(tester, find.byType(PhotoDarkCloseButton)).single,
        const Size.square(AppDimensions.minTouchTarget),
      );
      for (final size in _inkSizes(tester, find.byType(PhotoDarkPillButton))) {
        expect(size.height, AppDimensions.minTouchTarget);
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'à la souris : pilules de 40 dp au moins (TapTargetHeight)',
    (tester) async {
      await openCapture(tester, size: _window);
      for (final size in _inkSizes(tester, find.byType(PhotoDarkPillButton))) {
        expect(
          size.height,
          greaterThanOrEqualTo(AppDimensions.pointerControlHeight),
        );
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );

  testWidgets(
    'séance : « Passer » et « Absent » à 48 dp au doigt',
    (tester) async {
      await openShooting(tester, harness, size: _window);
      final sizes = _inkSizes(tester, find.byType(PhotoDarkPillButton));
      expect(sizes, hasLength(2));
      for (final size in sizes) {
        expect(size.height, AppDimensions.minTouchTarget);
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
