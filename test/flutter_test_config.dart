import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Sonde téléphone : `--dart-define=PROBE_PHONE_SURFACE=true` rejoue toute
/// la suite à 360×740 dp (rapport de pixels 3).
///
/// Un test qui ne fixe pas sa fenêtre vérifie sans le dire les 800×600 de
/// `flutter_test` ; la sonde le fait rougir. Il fixe alors le format qu'il
/// vérifie (`setTestWindow`) ou tourne aux formats de référence
/// (`testAtReferenceFormats`). Ce qu'elle a déjà trouvé : #108 (42 tests),
/// #109 (Échap sous 600 dp). Workflow `phone_surface_probe.yml`.
///
/// Sans la variable, ce fichier ne change rien.
const _probePhoneSurface = bool.fromEnvironment('PROBE_PHONE_SURFACE');

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (_probePhoneSurface) {
    setUp(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      for (final view in binding.platformDispatcher.views) {
        view.physicalSize = const Size(1080, 2220);
        view.devicePixelRatio = 3;
      }
    });
  }
  await testMain();
}
