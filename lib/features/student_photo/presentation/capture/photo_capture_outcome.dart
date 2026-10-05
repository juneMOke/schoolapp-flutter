import 'package:flutter/foundation.dart';

/// Comment la modale s'ouvre.
enum PhotoCaptureEntry { camera, import }

/// Ce que la modale rend en se fermant.
sealed class PhotoCaptureOutcome {
  const PhotoCaptureOutcome();
}

/// La photo est enregistrée pour l'élève (et partira par l'outbox).
class PhotoSavedOutcome extends PhotoCaptureOutcome {
  const PhotoSavedOutcome();
}

/// Nouvelle inscription : la photo, à garder en brouillon par l'appelant.
class PhotoDraftOutcome extends PhotoCaptureOutcome {
  final Uint8List photo;
  final DateTime takenAt;

  const PhotoDraftOutcome(this.photo, this.takenAt);
}
