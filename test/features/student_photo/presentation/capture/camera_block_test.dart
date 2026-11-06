import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/capture/camera/platform_camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/camera_opener.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/capture_camera_body.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_dark_controls.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

import '../../student_photo_fakes.dart';
import '../photo_layout_harness.dart';
import 'capture_dialog_layout_test.dart' show openCapture;

const _window = Size(1440, 900);

bool _shutterLive(WidgetTester tester) =>
    tester
        .widget<PhotoShutterButton>(find.byType(PhotoShutterButton))
        .onPressed !=
    null;

void main() {
  group('page web en http', () {
    test('la passerelle le dit avant de chercher une caméra', () async {
      final gateway = PlatformCameraViewfinderGateway(
        insecureContext: () => true,
      );
      await expectLater(
        gateway.lenses(),
        throwsA(isA<CameraInsecureContextException>()),
      );
    });

    test('l’ouverture en fait un motif propre, sans nouvel essai', () async {
      final cameras = FakeCameras(const [])
        ..lensesError = const CameraInsecureContextException();
      final opening = await CameraOpener(cameras, isTouch: false).open();
      expect(
        (opening as CameraUnavailable).reason,
        CameraBlockReason.insecureContext,
      );
      expect(CameraBlockReason.insecureContext.canRetry, isFalse);
      expect(CameraBlockReason.denied.canRetry, isTrue);
      expect(CameraBlockReason.none.canRetry, isTrue);
    });
  });

  group('les phrases', () {
    final l10n = AppLocalizationsFr();

    test('refus sur le web : autoriser la caméra pour ce site', () {
      final web = cameraBlockTexts(l10n, CameraBlockReason.denied, web: true);
      expect(web.message, contains('pour ce site'));
      final app = cameraBlockTexts(l10n, CameraBlockReason.denied, web: false);
      expect(app.message, l10n.photoCameraBlockedMessage);
    });

    test('http : https, pas « aucune caméra »', () {
      final texts = cameraBlockTexts(
        l10n,
        CameraBlockReason.insecureContext,
        web: true,
      );
      expect(texts.title, 'Connexion non sécurisée');
      expect(texts.message, contains('https'));
    });
  });

  group('la modale', () {
    final harness = PhotoLayoutHarness();

    setUpAll(PhotoLayoutHarness.registerFallbacks);
    setUp(harness.setUp);
    tearDown(harness.tearDown);

    testWidgets('en http : la carte le dit, sans « Réessayer »', (
      tester,
    ) async {
      harness.cameras.lensesError = const CameraInsecureContextException();
      await openCapture(tester, size: _window);
      expect(find.text('Connexion non sécurisée'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
      expect(find.text('Importer une photo'), findsOneWidget);
    });

    testWidgets('refusée puis autorisée : « Réessayer » relance la demande', (
      tester,
    ) async {
      harness.cameras.lensesError = const CameraAccessDeniedException();
      await openCapture(tester, size: _window);
      expect(find.text('Caméra bloquée'), findsOneWidget);
      expect(_shutterLive(tester), isFalse);

      harness.cameras.lensesError = null;
      await tester.tap(find.text('Réessayer'));
      await settleFrames(tester);
      expect(harness.cameras.opened, hasLength(1));
      expect(find.text('Caméra bloquée'), findsNothing);
      expect(_shutterLive(tester), isTrue);
    });

    for (final size in const [Size(360, 740), Size(740, 360)]) {
      testWidgets('$size, texte ×1,3 : la carte à deux boutons tient', (
        tester,
      ) async {
        harness.cameras.lensesError = const CameraAccessDeniedException();
        await openCapture(tester, size: size, textScale: 1.3);
        expect(find.text('Réessayer'), findsOneWidget);
      });
    }

    testWidgets('aucune caméra, webcam branchée : « Réessayer » la trouve', (
      tester,
    ) async {
      harness.cameras.available = const [];
      await openCapture(tester, size: _window);
      expect(find.text('Aucune caméra détectée'), findsOneWidget);

      harness.cameras.available = const [backLens];
      await tester.tap(find.text('Réessayer'));
      await settleFrames(tester);
      expect(_shutterLive(tester), isTrue);
    });
  });
}
