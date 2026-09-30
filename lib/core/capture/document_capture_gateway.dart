import 'dart:typed_data';

import 'package:school_app_flutter/core/capture/captured_document.dart';

/// Octets rendus par la plateforme, avant toute vérification.
class RawCapture {
  final Uint8List bytes;

  /// Nom d'origine, quand la plateforme en donne un.
  final String? fileName;

  const RawCapture({required this.bytes, this.fileName});
}

/// La caméra est refusée ou absente sur cet appareil.
class CameraUnavailableException implements Exception {
  const CameraUnavailableException();
}

/// Le fichier choisi dépasse le plafond : constaté sur sa taille annoncée,
/// **avant** d'en lire les octets — un PDF de 200 Mo ne doit pas être chargé
/// en mémoire pour être refusé.
class DocumentTooLargeException implements Exception {
  final int sizeBytes;

  const DocumentTooLargeException(this.sizeBytes);
}

/// Accès à la caméra et aux fichiers de la tablette.
///
/// Seul endroit qui touche aux greffons de la plateforme : tout le reste de la
/// capture se teste sans appareil.
abstract class DocumentCaptureGateway {
  /// Rend les octets obtenus par [mode], ou `null` si l'utilisateur a renoncé.
  ///
  /// Lève [CameraUnavailableException] quand la caméra est refusée ou absente,
  /// [DocumentTooLargeException] quand un fichier dépasse le plafond avant
  /// même d'être lu ; toute autre exception est une lecture ratée.
  Future<RawCapture?> acquire(DocumentCaptureMode mode);
}
