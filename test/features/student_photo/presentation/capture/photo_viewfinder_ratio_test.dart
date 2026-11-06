import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/widgets/photo_viewfinder.dart';

const _previewKey = Key('preview');

/// Un flux 16:9, celui d'une webcam ordinaire.
class _WideSession implements CameraSession {
  @override
  final CameraLens lens = const CameraLens(
    name: 'webcam',
    facing: CameraFacing.front,
  );

  @override
  double get previewAspectRatio => 16 / 9;

  @override
  Widget buildPreview() => const SizedBox.expand(key: _previewKey);

  @override
  Future<Uint8List> capture() async => Uint8List(0);

  @override
  Future<void> close() async {}
}

/// Pose le viseur dans une fenêtre de [size] et rend la taille de référence
/// donnée au flux (avant mise à l'échelle par `FittedBox`).
Future<Size> _referenceIn(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: PhotoViewfinder(session: _WideSession(), tip: ''),
          ),
        ),
      ),
    ),
  );
  final box = tester.widget<SizedBox>(
    find
        .ancestor(of: find.byKey(_previewKey), matching: find.byType(SizedBox))
        .first,
  );
  return Size(box.width!, box.height!);
}

void _expectSize(Size actual, double width, double height) {
  expect(actual.width, closeTo(width, 0.01));
  expect(actual.height, closeTo(height, 0.01));
}

void main() {
  const reference = AppDimensions.photoViewfinderReference;
  const tall = Size(700, 1000);
  const wide = Size(1000, 700);

  group('le flux ne pivote qu’avec une tablette ou un téléphone', () {
    test('web : jamais, même sur un navigateur Android', () {
      expect(
        PhotoViewfinder.streamFollowsDevice(
          isWeb: true,
          platform: TargetPlatform.android,
        ),
        isFalse,
      );
    });

    test('poste : jamais', () {
      for (final platform in [
        TargetPlatform.linux,
        TargetPlatform.windows,
        TargetPlatform.macOS,
      ]) {
        expect(
          PhotoViewfinder.streamFollowsDevice(isWeb: false, platform: platform),
          isFalse,
          reason: '$platform',
        );
      }
    });

    test('Android et iOS : oui', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        expect(
          PhotoViewfinder.streamFollowsDevice(isWeb: false, platform: platform),
          isTrue,
          reason: '$platform',
        );
      }
    });
  });

  testWidgets(
    'poste, fenêtre en hauteur : le flux garde son rapport paysage',
    (tester) async {
      final size = await _referenceIn(tester, tall);
      _expectSize(size, reference * 16 / 9, reference);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.linux,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'tablette tenue en portrait : le rapport est inversé (contre-épreuve)',
    (tester) async {
      final size = await _referenceIn(tester, tall);
      _expectSize(size, reference, reference * 16 / 9);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'tablette en paysage : rapport du capteur, sans inversion',
    (tester) async {
      final size = await _referenceIn(tester, wide);
      _expectSize(size, reference * 16 / 9, reference);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
