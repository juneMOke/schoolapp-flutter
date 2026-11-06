import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/camera_opener.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';

import '../photo_layout_harness.dart';
import 'photo_session_layout_test.dart' show openShooting;

const _window = Size(1440, 900);

void main() {
  final harness = PhotoLayoutHarness();

  setUpAll(PhotoLayoutHarness.registerFallbacks);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('caméra refusée : « Réessayer » relance la demande', (
    tester,
  ) async {
    harness.cameras.lensesError = const CameraAccessDeniedException();
    final cubit = await openShooting(tester, harness, size: _window);
    expect(find.text('Caméra bloquée'), findsOneWidget);

    harness.cameras.lensesError = null;
    await tester.tap(find.text('Réessayer'));
    await settleFrames(tester);
    expect((cubit.state as SessionShooting).camera, isA<CameraOpened>());
    expect(find.text('Caméra bloquée'), findsNothing);
  });

  testWidgets('en http : la séance le dit, sans « Réessayer »', (tester) async {
    harness.cameras.lensesError = const CameraInsecureContextException();
    await openShooting(tester, harness, size: _window);
    expect(find.text('Connexion non sécurisée'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });
}
