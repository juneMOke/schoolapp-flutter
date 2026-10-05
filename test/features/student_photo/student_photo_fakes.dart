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
  Uint8List shot = Uint8List.fromList([9, 9, 9]);

  FakeSession(this.lens);

  @override
  double get previewAspectRatio => 4 / 3;

  @override
  Widget buildPreview() => const SizedBox();

  @override
  Future<Uint8List> capture() async => shot;

  @override
  Future<void> close() async => closed = true;
}

class FakeCameras extends CameraViewfinderGateway {
  List<CameraLens> available;
  Object? openError;
  final List<FakeSession> opened = [];

  FakeCameras(this.available);

  @override
  Future<List<CameraLens>> lenses() async => available;

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
