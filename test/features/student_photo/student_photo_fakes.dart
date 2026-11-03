import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/square_photo_encoder.dart';

/// Une caméra ouverte, sans appareil.
class FakeSession implements CameraSession {
  @override
  final CameraLens lens;
  bool closed = false;

  /// Une vraie image (PNG 1 × 1) : le recadrage qui suit la prise la décode.
  Uint8List shot = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );

  /// Le nombre de prises demandées.
  int captures = 0;

  /// Combien de fois l'aperçu a été monté : sur le web, un aperçu remonté
  /// recrée son élément vidéo.
  int previewMounts = 0;

  FakeSession(this.lens);

  @override
  double get previewAspectRatio => 4 / 3;

  @override
  Widget buildPreview() => _CountedPreview(onMount: () => previewMounts++);

  @override
  Future<Uint8List> capture() async {
    captures++;
    return shot;
  }

  @override
  Future<void> close() async => closed = true;
}

class _CountedPreview extends StatefulWidget {
  final VoidCallback onMount;

  const _CountedPreview({required this.onMount});

  @override
  State<_CountedPreview> createState() => _CountedPreviewState();
}

class _CountedPreviewState extends State<_CountedPreview> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class FakeCameras extends CameraViewfinderGateway {
  List<CameraLens> available;
  Object? openError;

  /// Levée par [lenses] (refus du navigateur, page en http).
  Object? lensesError;
  final List<FakeSession> opened = [];

  FakeCameras(this.available);

  @override
  Future<List<CameraLens>> lenses() async {
    final error = lensesError;
    if (error != null) throw error;
    return available;
  }

  @override
  Future<CameraSession> open(CameraLens lens) async {
    final error = openError;
    if (error != null) throw error;
    final session = FakeSession(lens);
    opened.add(session);
    return session;
  }
}

class FakeEncoder implements SquarePhotoEncoder {
  bool unreadable = false;
  bool? lastMirror;
  CropWindow? lastWindow;

  @override
  Future<PhotoDimensions> measure(Uint8List bytes) async {
    if (unreadable) throw const UnreadablePhotoException();
    return (width: 400.0, height: 300.0);
  }

  @override
  Future<Uint8List> encode(
    Uint8List bytes,
    CropWindow window, {
    bool mirror = false,
  }) async {
    lastMirror = mirror;
    lastWindow = window;
    return Uint8List.fromList([5, 1, 2]);
  }
}
