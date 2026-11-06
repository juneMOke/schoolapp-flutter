import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/photo_capture_target.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_dialog.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_viewfinder.dart';

import '../photo_layout_harness.dart';

/// Ouvre la modale de capture sur une caméra en direct.
Future<void> openCapture(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
}) async {
  await pumpPhotoApp(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => StudentPhotoCaptureDialog.show(
              context,
              studentName: 'Rose Amani',
              target: const SaveForStudent('ama'),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
    size: size,
    textScale: textScale,
  );
  await tester.tap(find.text('ouvrir'));
  await settleFrames(tester);
}

void main() {
  final harness = PhotoLayoutHarness();

  setUpAll(PhotoLayoutHarness.registerFallbacks);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  test('le seuil du plein écran est celui des modales de saisie', () {
    expect(
      AppBreakpoints.photoCaptureFullscreenMax,
      AppBreakpoints.formDialogFullscreenMax,
    );
  });

  for (final size in referenceFormats) {
    testWidgets('$size : le déclencheur reste à l’écran', (tester) async {
      await openCapture(tester, size: size);
      expect(find.byType(PhotoShutterButton), findsOneWidget);
      expectOnScreen(tester, find.byType(PhotoShutterButton), size);
      expectOnScreen(tester, find.byType(PhotoViewfinder), size);
    });
  }

  for (final size in const [Size(360, 740), Size(740, 360)]) {
    testWidgets('$size, texte ×1,3 : rien ne déborde, déclencheur visible', (
      tester,
    ) async {
      await openCapture(tester, size: size, textScale: 1.3);
      expectOnScreen(tester, find.byType(PhotoShutterButton), size);
    });
  }

  testWidgets('740×360 : plein écran, viseur borné par la hauteur, au format '
      '4:3', (tester) async {
    const size = Size(740, 360);
    await openCapture(tester, size: size);
    final viewfinder = tester.getSize(find.byType(AspectRatio).first);
    expect(viewfinder.height, lessThan(size.height / 2));
    expect(viewfinder.width / viewfinder.height, closeTo(4 / 3, 0.01));
    expect(
      viewfinder.height,
      greaterThanOrEqualTo(AppDimensions.photoViewfinderMinHeight),
    );
  });

  testWidgets('fenêtre large mais basse (1280×600) : plein écran', (
    tester,
  ) async {
    const size = Size(1280, 600);
    await openCapture(tester, size: size);
    // Le panneau couvre la fenêtre : un appui en haut à gauche ne tombe pas
    // sur le voile (qui fermerait la modale).
    await tester.tapAt(const Offset(4, 4));
    await settleFrames(tester);
    expect(find.byType(PhotoShutterButton), findsOneWidget);
  });

  testWidgets('poste 1440×900 : panneau centré, le voile ferme', (
    tester,
  ) async {
    const size = Size(1440, 900);
    await openCapture(tester, size: size);
    await tester.tapAt(const Offset(4, 4));
    await settleFrames(tester);
    expect(find.byType(PhotoShutterButton), findsNothing);
  });
}
