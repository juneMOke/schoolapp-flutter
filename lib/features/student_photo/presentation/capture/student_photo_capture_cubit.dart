import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/square_photo_encoder.dart';
import 'package:school_app_flutter/features/student_photo/domain/usecases/student_photo_use_cases.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/camera_opener.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/photo_capture_target.dart';
import 'package:school_app_flutter/features/student_photo/presentation/capture/student_photo_capture_state.dart';

export 'package:school_app_flutter/features/student_photo/presentation/capture/photo_capture_target.dart';

/// La modale de capture : caméra, import, recadrage, puis enregistrement.
///
/// Détient la caméra ouverte et la referme à chaque sortie du viseur — une
/// caméra gardée ouverte derrière le recadrage resterait allumée pour rien.
class StudentPhotoCaptureCubit extends Cubit<StudentPhotoCaptureState> {
  final CameraViewfinderGateway _cameras;
  final DocumentCaptureGateway _files;
  final SquarePhotoEncoder _encoder;
  final SaveStudentPhotoUseCase _save;
  final DateTime Function() _now;

  StudentPhotoCaptureCubit({
    required CameraViewfinderGateway cameras,
    required DocumentCaptureGateway files,
    required SquarePhotoEncoder encoder,
    required SaveStudentPhotoUseCase save,
    DateTime Function()? now,
  }) : _cameras = cameras,
       _files = files,
       _encoder = encoder,
       _save = save,
       _now = now ?? DateTime.now,
       super(const CaptureStarting());

  /// Plafond d'un fichier importé : au-delà, refusé avant décodage.
  static const int maxImportBytes = 8 * 1024 * 1024;

  late PhotoCaptureTarget _target;
  CameraOpener? _opener;

  /// Ouvre la caméra ; ou directement le recadrage de [recrop] (une photo
  /// déjà prise qu'on recadre) ; ou d'abord le sélecteur de fichiers
  /// ([importFirst]), la caméra prenant le relais si l'on y renonce.
  Future<void> start({
    required PhotoCaptureTarget target,
    required bool isTouch,
    Uint8List? recrop,
    bool importFirst = false,
  }) async {
    _target = target;
    _opener = CameraOpener(_cameras, isTouch: isTouch);
    if (recrop != null) {
      await _review(recrop, origin: PhotoOrigin.file, mirror: false);
      return;
    }
    if (importFirst) {
      await importFile();
      if (isClosed || state is! CaptureStarting) return;
    }
    await _openCamera();
  }

  Future<void> _openCamera() async {
    emit(const CaptureStarting());
    _show(await _opener!.open());
  }

  void _show(CameraOpening opening) {
    switch (opening) {
      case CameraOpened(:final session, :final canSwitch):
        if (isClosed) {
          unawaited(session.close());
          return;
        }
        emit(CaptureLive(session: session, canSwitch: canSwitch));
      case CameraUnavailable(:final reason):
        if (!isClosed) emit(CaptureBlocked(reason));
      case CameraSuperseded():
        // Une ouverture plus récente montrera son propre flux.
        break;
    }
  }

  Future<void> _closeCamera() async => _opener?.close();

  bool _suspended = false;

  /// L'application passe en arrière-plan : la caméra est rendue au système
  /// (le paquet `camera` laisse ce soin à l'application).
  Future<void> suspendCamera() async {
    if (state is! CaptureLive && state is! CaptureStarting) return;
    _suspended = true;
    await _opener?.release();
    if (!isClosed) emit(const CaptureStarting());
  }

  /// Retour au premier plan : le flux rendu à l'arrière-plan se rouvre.
  Future<void> resumeCamera() async {
    if (!_suspended) return;
    _suspended = false;
    if (!isClosed && state is CaptureStarting) await _openCamera();
  }

  /// Passe à la caméra suivante (avant ↔ arrière).
  Future<void> switchCamera() async {
    final current = state;
    if (current is! CaptureLive || !current.canSwitch) return;
    emit(const CaptureStarting());
    _show(await _opener!.switchNext());
  }

