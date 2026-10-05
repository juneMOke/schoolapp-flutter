import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/capture/camera/camera_viewfinder_gateway.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/crop_window.dart';

/// D'où vient la photo en cours de recadrage : l'action secondaire dit
/// « Reprendre » pour la caméra, « Autre fichier » pour un import.
enum PhotoOrigin { camera, file }

/// Pourquoi la caméra n'est pas là.
enum CameraBlockReason { denied, none }

/// La modale de capture, de l'accès à la caméra jusqu'à la photo gardée.
sealed class StudentPhotoCaptureState extends Equatable {
  const StudentPhotoCaptureState();

  @override
  List<Object?> get props => const [];
}

/// L'accès à la caméra est demandé.
class CaptureStarting extends StudentPhotoCaptureState {
  const CaptureStarting();
}

/// Le flux est en direct.
class CaptureLive extends StudentPhotoCaptureState {
  final CameraSession session;
  final bool canSwitch;

  /// Une prise est en cours : le déclencheur est inactif.
  final bool shooting;

  const CaptureLive({
    required this.session,
    required this.canSwitch,
    this.shooting = false,
  });

  /// Le même flux, déclencheur en cours.
  CaptureLive copyShooting() =>
      CaptureLive(session: session, canSwitch: canSwitch, shooting: true);

  @override
  List<Object?> get props => [session, canSwitch, shooting];
}

/// Pas de caméra, ou caméra refusée : l'import reste l'issue.
class CaptureBlocked extends StudentPhotoCaptureState {
  final CameraBlockReason reason;

  const CaptureBlocked(this.reason);

  @override
  List<Object?> get props => [reason];
}

/// La photo est à vérifier et à recadrer.
class CaptureReview extends StudentPhotoCaptureState {
  final Uint8List source;
  final CropWindow window;
  final PhotoOrigin origin;
  final bool mirror;
  final DateTime takenAt;

  const CaptureReview({
    required this.source,
    required this.window,
    required this.origin,
    required this.takenAt,
    this.mirror = false,
  });

  CaptureReview withWindow(CropWindow window) => CaptureReview(
    source: source,
    window: window,
    origin: origin,
    takenAt: takenAt,
    mirror: mirror,
  );

  @override
  List<Object?> get props => [source, window, origin, mirror, takenAt];
}

/// Le carré est en préparation, puis gardé sur le poste.
class CaptureSaving extends StudentPhotoCaptureState {
  const CaptureSaving();
}

/// La photo est enregistrée : la modale se ferme seule.
class CaptureSaved extends StudentPhotoCaptureState {
  final Uint8List photo;

  const CaptureSaved(this.photo);

  @override
  List<Object?> get props => [photo];
}

/// Nouvelle inscription : la photo est prête, gardée en brouillon par
/// l'appelant jusqu'à l'enregistrement de l'élève.
class CaptureDraftReady extends StudentPhotoCaptureState {
  final Uint8List photo;
  final DateTime takenAt;

  const CaptureDraftReady(this.photo, this.takenAt);

  @override
  List<Object?> get props => [photo, takenAt];
}

/// Le fichier choisi n'est pas une image lisible, ou dépasse 8 Mo.
class CaptureBadFile extends StudentPhotoCaptureState {
  const CaptureBadFile();
}

/// La photo n'a pas pu être gardée sur le poste ; elle reste à l'écran pour
/// réessayer sans la reprendre.
class CaptureSaveFailed extends StudentPhotoCaptureState {
  final CaptureReview review;

  const CaptureSaveFailed(this.review);

  @override
  List<Object?> get props => [review];
}
