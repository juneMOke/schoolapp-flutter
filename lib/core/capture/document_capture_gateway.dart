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

/// Accès à la caméra et aux fichiers de la tablette.
///
/// Seul endroit qui touche aux greffons de la plateforme : tout le reste de la
/// capture se teste sans appareil.
abstract class DocumentCaptureGateway {
  /// Rend les octets obtenus par [mode], ou `null` si l'utilisateur a renoncé.
  ///
  /// Lève [CameraUnavailableException] quand la caméra est refusée ou absente ;
  /// toute autre exception est une lecture ratée.
  Future<RawCapture?> acquire(DocumentCaptureMode mode);
}
