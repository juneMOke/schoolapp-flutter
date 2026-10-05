import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';

/// [CameraViewfinderGateway] sur le greffon `camera`.
///
/// Android, iOS et web par la fédération du paquet, Windows par
/// `camera_windows`. Linux n'a pas de greffon : la liste des caméras y lève,
/// et se lit comme « aucune caméra » — l'import reste l'issue.
///
/// Sans son : l'application ne filme pas, et demander le micro ferait échouer
/// l'ouverture sur un appareil qui le refuse.
class PlatformCameraViewfinderGateway extends CameraViewfinderGateway {
  /// Codes par lesquels le greffon signale une caméra refusée ou bloquée par
  /// la gestion de flotte.
  static const Set<String> _deniedCodes = {
    'CameraAccessDenied',
    'CameraAccessDeniedWithoutPrompt',
    'CameraAccessRestricted',
    'cameraPermission',
    'permissionDenied',
  };

  @override
  Future<List<CameraLens>> lenses() async {
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (e) {
      if (_deniedCodes.contains(e.code)) {
        throw const CameraAccessDeniedException();
      }
      return const [];
    } catch (_) {
      // Pas de greffon (Linux), pas d'implémentation : aucune caméra.
      return const [];
    }
    return [for (final camera in cameras) _PlatformLens.of(camera)];
  }

  @override
  Future<CameraSession> open(CameraLens lens) async {
    if (lens is! _PlatformLens) throw const NoCameraException();
    final controller = CameraController(
      lens.description,
      // ~720p : la photo sort en 512 px, un capteur plus fin ne ferait que
      // ralentir la prise et grossir la mémoire.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      await controller.dispose();
      if (_deniedCodes.contains(e.code)) {
        throw const CameraAccessDeniedException();
      }
      throw const NoCameraException();
    }
    return _PlatformCameraSession(lens, controller);
  }
}

class _PlatformLens extends CameraLens {
  final CameraDescription description;

  const _PlatformLens(
    this.description, {
    required super.name,
    required super.facing,
  });

  factory _PlatformLens.of(CameraDescription description) => _PlatformLens(
    description,
    name: description.name,
    facing: switch (description.lensDirection) {
      CameraLensDirection.front => CameraFacing.front,
      CameraLensDirection.back => CameraFacing.back,
      CameraLensDirection.external => CameraFacing.external,
    },
  );
}

class _PlatformCameraSession implements CameraSession {
  @override
  final CameraLens lens;
  final CameraController _controller;

  _PlatformCameraSession(this.lens, this._controller);

  @override
  double get previewAspectRatio => _controller.value.aspectRatio;

  @override
  Widget buildPreview() => CameraPreview(_controller);

  @override
  Future<Uint8List> capture() async {
    final file = await _controller.takePicture();
    try {
      return await file.readAsBytes();
    } finally {
      // La photo d'un enfant ne doit pas survivre en clair dans le cache.
      if (!kIsWeb && file.path.isNotEmpty) {
        try {
          await File(file.path).delete();
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> close() => _controller.dispose();
}