  /// Déclenche : la date de prise est celle de cet instant.
  Future<void> shoot() async {
    final current = state;
    if (current is! CaptureLive || current.shooting) return;
    emit(
      CaptureLive(
        session: current.session,
        canSwitch: current.canSwitch,
        shooting: true,
      ),
    );
    final takenAt = _now();
    final Uint8List bytes;
    try {
      bytes = await current.session.capture();
    } catch (_) {
      if (isClosed || state != current.copyShooting()) return;
      emit(CaptureLive(session: current.session, canSwitch: current.canSwitch));
      return;
    }
    if (isClosed) return;
    final mirror = current.session.lens.mirrors;
    // Le recadrage remplace le viseur AVANT que la caméra ne s'éteigne : un
    // flux refermé encore à l'écran lèverait au premier rebuild.
    await _review(
      bytes,
      origin: PhotoOrigin.camera,
      mirror: mirror,
      takenAt: takenAt,
      guided: true,
    );
    await _closeCamera();
  }

  /// Importe une image du poste. Un renoncement laisse l'écran tel quel.
  Future<void> importFile() async {
    RawCapture? raw;
    try {
      raw = await _files.acquire(DocumentCaptureMode.importImage);
    } catch (_) {
      // Trop lourd avant lecture, ou lecture ratée : le même refus.
      raw = RawCapture(bytes: Uint8List(maxImportBytes + 1));
    }
    if (raw == null || isClosed) return;
    if (raw.bytes.length > maxImportBytes) {
      emit(const CaptureBadFile());
    } else {
      await _review(raw.bytes, origin: PhotoOrigin.file, mirror: false);
    }
    await _closeCamera();
  }

  Future<void> _review(
    Uint8List bytes, {
    required PhotoOrigin origin,
    required bool mirror,
    DateTime? takenAt,
    bool guided = false,
  }) async {
    final PhotoDimensions size;
    try {
      size = await _encoder.measure(bytes);
    } catch (_) {
      if (!isClosed) emit(const CaptureBadFile());
      return;
    }
    if (isClosed) return;
    emit(
      CaptureReview(
        source: bytes,
        origin: origin,
        mirror: mirror,
        takenAt: takenAt ?? _now(),
        window: guided
            ? CropWindow.ovalGuide(size.width, size.height)
            : CropWindow.centered(size.width, size.height),
      ),
    );
  }

  /// Reprendre : la caméra pour une prise, le sélecteur pour un fichier.
  Future<void> retake() async {
    final current = state;
    final origin = switch (current) {
      CaptureReview(:final origin) => origin,
      CaptureSaveFailed(:final review) => review.origin,
      _ => PhotoOrigin.camera,
    };
    if (origin == PhotoOrigin.file) {
      await importFile();
    } else {
      await _openCamera();
    }
  }

  /// Rouvre la caméra depuis un écran d'erreur.
  Future<void> reopenCamera() => _openCamera();

  void adjust(CropWindow window) {
    final current = state;
    if (current is CaptureReview) emit(current.withWindow(window));
  }

  /// « Utiliser cette photo » : le carré est préparé, puis gardé.
  Future<void> confirm() async {
    final current = switch (state) {
      final CaptureReview review => review,
      CaptureSaveFailed(:final review) => review,
      _ => null,
    };
    if (current == null) return;
    emit(const CaptureSaving());
    final Uint8List square;
    try {
      square = await _encoder.encode(
        current.source,
        current.window,
        mirror: current.mirror,
      );
    } catch (_) {
      if (!isClosed) emit(const CaptureBadFile());
      return;
    }
    if (isClosed) return;
    switch (_target) {
      case KeepAsDraft():
        emit(CaptureDraftReady(square, current.takenAt));
      case SaveForStudent(:final studentId):
        final result = await _save(
          studentId: studentId,
          jpeg: square,
          takenAt: current.takenAt,
        );
        if (isClosed) return;
        result.fold(
          (_) => emit(CaptureSaveFailed(current)),
          (_) => emit(CaptureSaved(square)),
        );
    }
  }

  @override
  Future<void> close() async {
    await _opener?.release();
    return super.close();
  }
}
