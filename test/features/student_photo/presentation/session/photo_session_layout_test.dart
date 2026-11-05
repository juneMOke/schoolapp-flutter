import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_cubit.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_page.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';

import '../photo_layout_harness.dart';

/// Ouvre la séance et lance la prise de vue de la classe ; rend le cubit.
Future<PhotoSessionCubit> openShooting(
  WidgetTester tester,
  PhotoLayoutHarness harness, {
  required Size size,
  double textScale = 1,
}) async {
  late PhotoSessionCubit cubit;
  getIt.unregister<PhotoSessionCubit>();
  getIt.registerFactory<PhotoSessionCubit>(() => cubit);
  cubit = harness.sessionCubit();
  await pumpPhotoApp(
    tester,
    const PhotoSessionPage(),
    size: size,
    textScale: textScale,
  );
  await settleFrames(tester);
  cubit.selectClass('c-6a');
  await cubit.start();
  await settleFrames(tester);
  expect(cubit.state, isA<SessionShooting>());
  return cubit;
}

void main() {
  final harness = PhotoLayoutHarness();

  setUpAll(PhotoLayoutHarness.registerFallbacks);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  // 740×360 compris : sur une fenêtre basse, la prise de vue passe en
  // paysage (cf. `photo_session_landscape_test`).
  for (final size in referenceFormats) {
    testWidgets('$size : déclencheur et « Importer » à l’écran', (
      tester,
    ) async {
      await openShooting(tester, harness, size: size);
      expectOnScreen(tester, find.byType(PhotoShutterButton), size);
      // L'icône : en paysage, « Importer » n'a plus que son info-bulle.
      expectOnScreen(tester, find.byIcon(Icons.upload_rounded), size);
    });
  }

  testWidgets('360×740, texte ×1,3 : rien ne déborde', (tester) async {
    const size = Size(360, 740);
    await openShooting(tester, harness, size: size, textScale: 1.3);
    expectOnScreen(tester, find.byType(PhotoShutterButton), size);
  });

  testWidgets('1366×768, texte ×1,3 : le déclencheur reste visible', (
    tester,
  ) async {
    const size = Size(1366, 768);
    await openShooting(tester, harness, size: size, textScale: 1.3);
    expectOnScreen(tester, find.byType(PhotoShutterButton), size);
  });
}
