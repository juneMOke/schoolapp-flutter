import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_queue_panel.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/widgets/session_shoot_panel.dart';

import '../photo_layout_harness.dart';
import 'photo_session_layout_test.dart' show openShooting;

void main() {
  final harness = PhotoLayoutHarness();

  setUpAll(PhotoLayoutHarness.registerFallbacks);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('la fenêtre passe sous le seuil : le viseur n’est pas recréé', (
    tester,
  ) async {
    await openShooting(tester, harness, size: const Size(1100, 900));
    final shoot = find.byType(SessionShootPanel);
    final queue = find.byType(SessionQueuePanel);
    // Côte à côte : la file à droite de la prise de vue.
    expect(
      tester.getTopLeft(queue).dx,
      greaterThan(tester.getTopRight(shoot).dx),
    );
    final session = harness.cameras.opened.single;
    expect(session.previewMounts, 1);

    tester.view.physicalSize = const Size(800, 900);
    await settleFrames(tester);
    // Empilées : la file sous la prise de vue.
    expect(
      tester.getTopLeft(queue).dy,
      greaterThan(tester.getBottomLeft(shoot).dy),
    );
    expect(session.previewMounts, 1, reason: 'aperçu remonté à la bascule');

    tester.view.physicalSize = const Size(1100, 900);
    await settleFrames(tester);
    expect(session.previewMounts, 1);
  });

  testWidgets('740×360 : la file garde sa hauteur plancher', (tester) async {
    await openShooting(tester, harness, size: const Size(740, 360));
    final box = tester.widget<ConstrainedBox>(
      find
          .ancestor(
            of: find.byType(SessionQueuePanel),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(
      box.constraints.maxHeight,
      greaterThanOrEqualTo(AppDimensions.photoSessionQueueMinHeight),
    );
  });
}
