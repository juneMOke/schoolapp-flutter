import 'package:school_app_flutter/core/capture/captured_document.dart';

/// Ce qu'une pièce numérisée ou importée doit respecter avant d'être gardée
/// sur la tablette.
///
/// Les bornes sont celles du serveur, vérifiées **avant** la mise en file
/// d'envoi : une pièce qui les dépasse serait refusée en 422 terminal
/// (`DOCUMENT_TOO_LARGE`) des heures plus tard, loin de celui qui pouvait en
/// choisir une autre.
class DocumentCapturePolicy {
  DocumentCapturePolicy._();

  /// Plafond par fichier : 5 Mo au sens de Spring (`spring.servlet.multipart`,
  /// réglé pour toute l'application depuis le logo V126), donc 5 × 1024².
  static const int maxBytes = 5 * 1024 * 1024;

  /// Le même plafond, en mégaoctets entiers, pour l'affichage.
  static const int maxMegabytes = 5;

  /// Grand côté d'une image après réduction : assez pour lire une pièce A4,
  /// assez peu pour qu'une photo d'appareil tienne sous [maxBytes].
  static const double maxImageDimension = 2000;

  /// Qualité JPEG d'une image réduite (0–100).
  static const int jpegQuality = 82;

  /// Types acceptés par le serveur.
  static const Set<DocumentMimeType> acceptedTypes = {
    DocumentMimeType.jpeg,
    DocumentMimeType.png,
    DocumentMimeType.pdf,
  };
}
