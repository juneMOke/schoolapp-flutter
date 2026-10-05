import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/camera_opener.dart';
import 'package:school_app_flutter/features/student_photo/presentation/session/photo_session_state.dart';

/// La caméra de la séance : l'ouvrir, la basculer, la rendre au système en
/// arrière-plan et la reprendre au retour.
mixin SessionCameraControl on Cubit<PhotoSessionState> {
  CameraOpener? get opener;

  Future<void> openCamera([Future<CameraOpening> Function()? how]) async {
    final opening = await (how ?? opener!.open)();
    if (opening is CameraSuperseded) return;
    final current = state;
    if (isClosed || current is! SessionShooting) {
      await opener?.close();
      return;
    }
    emit(current.copyWith(camera: opening));
  }

  /// Passe à la caméra suivante. Le viseur quitte l'ancien flux AVANT qu'il
  /// ne soit refermé : un flux refermé encore à l'écran lèverait.
  Future<void> switchCamera() async {
    final current = state;
    if (current is! SessionShooting || current.busy) return;
    if (current.camera is! CameraOpened) return;
    emit(current.copyWith(clearCamera: true));
    await openCamera(opener!.switchNext);
  }

  bool _suspended = false;

  /// L'application passe en arrière-plan : la caméra est rendue au système.
  Future<void> suspendCamera() async {
    final current = state;
    if (current is! SessionShooting) return;
    _suspended = true;
    emit(current.copyWith(clearCamera: true));
    await opener?.release();
  }

  /// Retour au premier plan : la caméra se rouvre si la prise de vue continue.
  Future<void> resumeCamera() async {
    if (!_suspended) return;
    _suspended = false;
    if (!isClosed && state is SessionShooting) await openCamera();
  }
}
