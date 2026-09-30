import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/capture/platform_document_capture_gateway.dart';

/// `ImagePicker` dont on choisit la réponse, sans canal natif.
class _FakeImagePicker extends ImagePicker {
  final bool cameraSupported;
  final Object? error;

  _FakeImagePicker({this.cameraSupported = true, this.error});

  @override
  bool supportsImageSource(ImageSource source) =>
      source != ImageSource.camera || cameraSupported;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    return null;
  }
}

void main() {
  PlatformDocumentCaptureGateway gatewayWith(_FakeImagePicker picker) =>
      PlatformDocumentCaptureGateway(imagePicker: picker);

  for (final code in [
    'camera_access_denied',
    'camera_access_restricted',
    'no_available_camera',
  ]) {
    test('« $code » se lit comme une caméra indisponible', () {
      final gateway = gatewayWith(
        _FakeImagePicker(error: PlatformException(code: code)),
      );

      expect(
        gateway.acquire(DocumentCaptureMode.scan),
        throwsA(isA<CameraUnavailableException>()),
      );
    });
  }

  test('une plateforme sans prise de vue se lit comme une caméra '
      'indisponible', () {
    final gateway = gatewayWith(_FakeImagePicker(cameraSupported: false));

    expect(
      gateway.acquire(DocumentCaptureMode.scan),
      throwsA(isA<CameraUnavailableException>()),
    );
  });

  test('toute autre panne reste une panne, non une caméra absente', () {
    final gateway = gatewayWith(
      _FakeImagePicker(error: PlatformException(code: 'invalid_image')),
    );

    expect(
      gateway.acquire(DocumentCaptureMode.scan),
      throwsA(isA<PlatformException>()),
    );
  });

  test(
    "un code « caméra » sur la photothèque n'est pas une caméra absente",
    () {
      final gateway = gatewayWith(
        _FakeImagePicker(
          error: PlatformException(code: 'camera_access_denied'),
        ),
      );

      expect(
        gateway.acquire(DocumentCaptureMode.importImage),
        throwsA(isA<PlatformException>()),
      );
    },
  );

  test('renoncer rend null', () async {
    final gateway = gatewayWith(_FakeImagePicker());

    expect(await gateway.acquire(DocumentCaptureMode.importImage), isNull);
  });
}
