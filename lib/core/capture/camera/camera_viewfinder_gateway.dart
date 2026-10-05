import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// De quel côté de l'appareil regarde une caméra.
enum CameraFacing { front, back, external }

/// Une caméra de l'appareil.
class CameraLens {
  final String name;
  final CameraFacing facing;

  const CameraLens({required this.name, required this.facing});

  /// L'aperçu et la photo d'une caméra frontale sont montrés en miroir : on
  /// se reconnaît ainsi, comme dans une glace.
  bool get mirrors => facing == CameraFacing.front;
}

/// La caméra est refusée (permission, gestion de flotte) : l'écran propose
/// d'importer un fichier à la place.
class CameraAccessDeniedException implements Exception {
  const CameraAccessDeniedException();
}

/// L'appareil n'a aucune caméra utilisable (poste fixe sans webcam, Linux).
class NoCameraException implements Exception {
  const NoCameraException();
}

/// Un flux de caméra ouvert : son aperçu, et la prise d'une photo.
abstract class CameraSession {
  CameraLens get lens;

  /// Rapport largeur / hauteur de l'aperçu, tel que la caméra le livre.
  double get previewAspectRatio;

  /// Le flux en direct, à poser dans le viseur.
  Widget buildPreview();

  /// Prend une photo et rend ses octets (JPEG). Le fichier temporaire que la
  /// plateforme écrit est effacé : la photo n'existe qu'en mémoire.
  Future<Uint8List> capture();

  Future<void> close();
}

/// Accès aux caméras de l'appareil, pour un viseur intégré à l'application.
///
/// Seul endroit qui touche au greffon `camera` : tout le reste de la prise de
/// vue se teste sans appareil.
abstract class CameraViewfinderGateway {
  /// Les caméras de l'appareil ; vide s'il n'y en a pas.
  Future<List<CameraLens>> lenses();

  /// Ouvre [lens]. Lève [CameraAccessDeniedException] si l'accès est refusé,
  /// [NoCameraException] si la caméra ne répond pas.
  Future<CameraSession> open(CameraLens lens);

  /// La caméra à ouvrir d'abord : à l'arrière sur une tablette (on
  /// photographie l'élève en face), à l'avant sur un poste (la webcam).
  CameraLens? preferredLens(List<CameraLens> lenses, {required bool isTouch}) {
    if (lenses.isEmpty) return null;
    final wanted = isTouch ? CameraFacing.back : CameraFacing.front;
    for (final lens in lenses) {
      if (lens.facing == wanted) return lens;
    }
    return lenses.first;
  }
}
